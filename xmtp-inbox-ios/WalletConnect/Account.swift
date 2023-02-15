//
//  Account.swift
//
//
//  Created by Pat Nakajima on 11/22/22.
//
import Foundation
import UIKit
import XMTP

public enum WalletProvider {
	case rainbow, metamask, coinbase, walletconnect

	var scheme: String {
		switch self {
		case .rainbow:
			return "https://rnbwapp.com"
		case .metamask:
			return "https://metamask.app.link"
		case .coinbase:
			return "cbwallet"
		case .walletconnect:
			return "wc"
		}
	}
}

/// Wrapper around a WalletConnect V1 wallet connection. Account conforms to ``SigningKey`` so
/// you can use it to create a ``Client``.
///
/// > Warning: The WalletConnect V1 API will be deprecated soon.
public struct Account {
	var connection: WCWalletConnection

	public static func create() throws -> Account {
		let connection = WCWalletConnection()
		return try Account(connection: connection)
	}

	init(connection: WCWalletConnection) throws {
		self.connection = connection
	}

	public var isConnected: Bool {
		connection.isConnected
	}

	public var address: String {
		connection.walletAddress ?? ""
	}

	public func connect() async throws {
		try await connection.connect()
	}
}

extension Account: SigningKey {
	public func sign(_ data: Data) async throws -> Signature {
		let signatureData = try await connection.sign(data)

		var signature = Signature()

		signature.ecdsaCompact.bytes = signatureData[0 ..< 64]
		signature.ecdsaCompact.recovery = UInt32(signatureData[64])

		return signature
	}

	public func sign(message: String) async throws -> Signature {
		return try await sign(Data(message.utf8))
	}
}
