//
//  ConversationListView.swift
//  xmtp-inbox-ios
//
//  Created by Elise Alix on 12/22/22.
//

import Combine
import GRDBQuery
import SwiftUI
import XMTP

struct ConversationListView: View {
	enum LoadingStatus {
		case loading, empty, success, error(String)
	}

	let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
	@State @MainActor var isLoading = false

	let client: XMTP.Client
	let db: DB
	@Binding var selectedConversation: DB.Conversation?

	@State private var status: LoadingStatus = .success
	@State var isShowingNewMessage = false

	@EnvironmentObject var coordinator: EnvironmentCoordinator
	@StateObject private var conversationLoader: ConversationLoader

	@Query(ConversationsRequest(), in: \.dbQueue) var conversations: [DB.Conversation]

	init(client: XMTP.Client, db: DB) {
		let conversationLoader = ConversationLoader(client: client, db: db)

		self.client = client
		self.db = db
		_conversationLoader = StateObject(wrappedValue: conversationLoader)
		_selectedConversation = .constant(nil)
	}

	init(client: XMTP.Client, selectedConversation: Binding<DB.Conversation?>, db: DB) {
		let conversationLoader = ConversationLoader(client: client, db: db)

		self.client = client
		self.db = db
		_conversationLoader = StateObject(wrappedValue: conversationLoader)
		_selectedConversation = selectedConversation
	}

	var body: some View {
		ZStack {
			switch status {
			case .loading:
				ProgressView("Loading…")
			case .empty:
				if let error = conversationLoader.error {
					Text(error.localizedDescription)
				} else {
					Text("conversations-empty")
						.padding()
				}
			case let .error(errorMessage):
				Text(errorMessage)
					.padding()
			case .success:
				List {
					ForEach(conversations) { conversation in
						ConversationCellView(conversation: conversation)
							.padding(.horizontal, 8)
							.padding(.vertical)
							.contentShape(Rectangle())
							.listRowInsets(EdgeInsets())
							.listRowBackground(conversation.title == selectedConversation?.title ? Color("BackgroundSecondary") : Color.clear)
							.onTapGesture {
								self.selectedConversation = conversation
								coordinator.path.append(conversation)
							}
					}
				}
				.listStyle(.plain)
				.scrollContentBackground(.hidden)
				.refreshable {
					await loadConversations()
				}
			}
			VStack {
				Spacer()
				HStack {
					Spacer()
					FloatingButton(icon: Image("PlusIcon")) {
						isShowingNewMessage.toggle()
					}
					.padding(24)
				}
			}
			.frame(maxWidth: .infinity)
			.frame(maxHeight: .infinity)
		}
		.onAppear {
			timer.upstream.connect()
			Task.detached {
				await loadConversations()
			}
		}
		.onDisappear {
			timer.upstream.connect().cancel()
		}
		.onReceive(timer) { _ in
			if isLoading {
				return
			}

			Task {
				await loadConversations()
			}
		}
		.task {
			await streamConversations()
		}
		.sheet(isPresented: $isShowingNewMessage) {
			NewConversationView(client: client) { conversation in
				coordinator.path.append(conversation)
			}
		}
	}

	func loadConversations() async {
		print("load conversations called")
		if isLoading {
			return
		}

		do {
			await MainActor.run {
				withAnimation {
					if conversations.isEmpty {
						self.status = .loading
						self.isLoading = true
					}
				}
			}

			try await conversationLoader.load()

			await MainActor.run {
				self.isLoading = false
				withAnimation {
					if conversations.isEmpty {
						self.status = .empty
					} else {
						self.status = .success
					}
				}
			}
		} catch {
			print("ERROR LOADING CONVERSATIONS \(error)")
			await MainActor.run {
				if conversations.isEmpty {
					self.status = .error(error.localizedDescription)
					self.isLoading = false
				} else {
					self.isLoading = false
					Flash.add(.error("Error loading conversations: \(error)"))
				}
			}
		}
	}

	func streamConversations() async {
		do {
			for try await newConversation in client.conversations.stream()
				where newConversation.peerAddress != client.address
			{
				var newConversation = try await DB.Conversation.from(newConversation, db: db)
				try await newConversation.loadMostRecentMessages(client: client, db: db)
			}
		} catch {
			await MainActor.run {
				if conversations.isEmpty {
					self.status = .error(error.localizedDescription)
				} else {
					Flash.add(.error("Error streaming conversations: \(error)"))
				}
			}
		}
	}
}

struct ConversationListView_Previews: PreviewProvider {
	static var previews: some View {
		VStack {
			PreviewClientProvider { client in
				NavigationView {
					ConversationListView(client: client, db: DB.prepareTest())
				}
			}
		}
	}
}
