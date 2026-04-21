//
// Created by Banghua Zhao on 21/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import UIKit
import Vision

struct DecodedBarcode: Hashable, Sendable {
  var payload: String
  var symbology: String
}

enum BarcodePhotoDecoder {
  static func decode(image: UIImage) async throws -> [DecodedBarcode] {
    guard let cgImage = image.cgImage else { return [] }
    return try await withCheckedThrowingContinuation { continuation in
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
          let sym = symbologyName(observation.symbology)
          return DecodedBarcode(payload: payload, symbology: sym)
        }
        continuation.resume(returning: decoded)
      }
      request.revision = VNDetectBarcodesRequestRevision3
      let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
      do {
        try handler.perform([request])
      } catch {
        continuation.resume(throwing: error)
      }
    }
  }

  private static func symbologyName(_ sym: VNBarcodeSymbology) -> String {
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
    default: String(describing: sym.rawValue)
    }
  }
}
