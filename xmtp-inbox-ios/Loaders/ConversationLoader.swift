//
//  ConversationLoader.swift
//  xmtp-inbox-ios
//
//  Created by Pat Nakajima on 2/2/23.
//

import AsyncAlgorithms
import Foundation
import GRDB
import SwiftUI
import XMTP

struct ConversationWithLastMessage: Codable, FetchableRecord {
	var conversation: DB.Conversation
	var lastMessage: DB.Message?
}

class ConversationLoader: ObservableObject {
	var db: DB
	var client: XMTP.Client
	var ensRefreshedAt: Date? {
		didSet {
			AppGroup.defaults.set(ensRefreshedAt, forKey: "ensRefreshedAt")
		}
	}

	var ensService: ENSService = ENS.shared

	@MainActor @Published var error: Error?

	init(client: XMTP.Client, db: DB) {
		self.client = client
		self.db = db
		ensRefreshedAt = (AppGroup.defaults.object(forKey: "ensRefreshedAt") as? Date)
	}

	func load() async throws {
		do {
			try await fetchRemote()
			try await fetchRecentMessages()
		} catch {
			await MainActor.run {
				self.error = error
			}
			print("Error in ConversationLoader.load(): \(error)")
		}
	}

	func fetchRemote() async throws {
		var conversations: [DB.Conversation] = []

		for conversation in try await client.conversations.list() {
			conversations.append(try await DB.Conversation.from(conversation, db: db))
		}

		await refreshENS(conversations: conversations)
	}

	func fetchRecentMessages() async throws {
		await withTaskGroup(of: Void.self) { group in
			for conversation in await DB.Conversation.using(db: db).list() {
				group.addTask {
					do {
						var conversation = conversation
						try await conversation.loadMostRecentMessages(client: self.client, db: self.db)
					} catch {
						print("Error loading most recent message for \(conversation.peerAddress): \(error)")
					}
				}
			}
		}
	}

	func refreshENS(conversations: [DB.Conversation]) async {
		if let ensRefreshedAt, ensRefreshedAt > Date().addingTimeInterval(-60 * 60) {
			return
		}

		let addresses = conversations.map(\.peerAddress)

		do {
			let ensResults = try await ensService.ens(addresses: addresses)

			for conversation in conversations {
				var conversation = conversation

				if let result = ensResults[conversation.peerAddress.lowercased()], let result {
					conversation.ens = result
					try conversation.save(db: db)
				}
			}

			ensRefreshedAt = Date()
		} catch {
			print("Error loading ENS: \(error)")
		}
	}
}
