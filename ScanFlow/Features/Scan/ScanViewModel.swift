//
// Created by Banghua Zhao on 21/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import AVFoundation
import Dependencies
import Foundation
import Observation
import SQLiteData
import UIKit

enum CameraAccess: Equatable {
  /// System permission dialog not answered yet, or we have not re-checked.
  case undetermined
  case authorized
  case denied
  case restricted
}

@Observable @MainActor
final class ScanViewModel {
  /// Bumped when camera goes from "waiting for permission" to `authorized` so the capture session is recreated.
  var cameraScannerViewID: Int = 0

  var cameraAccess: CameraAccess
  var lastScannedValue: String?
  var lastSymbology: String?
  var lastPreviewImage: UIImage?
  var scanDetailPresented = false
  var throttleUntil: Date = .distantPast
  /// Row id of the most recently persisted scan (camera or photo) while the detail sheet is relevant.
  var lastPersistedScanId: Int?

  @ObservationIgnored
  @Dependency(\.defaultDatabase) private var database

  /// Prevents `requestAccess` from being invoked twice in the same notDetermined window (e.g. `onAppear` + `scenePhase`).
  @ObservationIgnored
  private var didRequestCameraAccess = false

  init() {
    cameraAccess = Self.currentCameraAccess()
  }

  private static func currentCameraAccess() -> CameraAccess {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized:
      return .authorized
    case .notDetermined:
      return .undetermined
    case .denied:
      return .denied
    case .restricted:
      return .restricted
    @unknown default:
      return .denied
    }
  }

  func checkCameraAuthorization() {
    let status = AVCaptureDevice.authorizationStatus(for: .video)
    switch status {
    case .authorized:
      cameraAccess = .authorized
    case .notDetermined:
      cameraAccess = .undetermined
      if !didRequestCameraAccess {
        didRequestCameraAccess = true
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
          Task { @MainActor in
            guard let self else { return }
            if granted {
              self.cameraAccess = .authorized
              self.cameraScannerViewID &+= 1
            } else {
              self.cameraAccess = .denied
            }
          }
        }
      }
    case .denied:
      cameraAccess = .denied
    case .restricted:
      cameraAccess = .restricted
    @unknown default:
      cameraAccess = .denied
    }
  }

  func handleScan(value: String, avType: AVMetadataObject.ObjectType, hapticsEnabled: Bool) {
    let sym = avType.rawValue.replacingOccurrences(of: "AVMetadataObjectType", with: "")
    let now = Date()
    if now < throttleUntil, lastScannedValue == value { return }
    throttleUntil = now.addingTimeInterval(1.2)
    lastScannedValue = value
    lastSymbology = sym
    lastPreviewImage = synthesizedPreview(symbology: sym, value: value)
    Haptics.success(enabled: hapticsEnabled)
    persistScan(symbology: sym, value: value, image: lastPreviewImage)
    scanDetailPresented = true
  }

  func handlePhotoScan(results: [DecodedBarcode], hapticsEnabled: Bool) {
    guard let first = results.first else { return }
    lastScannedValue = first.payload
    lastSymbology = first.symbology
    lastPreviewImage = synthesizedPreview(symbology: first.symbology, value: first.payload)
    Haptics.success(enabled: hapticsEnabled)
    persistScan(symbology: first.symbology, value: first.payload, image: lastPreviewImage)
    scanDetailPresented = true
  }

  func clearDetail() {
    scanDetailPresented = false
  }

  /// Deletes the scan row created for the current in-session result and dismisses the detail sheet.
  func deleteLastScannedIfPresented() {
    if let id = lastPersistedScanId {
      do {
        try database.write { db in
          try db.execute(sql: "DELETE FROM scan_records WHERE id = ?", arguments: [id])
        }
      } catch {
        AppLog.logPersistenceError("Delete last scan", error)
      }
    }
    lastPersistedScanId = nil
    lastScannedValue = nil
    lastSymbology = nil
    lastPreviewImage = nil
    clearDetail()
  }

  private func synthesizedPreview(symbology: String, value: String) -> UIImage? {
    let style = CodeStyleConfiguration.default
    if symbology.contains("QR") || symbology == "qr" {
      return QRBarcodeImageGenerator.qrUIImage(payload: value, style: style, centerImage: nil)
    }
    return QRBarcodeImageGenerator.linearBarcodeUIImage(payload: value, style: style)
  }

  private func persistScan(symbology: String, value: String, image: UIImage?) {
    let data = image.flatMap { $0.jpegData(compressionQuality: 0.82) }
    let title = value.count > 44 ? String(value.prefix(41)) + "…" : value
    var newId: Int?
    do {
      try database.write { db in
        try ScanRecord.insert {
          ScanRecord.Draft(
            symbology: symbology,
            rawValue: value,
            title: title,
            snapshotData: data,
            createdAt: Date()
          )
        }.execute(db)
        newId = Int(db.lastInsertedRowID)
      }
    } catch {
      AppLog.logPersistenceError("Persist scan", error)
      newId = nil
    }
    lastPersistedScanId = newId
  }
}
