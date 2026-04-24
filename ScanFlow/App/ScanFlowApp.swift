//
// Created by Banghua Zhao on 21/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Dependencies
import Foundation
import SQLiteData
import SwiftUI

@main
struct ScanFlowApp: App {
  private static let inMemoryAppStorageKey = "scanflow.usingInMemoryStore"

  init() {
    let queue: DatabaseQueue
    do {
      queue = try AppDatabase.makeDatabaseQueue()
      UserDefaults.standard.set(false, forKey: Self.inMemoryAppStorageKey)
    } catch {
      AppLog.databaseDiskOpenFailed(error)
      do {
        queue = try AppDatabase.makeInMemoryDatabaseQueue()
        UserDefaults.standard.set(true, forKey: Self.inMemoryAppStorageKey)
        AppLog.databaseUsingInMemoryOnly()
      } catch {
        AppLog.databaseInMemoryOpenFailed(error)
        fatalError("ScanFlow could not open local storage. \(error)")
      }
    }
    prepareDependencies {
      $0.defaultDatabase = queue
    }
  }

  var body: some Scene {
    WindowGroup {
      MainTabView()
    }
  }
}
