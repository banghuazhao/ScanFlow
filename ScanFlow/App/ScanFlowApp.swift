//
// Created by Banghua Zhao on 21/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Dependencies
import SQLiteData
import SwiftUI

@main
struct ScanFlowApp: App {
  init() {
    prepareDependencies {
      $0.defaultDatabase = try! AppDatabase.makeDatabaseQueue()
    }
  }

  var body: some Scene {
    WindowGroup {
      MainTabView()
    }
  }
}
