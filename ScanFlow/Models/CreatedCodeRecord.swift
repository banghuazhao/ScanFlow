//
// Created by Banghua Zhao on 21/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import SQLiteData

@Table("created_codes")
nonisolated struct CreatedCodeRecord: Identifiable, Hashable, Sendable {
  let id: Int
  var kind: CreatedCodeKind
  var payload: String
  var displayLabel: String
  var styleJSON: String
  var centerImageData: Data?
  var createdAt: Date
  var updatedAt: Date
}
