//
// Created by Banghua Zhao on 21/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import SQLiteData

enum CreatedCodeKind: String, CaseIterable, Hashable, Sendable, QueryBindable {
  case phone
  case web
  case email
  case message
  case contact
  case calendar
  case wifi
  case text
  case location
  case barcode
  case social

  var title: String {
    switch self {
    case .phone: "Phone"
    case .web: "Website"
    case .email: "Email"
    case .message: "Message"
    case .contact: "Contact"
    case .calendar: "Calendar"
    case .wifi: "Wi‑Fi"
    case .text: "Text"
    case .location: "Location"
    case .barcode: "Barcode"
    case .social: "Social"
    }
  }
}
