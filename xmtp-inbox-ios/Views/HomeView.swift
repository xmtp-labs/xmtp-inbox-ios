//
//  HomeView.swift
//  xmtp-inbox-ios
//
//  Created by Elise Alix on 12/20/22.
//

import SwiftUI
import XMTP

class EnvironmentCoordinator: ObservableObject {
    @Published var path = NavigationPath()
}

struct HomeView: View {

    let client: XMTP.Client

    @StateObject var environmentCoordinator = EnvironmentCoordinator()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundPrimary.edgesIgnoringSafeArea(.all)

                ConversationListView(client: client)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: NavigationLink(destination: SettingsView(client: client)) {
                EnsImageView(imageSize: 40.0, peerAddress: client.address)
            })
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Image("MessageIcon")
                            .renderingMode(.template)
                            .colorMultiply(.textPrimary)
                            .frame(width: 16.0, height: 16.0)
                        Text("home-title").font(.Title2H)
                            .accessibilityAddTraits(.isHeader)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                }
            }
        }
        .accentColor(.textPrimary)
        .environmentObject(environmentCoordinator)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            PreviewClientProvider { client in
                HomeView(client: client)
            }
        }
    }
}
