//
// Created by Banghua Zhao on 21/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation

enum CodeModuleShape: String, CaseIterable, Codable, Hashable, Sendable {
  case square
  case rounded
  case circle
}

enum CodePupilShape: String, CaseIterable, Codable, Hashable, Sendable {
  case square
  case rounded
  case circle
}

enum CodeCenterMode: String, CaseIterable, Codable, Hashable, Sendable {
  case none
  case auto
  case custom
}

struct CodeStyleConfiguration: Codable, Hashable, Sendable {
  var foregroundHex: String
  var backgroundHex: String
  var moduleShape: CodeModuleShape
  var pupilShape: CodePupilShape
  var centerMode: CodeCenterMode

  static let `default` = CodeStyleConfiguration(
    foregroundHex: "000000",
    backgroundHex: "FFFFFF",
    moduleShape: .square,
    pupilShape: .square,
    centerMode: .none
  )

  static func decode(from json: String) -> CodeStyleConfiguration {
    guard let data = json.data(using: .utf8),
          let value = try? JSONDecoder().decode(CodeStyleConfiguration.self, from: data)
    else {
      return .default
    }
    return value
  }

  func encodedJSON() -> String {
    (try? JSONEncoder().encode(self)).flatMap { String(data: $0, encoding: .utf8) } ?? "{\"foregroundHex\":\"000000\"}"
  }
}
