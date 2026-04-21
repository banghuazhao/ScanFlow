//
// Created by Banghua Zhao on 21/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

struct CreateListView: View {
  @State private var model = CreateViewModel()
  @State private var showEditor = false

  var body: some View {
    NavigationStack {
      Group {
        if model.codes.isEmpty {
          ContentUnavailableView(
            "No codes yet",
            systemImage: "qrcode",
            description: Text("Tap + to create a QR code or barcode.")
          )
        } else {
          List {
            ForEach(model.codes) { record in
              NavigationLink(value: record) {
                CreatedCodeRow(record: record)
              }
            }
            .onDelete { indexSet in
              for index in indexSet {
                model.delete(model.codes[index])
              }
            }
          }
        }
      }
      .navigationTitle("Create")
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          Button {
            showEditor = true
          } label: {
            Image(systemName: "plus")
          }
        }
      }
      .navigationDestination(for: CreatedCodeRecord.self) { record in
        CreatedCodeDetailView(record: record, model: model)
      }
      .sheet(isPresented: $showEditor) {
        NavigationStack {
          CreateCodeEditorView(
            model: model,
            mode: .new,
            onFinished: { showEditor = false }
          )
        }
      }
    }
  }
}

private struct CreatedCodeRow: View {
  let record: CreatedCodeRecord

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: record.kind == .barcode ? "barcode" : "qrcode")
        .foregroundStyle(.secondary)
        .frame(width: 32, height: 32)
      VStack(alignment: .leading, spacing: 4) {
        Text(record.displayLabel)
          .lineLimit(1)
        Text(record.kind.title)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
  }
}
