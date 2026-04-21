//
// Created by Banghua Zhao on 21/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation

enum SymbologyDisplay {
  static func friendlyName(_ raw: String) -> String {
    let r = raw.lowercased()
    if r.contains("qr") { return "QR Code" }
    if r.contains("ean13") { return "EAN-13" }
    if r.contains("ean8") { return "EAN-8" }
    if r.contains("upc") { return "UPC" }
    if r.contains("code128") { return "Code 128" }
    if r.contains("code39") { return "Code 39" }
    if r.contains("code93") { return "Code 93" }
    if r.contains("pdf417") { return "PDF417" }
    if r.contains("aztec") { return "Aztec" }
    if r.contains("data") && r.contains("matrix") { return "Data Matrix" }
    if r.contains("itf") { return "ITF" }
    if r.contains("interleaved") { return "Interleaved 2 of 5" }
    return raw.replacingOccurrences(of: "AVMetadataObjectType", with: "")
  }

  static func iconName(_ raw: String) -> String {
    let r = raw.lowercased()
    if r.contains("qr") || r.contains("aztec") || r.contains("data") { return "qrcode" }
    return "barcode"
  }
}
