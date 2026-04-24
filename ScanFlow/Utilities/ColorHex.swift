//
// Created by Banghua Zhao on 21/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI
import UIKit

extension Color {
  /// Parses 6-character RGB hex, with or without `#`.
  init?(rgbHex: String) {
    var s = rgbHex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    if s.hasPrefix("#") { s.removeFirst() }
    guard s.count == 6 else { return nil }
    var value: UInt64 = 0
    guard Scanner(string: s).scanHexInt64(&value) else { return nil }
    self.init(
      red: Double((value & 0xFF0000) >> 16) / 255,
      green: Double((value & 0x00FF00) >> 8) / 255,
      blue: Double(value & 0x0000FF) / 255
    )
  }

  /// 6 uppercase hex digits for QR styling (no `#`).
  func rgbHexString() -> String {
    let ui = UIColor(self)
    var r: CGFloat = 0
    var g: CGFloat = 0
    var b: CGFloat = 0
    var a: CGFloat = 0
    guard ui.getRed(&r, green: &g, blue: &b, alpha: &a) else {
      return "000000"
    }
    return String(
      format: "%02X%02X%02X",
      Int(round(r * 255)),
      Int(round(g * 255)),
      Int(round(b * 255))
    )
  }
}
