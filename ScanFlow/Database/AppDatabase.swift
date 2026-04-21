//
// Created by Banghua Zhao on 21/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import GRDB
import SQLiteData

enum AppDatabase {
  static func makeDatabaseQueue() throws -> DatabaseQueue {
    let fileManager = FileManager.default
    let folder = try fileManager.url(
      for: .applicationSupportDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: true
    )
    .appendingPathComponent("ScanFlow", isDirectory: true)
    try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
    let url = folder.appendingPathComponent("scanflow.sqlite")
    let dbQueue = try DatabaseQueue(path: url.path)
    var migrator = DatabaseMigrator()
    migrator.registerMigration("initial") { db in
      try db.create(table: "scan_records", ifNotExists: true) { t in
        t.autoIncrementedPrimaryKey("id")
        t.column("symbology", .text).notNull()
        t.column("rawValue", .text).notNull()
        t.column("title", .text)
        t.column("snapshotData", .blob)
        t.column("createdAt", .text).notNull()
      }
      try db.create(table: "created_codes", ifNotExists: true) { t in
        t.autoIncrementedPrimaryKey("id")
        t.column("kind", .text).notNull()
        t.column("payload", .text).notNull()
        t.column("displayLabel", .text).notNull()
        t.column("styleJSON", .text).notNull()
        t.column("centerImageData", .blob)
        t.column("createdAt", .text).notNull()
        t.column("updatedAt", .text).notNull()
      }
    }
    try migrator.migrate(dbQueue)
    return dbQueue
  }
}
