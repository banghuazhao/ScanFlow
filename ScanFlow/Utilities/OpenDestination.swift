//
// Created by Banghua Zhao on 25/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation

/// Resolves a URL that can be opened in another app (browser, phone, maps, product link, custom schemes).
/// Does not include generic web search; plain text is not "openable" for the Open action.
enum OpenDestination {
  static func url(for raw: String) -> URL? {
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }
    let lower = trimmed.lowercased()

    if lower.hasPrefix("http"), let u = URL(string: trimmed) { return u }
    if lower.hasPrefix("tel:"), let u = URL(string: trimmed) { return u }
    if lower.hasPrefix("mailto:"), let u = URL(string: trimmed) { return u }
    if lower.hasPrefix("sms:"), let u = URL(string: trimmed) { return u }
    if lower.hasPrefix("geo:") {
      let q = trimmed.replacingOccurrences(of: "geo:", with: "")
        .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
      if !q.isEmpty { return URL(string: "https://maps.apple.com/?q=\(q)") }
    }
    if let u = URL(string: trimmed), let scheme = u.scheme, !scheme.isEmpty, scheme != "file" {
      return u
    }
    return ProductLookup.productSearchURL(for: raw)
  }
}
