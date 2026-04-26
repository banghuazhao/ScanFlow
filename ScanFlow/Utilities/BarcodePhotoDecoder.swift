//
// Created by Banghua Zhao on 21/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import ImageIO
import UIKit
import Vision

struct DecodedBarcode: Hashable, Sendable {
  var payload: String
  var symbology: String
}

enum BarcodePhotoDecoder {
  /// Decodes barcodes from a still image using Vision.
  ///
  /// The Swift concurrency `DetectBarcodesRequest` path can fail on the simulator (and occasionally
  /// on device) with `operationFailed("Failed to create barcode detector.")`. The simulator uses the
  /// classic `VNDetectBarcodesRequest` with `usesCPUOnly`; on device we try the modern API first
  /// and fall back to the classic request when needed.
  static func decode(image: UIImage) async throws -> [DecodedBarcode] {
    guard let cgImage = image.cgImage else { return [] }
    let orientation = CGImagePropertyOrientation(image.imageOrientation)

    #if targetEnvironment(simulator)
    return try await decodeLegacy(cgImage: cgImage, orientation: orientation)
    #else
    do {
      return try await decodeModern(cgImage: cgImage, orientation: orientation)
    } catch {
      return try await decodeLegacy(cgImage: cgImage, orientation: orientation)
    }
    #endif
  }

  // MARK: - Modern (Swift concurrency)

  private static func decodeModern(
    cgImage: CGImage,
    orientation: CGImagePropertyOrientation
  ) async throws -> [DecodedBarcode] {
    let request = DetectBarcodesRequest()
    let observations = try await request.perform(on: cgImage, orientation: orientation)
    return observations.compactMap { observation in
      guard let payload = observation.payloadString else { return nil }
      return DecodedBarcode(payload: payload, symbology: symbologyLabel(observation.symbology))
    }
  }

  // MARK: - Legacy (VN* — reliable on Simulator / fallback)

  private static func decodeLegacy(
    cgImage: CGImage,
    orientation: CGImagePropertyOrientation
  ) async throws -> [DecodedBarcode] {
    try await withCheckedThrowingContinuation { continuation in
      let request = VNDetectBarcodesRequest { request, error in
        if let error {
          continuation.resume(throwing: error)
          return
        }
        guard let results = request.results as? [VNBarcodeObservation] else {
          continuation.resume(returning: [])
          return
        }
        let decoded = results.compactMap { observation -> DecodedBarcode? in
          guard let payload = observation.payloadStringValue else { return nil }
          let sym = symbologyLabel(observation.symbology)
          return DecodedBarcode(payload: payload, symbology: sym)
        }
        continuation.resume(returning: decoded)
      }
      request.revision = VNDetectBarcodesRequestRevision3
      let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
      do {
        try handler.perform([request])
      } catch {
        continuation.resume(throwing: error)
      }
    }
  }

  // MARK: - Symbology labels

  private static func symbologyLabel(_ sym: BarcodeSymbology) -> String {
    switch sym {
    case .qr: "QR"
    case .aztec: "Aztec"
    case .pdf417: "PDF417"
    case .dataMatrix: "DataMatrix"
    case .ean8: "EAN-8"
    case .ean13: "EAN-13"
    case .upce: "UPC-E"
    case .code128: "Code128"
    case .code39: "Code39"
    case .code93: "Code93"
    case .itf14: "ITF14"
    case .codabar: "Codabar"
    case .code39Checksum, .code39FullASCII, .code39FullASCIIChecksum: "Code39"
    case .code93i: "Code93"
    case .gs1DataBar, .gs1DataBarExpanded, .gs1DataBarLimited: "GS1DataBar"
    case .i2of5, .i2of5Checksum: "I2of5"
    case .microPDF417: "MicroPDF417"
    case .microQR: "MicroQR"
    case .msiPlessey: "MSIPlessey"
    @unknown default:
      String(describing: sym)
    }
  }

  private static func symbologyLabel(_ sym: VNBarcodeSymbology) -> String {
    switch sym {
    case .qr: "QR"
    case .aztec: "Aztec"
    case .pdf417: "PDF417"
    case .dataMatrix: "DataMatrix"
    case .ean8: "EAN-8"
    case .ean13: "EAN-13"
    case .upce: "UPC-E"
    case .code128: "Code128"
    case .code39: "Code39"
    case .code93: "Code93"
    case .itf14: "ITF14"
    default:
      String(describing: sym.rawValue)
    }
  }
}

private extension CGImagePropertyOrientation {
  init(_ uiOrientation: UIImage.Orientation) {
    switch uiOrientation {
    case .up: self = .up
    case .upMirrored: self = .upMirrored
    case .down: self = .down
    case .downMirrored: self = .downMirrored
    case .left: self = .left
    case .leftMirrored: self = .leftMirrored
    case .right: self = .right
    case .rightMirrored: self = .rightMirrored
    @unknown default:
      self = .up
    }
  }
}
