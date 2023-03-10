//
//  Model.swift
//  xmtp-inbox-ios
//
//  Created by Pat Nakajima on 2/2/23.
//

import GRDB

protocol Model: Identifiable, Codable, Hashable, MutablePersistableRecord, FetchableRecord {
	static func createTable(db: GRDB.Database) throws

	// We've always got a DB ID
	var id: Int? { get set }
}

extension Model {
	static func `where`(_ predicate: SQLSpecificExpressible) async -> [Self] {
		do {
			return try await DB.read { db in
				try filter(predicate).fetchAll(db)
			}
		} catch {
			print("Error finding \(predicate) : \(error)")
			return []
		}
	}

	static func list() async -> [Self] {
		do {
			return try await DB.read { db in
				try fetchAll(db)
			}
		} catch {
			print("Error loading all \(databaseTableName): \(error)")
			return []
		}
	}

	static func list(order: SQLOrderingTerm) async -> [Self] {
		do {
			return try await DB.read { db in
				try self
					.order([order])
					.fetchAll(db)
			}
		} catch {
			print("Error loading all \(databaseTableName): \(error)")
			return []
		}
	}

	static func find(id: Int) async -> Self? {
		do {
			return try await DB.read { db in
				try find(db, key: id)
			}
		} catch {
			print("Error finding by ID (\(id)): \(error)")
			return nil
		}
	}

	static func find(_ predicate: SQLSpecificExpressible) async -> Self? {
		do {
			return try await DB.read { db in
				try filter(predicate).fetchOne(db)
			}
		} catch {
			print("Error finding \(predicate) : \(error)")
			return nil
		}
	}

	mutating func save() async throws {
		do {
			try await DB.write { db in
				try insert(db, onConflict: .replace)
			}
		} catch {
			print("Error saving \(self): \(error)")
		}
	}

	mutating func didInsert(_ inserted: InsertionSuccess) {
		id = Int(inserted.rowID)
	}
}
