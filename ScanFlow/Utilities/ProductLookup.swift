//
// Created by Banghua Zhao on 21/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation

enum ProductLookup {
  static func productSearchURL(for value: String) -> URL? {
    let digits = value.filter(\.isNumber)
    guard (8 ... 14).contains(digits.count) else { return nil }
    let encoded = digits.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? digits
    return URL(string: "https://www.google.com/search?tbm=shop&q=\(encoded)")
  }
}
