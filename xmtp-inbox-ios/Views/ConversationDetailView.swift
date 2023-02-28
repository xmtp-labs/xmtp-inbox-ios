//
//  ConversationDetailView.swift
//  XMTPiOSExample
//
//  Created by Pat Nakajima on 12/2/22.
//

import SwiftUI
import XMTP

struct ConversationDetailView: View {
	let client: XMTP.Client
	@State var conversation: DB.Conversation

	// For interactive keyboard dismiss
	@State private var offset = CGFloat()

	var body: some View {
		VStack {
			MessageListView(client: client, conversation: conversation)
				.frame(maxHeight: .infinity)
				.backgroundStyle(.blue)
			MessageComposerView(offset: $offset, onSend: sendMessage)
				.padding(.horizontal)
				.padding(.bottom)
		}
		.padding(.bottom, -offset) // For interactive keyboard dismiss
		.background(.clear)
		.navigationTitle(conversation.title)
		.navigationBarTitleDisplayMode(.inline)
		.toolbarBackground(.visible, for: .navigationBar)
		.onAppear {
			conversation.markViewed()
		}
	}

	func sendMessage(text: String, attachment: XMTP.Attachment?) async {
		do {
			try await conversation.send(text: text, attachment: attachment, client: client)
		} catch {
			await MainActor.run {
				Flash.add(.error("Error sending message: \(error)"))
			}
		}
	}
}
