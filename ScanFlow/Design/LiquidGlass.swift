//
// Created by Banghua Zhao on 21/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

enum LiquidGlass {
  static let cornerLarge: CGFloat = 28
  static let cornerMedium: CGFloat = 20
  static let cornerSmall: CGFloat = 14
  static let cardShadowRadius: CGFloat = 12
  static let cardShadowY: CGFloat = 4

  static let headerGradient = LinearGradient(
    colors: [
      Color(red: 0.25, green: 0.55, blue: 1.0),
      Color(red: 0.55, green: 0.35, blue: 0.95),
      Color(red: 0.75, green: 0.25, blue: 0.82),
    ],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
  )

  static let iconGradient = LinearGradient(
    colors: [
      Color(red: 0.45, green: 0.35, blue: 0.95),
      Color(red: 0.85, green: 0.35, blue: 0.65),
    ],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
  )

  static let subtleScreenBackground = LinearGradient(
    colors: [
      Color(.systemGroupedBackground),
      Color(.systemGroupedBackground).opacity(0.92),
      Color(red: 0.94, green: 0.93, blue: 0.98),
    ],
    startPoint: .top,
    endPoint: .bottom
  )
}

struct GlassCard<Content: View>: View {
  var padding: CGFloat = 16
  @ViewBuilder var content: () -> Content

  var body: some View {
    content()
      .padding(padding)
      .background {
        RoundedRectangle(cornerRadius: LiquidGlass.cornerMedium, style: .continuous)
          .fill(.ultraThinMaterial)
          .shadow(
            color: .black.opacity(0.08),
            radius: LiquidGlass.cardShadowRadius,
            x: 0,
            y: LiquidGlass.cardShadowY
          )
      }
  }
}

struct GradientIconBadge: View {
  var systemName: String
  var size: CGFloat = 44

  var body: some View {
    RoundedRectangle(cornerRadius: LiquidGlass.cornerSmall, style: .continuous)
      .fill(LiquidGlass.iconGradient)
      .frame(width: size, height: size)
      .overlay {
        Image(systemName: systemName)
          .font(.system(size: size * 0.38, weight: .semibold))
          .foregroundStyle(.white)
      }
      .shadow(color: Color.purple.opacity(0.25), radius: 8, y: 4)
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
        .background {
          Circle()
            .fill(.ultraThinMaterial)
            .overlay {
              Circle()
                .strokeBorder(.white.opacity(0.2), lineWidth: 1)
            }
        }
    }
    .buttonStyle(.plain)
  }
}

extension View {
  func liquidGlassListRow() -> some View {
    listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
      .listRowBackground(
        RoundedRectangle(cornerRadius: LiquidGlass.cornerMedium, style: .continuous)
          .fill(.ultraThinMaterial)
          .padding(.vertical, 4)
          .padding(.horizontal, 4)
      )
  }

  func scanflowScreenBackground() -> some View {
    background {
      ZStack {
        Color(.systemGroupedBackground)
        LiquidGlass.subtleScreenBackground
          .opacity(0.6)
      }
      .ignoresSafeArea()
    }
  }
}

struct TabBarGlassModifier: ViewModifier {
  func body(content: Content) -> some View {
    content
      .toolbarBackground(.ultraThinMaterial, for: .tabBar)
      .toolbarBackground(.visible, for: .tabBar)
  }
}
