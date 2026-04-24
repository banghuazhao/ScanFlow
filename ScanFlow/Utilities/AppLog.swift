//
// Created by Banghua Zhao on 25/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import OSLog
import os

enum AppLog {
  static let database = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ScanFlow", category: "database")
  static let persistence = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ScanFlow", category: "persistence")

  static func logPersistenceError(_ context: String, _ error: Error) {
    persistence.error("\(context): \(error.localizedDescription, privacy: .public)")
  }

  static func databaseDiskOpenFailed(_ error: Error) {
    database.error("On-disk database failed: \(error.localizedDescription, privacy: .public)")
  }

  static func databaseInMemoryOpenFailed(_ error: Error) {
    database.critical("In-memory database failed: \(error.localizedDescription, privacy: .public)")
  }

  static func databaseUsingInMemoryOnly() {
    database.notice("Using in-memory database; data will not persist after quit.")
  }
}
