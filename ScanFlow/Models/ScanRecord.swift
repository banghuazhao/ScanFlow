//
// Created by Banghua Zhao on 21/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import SQLiteData

@Table("scan_records")
nonisolated struct ScanRecord: Identifiable, Hashable, Sendable {
  let id: Int
  var symbology: String
  var rawValue: String
  var title: String?
  var snapshotData: Data?
  var createdAt: Date
}
