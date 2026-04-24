//
// Created by Banghua Zhao on 21/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation

/// How to form a Google search for scanned content. Differs by kind: URL, retail barcode, other product codes, or plain text.
struct ScanWebSearchAction: Sendable {
  let url: URL
  let title: String
  let systemImage: String
}

enum ProductLookup {
  private static let googleSearch = "https://www.google.com/search"

  // MARK: - Public

  /// Builds a Google link and UI hints. Rules:
  /// - **URL** (http/https): `q` is the URL only (e.g. `https://example.com/abc123`), general web search.
  /// - **Retail shelf barcode** (EAN / UPC symbology, numeric): `q` = `{digits} product`, Google Shopping.
  /// - **Other product-style numbers** (8–14 digits, e.g. Code 128, QR with GTIN, ITF): `q` = `{digits} barcode`, Shopping.
  /// - **Plain text** (WiFi, vCard, random, mixed): `q` is the full value, general web search.
  static func webSearchAction(raw: String, symbology: String) -> ScanWebSearchAction? {
    let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    if t.isEmpty { return nil }

    // 1) URL — search is exactly the URL string.
    let lower = t.lowercased()
    if lower.hasPrefix("http://") || lower.hasPrefix("https://") {
      if let u = URL(string: t), u.scheme == "https" || u.scheme == "http" {
        if let found = makeGoogleURL(query: t, shopping: false) {
          return ScanWebSearchAction(url: found, title: "Web search", systemImage: "magnifyingglass")
        }
      }
    }

    // 2–3) 8–14 digit product numbers (strip spaces/hyphens; no letters).
    if isStrictProductDigitPayload(t) {
      let digits = t.filter(\.isNumber)
      if (8 ... 14).contains(digits.count) {
        let isRetail = isRetailShelfSymbology(symbology)
        let q = isRetail ? "\(digits) product" : "\(digits) barcode"
        if let found = makeGoogleURL(query: q, shopping: true) {
          return ScanWebSearchAction(url: found, title: "Find product", systemImage: "cart.fill")
        }
      }
    }

    // 4) Wi‑Fi, vCard, and everything else: full string, web search.
    if let found = makeGoogleURL(query: t, shopping: false) {
      return ScanWebSearchAction(url: found, title: "Web search", systemImage: "magnifyingglass")
    }
    return nil
  }

  // MARK: - Internals

  private static func makeGoogleURL(query: String, shopping: Bool) -> URL? {
    var c = URLComponents(string: googleSearch)
    var items: [URLQueryItem] = [URLQueryItem(name: "q", value: query)]
    if shopping { items.append(URLQueryItem(name: "tbm", value: "shop")) }
    c?.queryItems = items
    return c?.url
  }

  /// EAN-13, EAN-8, or UPC — use the `… product` shopping query.
  private static func isRetailShelfSymbology(_ symbology: String) -> Bool {
    let s = symbology.lowercased()
    return s.contains("ean13") || s.contains("ean8") || s.contains("upc")
  }

  /// Only digits plus optional group separators (no letters), 8–14 digit total when read as numbers.
  private static func isStrictProductDigitPayload(_ t: String) -> Bool {
    let d = t.filter(\.isNumber)
    guard (8 ... 14).contains(d.count) else { return false }
    for ch in t {
      if ch.isNumber { continue }
      if ch == " " || ch == "-" { continue }
      return false
    }
    return true
  }
}
