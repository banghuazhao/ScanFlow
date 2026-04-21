//
// Created by Banghua Zhao on 21/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation

enum CodePayloadBuilder {
  static func payload(
    kind: CreatedCodeKind,
    phone: String,
    web: String,
    emailAddress: String,
    emailSubject: String,
    emailBody: String,
    smsNumber: String,
    smsBody: String,
    contactName: String,
    contactPhone: String,
    contactEmail: String,
    eventTitle: String,
    eventLocation: String,
    eventStart: Date,
    eventEnd: Date,
    wifiSSID: String,
    wifiPassword: String,
    wifiSecurity: String,
    plainText: String,
    latitude: String,
    longitude: String,
    barcodeText: String,
    socialURL: String
  ) -> String {
    switch kind {
    case .phone:
      let digits = phone.filter(\.isNumber)
      return digits.isEmpty ? "" : "tel:\(digits)"
    case .web:
      var url = web.trimmingCharacters(in: .whitespacesAndNewlines)
      if !url.lowercased().hasPrefix("http") { url = "https://\(url)" }
      return url
    case .email:
      var parts: [String] = []
      if !emailSubject.isEmpty { parts.append("subject=\(emailSubject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") }
      if !emailBody.isEmpty { parts.append("body=\(emailBody.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") }
      let query = parts.joined(separator: "&")
      let addr = emailAddress.trimmingCharacters(in: .whitespacesAndNewlines)
      if query.isEmpty { return "mailto:\(addr)" }
      return "mailto:\(addr)?\(query)"
    case .message:
      let num = smsNumber.filter(\.isNumber)
      let body = smsBody.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
      if num.isEmpty { return "" }
      if body.isEmpty { return "sms:\(num)" }
      return "sms:\(num)?body=\(body)"
    case .contact:
      return vCard(name: contactName, phone: contactPhone, email: contactEmail)
    case .calendar:
      return icsEvent(title: eventTitle, location: eventLocation, start: eventStart, end: eventEnd)
    case .wifi:
      let escapedSSID = wifiSSID.replacingOccurrences(of: ";", with: "\\;")
        .replacingOccurrences(of: ":", with: "\\:")
      let escapedPass = wifiPassword.replacingOccurrences(of: ";", with: "\\;")
        .replacingOccurrences(of: ":", with: "\\:")
      let sec = wifiSecurity.isEmpty ? "WPA" : wifiSecurity
      return "WIFI:S:\(escapedSSID);T:\(sec);P:\(escapedPass);H:false;;"
    case .text:
      return plainText
    case .location:
      let lat = latitude.replacingOccurrences(of: ",", with: ".")
      let lon = longitude.replacingOccurrences(of: ",", with: ".")
      if lat.isEmpty || lon.isEmpty { return "" }
      return "geo:\(lat),\(lon)"
    case .barcode:
      return barcodeText
    case .social:
      var u = socialURL.trimmingCharacters(in: .whitespacesAndNewlines)
      if !u.lowercased().hasPrefix("http") { u = "https://\(u)" }
      return u
    }
  }

  static func defaultLabel(kind: CreatedCodeKind, payload: String) -> String {
    if payload.isEmpty { return kind.title }
    if payload.count > 48 { return String(payload.prefix(45)) + "…" }
    return payload
  }

  private static func vCard(name: String, phone: String, email: String) -> String {
    """
    BEGIN:VCARD
    VERSION:3.0
    N:\(name);;;;
    FN:\(name)
    TEL;TYPE=CELL:\(phone)
    EMAIL:\(email)
    END:VCARD
    """
  }

  private static func icsEvent(title: String, location: String, start: Date, end: Date) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    let s = formatter.string(from: start)
    let e = formatter.string(from: end)
    return """
    BEGIN:VCALENDAR
    VERSION:2.0
    BEGIN:VEVENT
    SUMMARY:\(title)
    LOCATION:\(location)
    DTSTART:\(s)
    DTEND:\(e)
    END:VEVENT
    END:VCALENDAR
    """
  }
}
