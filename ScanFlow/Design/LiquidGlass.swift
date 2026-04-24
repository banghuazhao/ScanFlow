//
// Created by Banghua Zhao on 21/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

/// Layout constants; surfaces use system **Liquid Glass** via `glassEffect(_:in:)`.
enum LiquidGlass {
  static let cornerLarge: CGFloat = 28
  static let cornerMedium: CGFloat = 20
  static let cornerSmall: CGFloat = 14
}

struct GlassCard<Content: View>: View {
  var padding: CGFloat = 16
  @ViewBuilder var content: () -> Content

  var body: some View {
    content()
      .padding(padding)
      .glassEffect(
        .regular,
        in: RoundedRectangle(cornerRadius: LiquidGlass.cornerMedium, style: .continuous)
      )
  }
}

struct GradientIconBadge: View {
  var systemName: String
  var size: CGFloat = 44

  var body: some View {
    Image(systemName: systemName)
      .font(.system(size: size * 0.38, weight: .semibold))
      .foregroundStyle(.primary)
      .frame(width: size, height: size)
      .glassEffect(
        .regular.tint(.blue),
        in: RoundedRectangle(cornerRadius: LiquidGlass.cornerSmall, style: .continuous)
      )
  }
}

struct GlassCircleButton: View {
  var systemName: String
  var isActive: Bool = false
  var action: () -> Void

  var body: some View {
    Button(action: action) {
      Image(systemName: systemName)
        .font(.system(size: 18, weight: .semibold))
        .foregroundStyle(isActive ? .yellow : .white)
        .frame(width: 48, height: 48)
        .glassEffect(.regular.interactive(), in: Circle())
    }
    .buttonStyle(.plain)
  }
}

extension View {
  /// System grouped background only (no custom gradients).
  func scanflowScreenBackground() -> some View {
    background(Color(.systemGroupedBackground).ignoresSafeArea())
  }
}

struct TabBarGlassModifier: ViewModifier {
  func body(content: Content) -> some View {
    content
  }
}
