//
// Created by Banghua Zhao on 21/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI
import UIKit

struct CreatedCodeDetailView: View {
  @Environment(\.dismiss) private var dismiss
  let record: CreatedCodeRecord
  let model: CreateViewModel

  @AppStorage("scanflow.hapticsEnabled") private var hapticsEnabled = true
  @State private var showShare = false
  @State private var shareItems: [Any] = []
  @State private var showEdit = false

  var body: some View {
    ScrollView {
      VStack(spacing: 0) {
        headerSection
        contentSection
      }
    }
    .background(Color(.systemGroupedBackground))
    .navigationTitle("Code")
    .navigationBarTitleDisplayMode(.inline)
    .toolbarBackground(.hidden, for: .navigationBar)
    .toolbarColorScheme(.dark, for: .navigationBar)
    .sheet(isPresented: $showShare) {
      ShareSheet(items: shareItems)
    }
    .sheet(isPresented: $showEdit) {
      NavigationStack {
        CreateCodeEditorView(
          model: model,
          mode: .edit(record),
          onFinished: { showEdit = false }
        )
      }
    }
  }

  private var headerSection: some View {
    ZStack {
      LiquidGlass.headerGradient
      VStack(spacing: 18) {
        Text(record.displayLabel)
          .font(.headline.weight(.bold))
          .foregroundStyle(.white)
          .lineLimit(1)
          .shadow(color: .black.opacity(0.25), radius: 4, y: 1)

        if let ui = model.image(for: record) {
          Image(uiImage: ui)
            .resizable()
            .interpolation(.none)
            .scaledToFit()
            .padding(18)
            .frame(maxWidth: 260, maxHeight: 260)
            .background {
              RoundedRectangle(cornerRadius: LiquidGlass.cornerMedium, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
            }
        }
      }
      .padding(.horizontal, 20)
      .padding(.bottom, 28)
    }
  }

  private var contentSection: some View {
    VStack(spacing: 16) {
      GlassCard {
        VStack(alignment: .leading, spacing: 8) {
          Text("Kind")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
          Text(record.kind.title)
            .font(.body.weight(.medium))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }

      GlassCard {
        HStack(alignment: .top) {
          VStack(alignment: .leading, spacing: 8) {
            Text("Content")
              .font(.caption.weight(.semibold))
              .foregroundStyle(.secondary)
            Text(record.payload)
              .font(.body.weight(.semibold))
              .textSelection(.enabled)
          }
          Spacer()
          Button {
            UIPasteboard.general.string = record.payload
            Haptics.light(enabled: hapticsEnabled)
          } label: {
            Image(systemName: "doc.on.doc")
              .font(.system(size: 18, weight: .medium))
              .foregroundStyle(.blue)
          }
          .buttonStyle(.plain)
        }
      }

      HStack(spacing: 12) {
        secondaryPill(title: "Open", systemName: "arrow.up.right.circle.fill") {
          openPayload()
        }
        if record.kind == .phone, let url = URL(string: record.payload), url.scheme == "tel" {
          secondaryPill(title: "Call", systemName: "phone.fill") {
            UIApplication.shared.open(url)
          }
        }
      }

      HStack(spacing: 12) {
        secondaryPill(title: "Edit", systemName: "pencil") {
          showEdit = true
        }
        secondaryPill(title: "Share", systemName: "square.and.arrow.up") {
          if let img = model.image(for: record) {
            shareItems = [record.payload, img]
          } else {
            shareItems = [record.payload]
          }
          showShare = true
        }
      }

      Button(role: .destructive) {
        model.delete(record)
        dismiss()
      } label: {
        Text("Delete")
          .font(.body.weight(.semibold))
          .frame(maxWidth: .infinity)
          .padding(.vertical, 14)
          .background {
            RoundedRectangle(cornerRadius: LiquidGlass.cornerMedium, style: .continuous)
              .fill(Color.red.opacity(0.12))
          }
      }
      .buttonStyle(.plain)
      .padding(.top, 4)
    }
    .padding(16)
    .padding(.top, 8)
    .background {
      UnevenRoundedRectangle(
        cornerRadii: RectangleCornerRadii(
          topLeading: LiquidGlass.cornerLarge,
          bottomLeading: 0,
          bottomTrailing: 0,
          topTrailing: LiquidGlass.cornerLarge
        ),
        style: .continuous
      )
      .fill(Color(.systemGroupedBackground))
      .shadow(color: .black.opacity(0.06), radius: 16, y: -4)
    }
    .offset(y: -12)
  }

  private func secondaryPill(title: String, systemName: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      HStack(spacing: 8) {
        Image(systemName: systemName)
        Text(title)
          .font(.body.weight(.semibold))
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 14)
      .background {
        RoundedRectangle(cornerRadius: LiquidGlass.cornerMedium, style: .continuous)
          .fill(.ultraThinMaterial)
          .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
      }
    }
    .buttonStyle(.plain)
  }

  private func openPayload() {
    let p = record.payload.trimmingCharacters(in: .whitespacesAndNewlines)
    if p.lowercased().hasPrefix("http"), let u = URL(string: p) {
      UIApplication.shared.open(u)
      return
    }
    if p.lowercased().hasPrefix("tel:"), let u = URL(string: p) {
      UIApplication.shared.open(u)
      return
    }
    if p.lowercased().hasPrefix("mailto:"), let u = URL(string: p) {
      UIApplication.shared.open(u)
      return
    }
    if p.lowercased().hasPrefix("sms:"), let u = URL(string: p) {
      UIApplication.shared.open(u)
      return
    }
    if p.lowercased().hasPrefix("geo:") {
      let q = p.replacingOccurrences(of: "geo:", with: "").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
      if let u = URL(string: "https://maps.apple.com/?q=\(q)") {
        UIApplication.shared.open(u)
      }
      return
    }
    if let u = URL(string: p), u.scheme != nil {
      UIApplication.shared.open(u)
    }
  }
}
