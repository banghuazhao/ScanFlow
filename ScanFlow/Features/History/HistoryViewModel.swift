//
// Created by Banghua Zhao on 21/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Dependencies
import Foundation
import Observation
import SQLiteData

@Observable @MainActor
final class HistoryViewModel {
  @ObservationIgnored
  @FetchAll(ScanRecord.order { $0.createdAt.desc() })
  var scans: [ScanRecord]

  @ObservationIgnored
  @Dependency(\.defaultDatabase) private var database

  func delete(_ record: ScanRecord) {
    do {
      try database.write { db in
        try ScanRecord.delete(record).execute(db)
      }
    } catch {
      AppLog.logPersistenceError("Delete scan", error)
    }
  }

  func delete(at offsets: IndexSet) {
    for index in offsets {
      let record = scans[index]
      delete(record)
    }
  }
}
