//
// Created by Banghua Zhao on 21/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI
import UIKit

struct ScanResultDetailView: View {
  var showDismissButton: Bool = true
  let symbology: String
  let rawValue: String
  let previewImage: UIImage?
  var onDismiss: () -> Void
  var onDelete: (() -> Void)? = nil

  @State private var showShare = false
  @State private var shareItems: [Any] = []

  var body: some View {
    List {
      Section {
        if let previewImage {
          Image(uiImage: previewImage)
            .resizable()
            .interpolation(.none)
            .scaledToFit()
            .frame(maxHeight: 220)
            .frame(maxWidth: .infinity)
        }
      }
      Section("Type") {
        Text(SymbologyDisplay.friendlyName(symbology))
      }
      Section("Value") {
        Text(rawValue)
          .textSelection(.enabled)
      }
      if ProductLookup.productSearchURL(for: rawValue) != nil {
        Section {
          if let url = ProductLookup.productSearchURL(for: rawValue) {
            Link("Find product", destination: url)
          }
        }
      }
      Section {
        Button("Open") {
          openValue()
        }
        Button("Copy") {
          UIPasteboard.general.string = rawValue
        }
        Button("Share…") {
          if let img = previewImage ?? synthesizedImage() {
            shareItems = [rawValue, img]
          } else {
            shareItems = [rawValue]
          }
          showShare = true
        }
      }
      if let onDelete {
        Section {
          Button("Delete", role: .destructive, action: onDelete)
        }
      }
    }
    .navigationTitle("Scan")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      if showDismissButton {
        ToolbarItem(placement: .cancellationAction) {
          Button("Done", action: onDismiss)
        }
      }
    }
    .sheet(isPresented: $showShare) {
      ShareSheet(items: shareItems)
    }
  }

  private func synthesizedImage() -> UIImage? {
    let style = CodeStyleConfiguration.default
    if symbology.localizedCaseInsensitiveContains("qr") {
      return QRBarcodeImageGenerator.qrUIImage(payload: rawValue, style: style, centerImage: nil)
    }
    return QRBarcodeImageGenerator.linearBarcodeUIImage(payload: rawValue, style: style)
  }

  private func openValue() {
    let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.lowercased().hasPrefix("http"), let u = URL(string: trimmed) {
      UIApplication.shared.open(u)
      return
    }
    if trimmed.lowercased().hasPrefix("tel:"), let u = URL(string: trimmed) {
      UIApplication.shared.open(u)
      return
    }
    if trimmed.lowercased().hasPrefix("mailto:"), let u = URL(string: trimmed) {
      UIApplication.shared.open(u)
      return
    }
    if trimmed.lowercased().hasPrefix("sms:"), let u = URL(string: trimmed) {
      UIApplication.shared.open(u)
      return
    }
    if trimmed.lowercased().hasPrefix("geo:") {
      let q = trimmed.replacingOccurrences(of: "geo:", with: "").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
      if let u = URL(string: "https://maps.apple.com/?q=\(q)") {
        UIApplication.shared.open(u)
      }
      return
    }
    if let u = URL(string: trimmed), u.scheme != nil {
      UIApplication.shared.open(u)
    }
  }
}

struct ShareSheet: UIViewControllerRepresentable {
  var items: [Any]

  func makeUIViewController(context: Context) -> UIActivityViewController {
    UIActivityViewController(activityItems: items, applicationActivities: nil)
  }

  func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
