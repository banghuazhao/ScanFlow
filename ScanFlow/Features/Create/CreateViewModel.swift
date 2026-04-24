//
// Created by Banghua Zhao on 21/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Dependencies
import Foundation
import Observation
import SQLiteData
import UIKit

@Observable @MainActor
final class CreateViewModel {
  @ObservationIgnored
  @FetchAll(CreatedCodeRecord.order { $0.updatedAt.desc() })
  var codes: [CreatedCodeRecord]

  @ObservationIgnored
  @Dependency(\.defaultDatabase) private var database

  func delete(_ record: CreatedCodeRecord) {
    do {
      try database.write { db in
        try CreatedCodeRecord.delete(record).execute(db)
      }
    } catch {
      AppLog.logPersistenceError("Delete created code", error)
    }
  }

  func saveNew(
    kind: CreatedCodeKind,
    payload: String,
    label: String,
    style: CodeStyleConfiguration,
    centerImageData: Data?
  ) {
    let now = Date()
    let json = style.encodedJSON()
    do {
      try database.write { db in
        try CreatedCodeRecord.insert {
          CreatedCodeRecord.Draft(
            kind: kind,
            payload: payload,
            displayLabel: label,
            styleJSON: json,
            centerImageData: centerImageData,
            createdAt: now,
            updatedAt: now
          )
        }.execute(db)
      }
    } catch {
      AppLog.logPersistenceError("Insert created code", error)
    }
  }

  func update(_ record: CreatedCodeRecord) {
    do {
      try database.write { db in
        try CreatedCodeRecord.update(record).execute(db)
      }
    } catch {
      AppLog.logPersistenceError("Update created code", error)
    }
  }

  func image(for record: CreatedCodeRecord) -> UIImage? {
    let style = CodeStyleConfiguration.decode(from: record.styleJSON)
    let center = record.centerImageData.flatMap { UIImage(data: $0) }
    switch record.kind {
    case .barcode:
      return QRBarcodeImageGenerator.linearBarcodeUIImage(payload: record.payload, style: style)
    default:
      return QRBarcodeImageGenerator.qrUIImage(
        payload: record.payload,
        style: style,
        centerImage: center
      )
    }
  }
}
