//
// Created by Banghua Zhao on 21/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

struct CopiedToastModifier: ViewModifier {
  @Binding var isPresented: Bool
  var message: String

  func body(content: Content) -> some View {
    content
      .overlay(alignment: .center) {
        if isPresented {
          Text(message)
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(.regularMaterial, in: Capsule())
            .shadow(color: .black.opacity(0.15), radius: 8, y: 2)
            .transition(.scale.combined(with: .opacity))
        }
      }
      .animation(.spring(duration: 0.28), value: isPresented)
      .onChange(of: isPresented) { _, on in
        guard on else { return }
        Task { @MainActor in
          try? await Task.sleep(for: .seconds(1.35))
          isPresented = false
        }
      }
  }
}

extension View {
  func copiedToast(_ message: String = "Copied", isPresented: Binding<Bool>) -> some View {
    modifier(CopiedToastModifier(isPresented: isPresented, message: message))
  }
}
