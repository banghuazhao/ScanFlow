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

  @State private var showShare = false
  @State private var shareItems: [Any] = []
  @State private var showEdit = false

  var body: some View {
    List {
      Section {
        if let ui = model.image(for: record) {
          Image(uiImage: ui)
            .resizable()
            .interpolation(.none)
            .scaledToFit()
            .frame(maxHeight: 260)
            .frame(maxWidth: .infinity)
        }
      }
      Section("Kind") {
        Text(record.kind.title)
      }
      Section("Content") {
        Text(record.payload)
          .textSelection(.enabled)
      }
      Section {
        Button("Open") { openPayload() }
        Button("Share…") {
          if let img = model.image(for: record) {
            shareItems = [record.payload, img]
          } else {
            shareItems = [record.payload]
          }
          showShare = true
        }
        if record.kind == .phone, let url = URL(string: record.payload), url.scheme == "tel" {
          Button("Call") {
            UIApplication.shared.open(url)
          }
        }
        Button("Edit") {
          showEdit = true
        }
        Button("Delete", role: .destructive) {
          model.delete(record)
          dismiss()
        }
      }
    }
    .navigationTitle("Code")
    .navigationBarTitleDisplayMode(.inline)
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
