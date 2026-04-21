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

@Observable @MainActor
final class ScanViewModel {
  var isTorchOn = false
  var cameraDenied = false
  var lastScannedValue: String?
  var lastSymbology: String?
  var lastPreviewImage: UIImage?
  var scanDetailPresented = false
  var throttleUntil: Date = .distantPast

  @ObservationIgnored
  @Dependency(\.defaultDatabase) private var database

  func checkCameraAuthorization() {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized:
      cameraDenied = false
    case .notDetermined:
      AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
        Task { @MainActor in
          self?.cameraDenied = !granted
        }
      }
    default:
      cameraDenied = true
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
      }
    } catch {}
  }
}
