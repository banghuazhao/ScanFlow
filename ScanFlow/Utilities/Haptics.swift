//
// Created by Banghua Zhao on 21/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import UIKit

enum Haptics {
  static func success(enabled: Bool) {
    guard enabled else { return }
    UINotificationFeedbackGenerator().notificationOccurred(.success)
  }

  static func light(enabled: Bool) {
    guard enabled else { return }
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
  }
}
