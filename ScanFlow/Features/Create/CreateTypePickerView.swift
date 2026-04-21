//
// Created by Banghua Zhao on 21/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

private struct SocialBrand: Identifiable {
  var id: String { title }
  let title: String
  let tint: Color
  let seedURL: String
}

/// Shown after tapping + on Create: choose what kind of code to build.
struct CreateTypePickerView: View {
  @Environment(\.dismiss) private var dismiss
  let onPick: (CreatedCodeKind?, String?) -> Void

  private let socialBrands: [SocialBrand] = [
    SocialBrand(title: "Facebook", tint: Color(red: 0.26, green: 0.41, blue: 0.88), seedURL: "https://facebook.com/"),
    SocialBrand(title: "Instagram", tint: Color(red: 0.9, green: 0.3, blue: 0.55), seedURL: "https://instagram.com/"),
    SocialBrand(title: "Threads", tint: .primary, seedURL: "https://threads.net/@"),
    SocialBrand(title: "TikTok", tint: .primary, seedURL: "https://tiktok.com/@"),
  ]

  private let personalItems: [(CreatedCodeKind, String, String)] = [
    (.phone, "Phone", "phone.fill"),
    (.web, "Web link", "link"),
    (.email, "Email", "envelope.fill"),
    (.message, "Message", "message.fill"),
    (.contact, "Contact", "person.crop.circle.fill"),
    (.calendar, "Calendar", "calendar"),
  ]

  private let utilityItems: [(CreatedCodeKind, String, String, Color)] = [
    (.wifi, "Wi‑Fi", "wifi", .green),
    (.text, "Text", "doc.text.fill", .orange),
    (.location, "Location", "location.fill", .pink),
    (.barcode, "Barcode", "barcode", .purple),
  ]

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 28) {
        sectionHeader("Personal")
        LazyVGrid(
          columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
          ],
          spacing: 14
        ) {
          ForEach(personalItems, id: \.0) { item in
            personalTile(kind: item.0, title: item.1, systemName: item.2)
          }
        }

        sectionHeader("Utilities")
        GlassCard(padding: 0) {
          VStack(spacing: 0) {
            ForEach(Array(utilityItems.enumerated()), id: \.element.0) { index, item in
              Button {
                pick(kind: item.0, social: nil)
              } label: {
                HStack(spacing: 14) {
                  RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(item.3.opacity(0.18))
                    .frame(width: 40, height: 40)
                    .overlay {
                      Image(systemName: item.2)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(item.3)
                    }
                  Text(item.1)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                  Spacer()
                  Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
              }
              .buttonStyle(.plain)
              if index < utilityItems.count - 1 {
                Divider()
                  .padding(.leading, 70)
              }
            }
          }
        }

        sectionHeader("Social media")
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 12) {
            ForEach(socialBrands) { brand in
              Button {
                pick(kind: .social, social: brand.seedURL)
              } label: {
                VStack(spacing: 8) {
                  RoundedRectangle(cornerRadius: LiquidGlass.cornerSmall, style: .continuous)
                    .fill(brand.tint.opacity(0.12))
                    .frame(width: 64, height: 64)
                    .overlay {
                      Text(String(brand.title.prefix(1)))
                        .font(.title2.weight(.bold))
                        .foregroundStyle(brand.tint)
                    }
                  Text(brand.title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                }
                .frame(width: 76)
              }
              .buttonStyle(.plain)
            }
          }
          .padding(.horizontal, 2)
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
    }
    .scanflowScreenBackground()
    .navigationTitle("New code")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button("Close") {
          dismiss()
        }
      }
    }
  }

  private func sectionHeader(_ title: String) -> some View {
    Text(title)
      .font(.title3.weight(.bold))
      .foregroundStyle(.primary)
  }

  private func personalTile(kind: CreatedCodeKind, title: String, systemName: String) -> some View {
    Button {
      pick(kind: kind, social: nil)
    } label: {
      VStack(spacing: 10) {
        RoundedRectangle(cornerRadius: LiquidGlass.cornerMedium, style: .continuous)
          .fill(.ultraThinMaterial)
          .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
          .frame(height: 72)
          .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
              .fill(Color.blue.opacity(0.2))
              .frame(width: 44, height: 44)
              .overlay {
                Image(systemName: systemName)
                  .font(.system(size: 20, weight: .semibold))
                  .foregroundStyle(.blue)
              }
          }
        Text(title)
          .font(.caption.weight(.medium))
          .foregroundStyle(.primary)
          .multilineTextAlignment(.center)
          .lineLimit(2)
          .minimumScaleFactor(0.85)
      }
      .frame(maxWidth: .infinity)
    }
    .buttonStyle(.plain)
  }

  private func pick(kind: CreatedCodeKind?, social: String?) {
    onPick(kind, social)
  }
}
