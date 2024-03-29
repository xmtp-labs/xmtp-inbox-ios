//
//  xmtp_inbox_iosApp.swift
//  xmtp-inbox-ios
//
//  Created by Elise Alix on 12/20/22.
//

import SDWebImage
import SDWebImageWebPCoder
import SwiftUI
import XMTP

class AppDelegate: NSObject, UIApplicationDelegate {
	func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
		XMTPPush.shared.setPushServer(Constants.xmtpPush)

		Client.register(codec: AttachmentCodec())
		Client.register(codec: RemoteAttachmentCodec())
		SDImageCodersManager.shared.addCoder(SDImageWebPCoder.shared)

		return true
	}

	func application(_: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
		Task {
			do {
				let deviceTokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
				try await XMTPPush.shared.register(token: deviceTokenString)
			} catch {
				print("Error registering: \(error)")
			}
		}
	}

	func application(_: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
		print("Could not register for remote notifications:")
		print(error.localizedDescription)
	}
}

@main
struct xmtp_inbox_iosApp: App {
	@UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
	@AppStorage("dbVersion") var dbVersion: Int = 0

	var body: some Scene {
		WindowGroup {
			ContentView()
		}
	}
}
