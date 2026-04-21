//
// Created by Banghua Zhao on 21/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Dependencies
import Observation
import SQLiteData

@Observable @MainActor
final class SettingsViewModel {
  @ObservationIgnored
  @Dependency(\.defaultDatabase) private var database

  func deleteAllData() {
    do {
      try database.write { db in
        try db.execute(sql: "DELETE FROM scan_records")
        try db.execute(sql: "DELETE FROM created_codes")
      }
    } catch {}
  }
}
