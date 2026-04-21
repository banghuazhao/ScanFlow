//
// Created by Banghua Zhao on 21/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

struct HistoryView: View {
  @State private var model = HistoryViewModel()
  @State private var search = ""

  private var filtered: [ScanRecord] {
    let q = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    guard !q.isEmpty else { return model.scans }
    return model.scans.filter {
      $0.rawValue.lowercased().contains(q)
        || $0.symbology.lowercased().contains(q)
        || ($0.title?.lowercased().contains(q) ?? false)
    }
  }

  var body: some View {
    NavigationStack {
      Group {
        if model.scans.isEmpty {
          ContentUnavailableView("No scans yet", systemImage: "clock", description: Text("Codes you scan appear here."))
        } else {
          List {
            ForEach(filtered) { record in
              NavigationLink(value: record) {
                HistoryRow(record: record)
              }
            }
            .onDelete { indexSet in
              for index in indexSet {
                model.delete(filtered[index])
              }
            }
          }
          .searchable(text: $search, prompt: "Search scans")
        }
      }
      .navigationTitle("History")
      .navigationDestination(for: ScanRecord.self) { record in
        HistoryRecordDetail(record: record, model: model)
      }
    }
  }
}

private struct HistoryRecordDetail: View {
  @Environment(\.dismiss) private var dismiss
  let record: ScanRecord
  let model: HistoryViewModel

  var body: some View {
    ScanResultDetailView(
      showDismissButton: false,
      symbology: record.symbology,
      rawValue: record.rawValue,
      previewImage: record.snapshotData.flatMap { UIImage(data: $0) },
      onDismiss: {},
      onDelete: {
        model.delete(record)
        dismiss()
      }
    )
  }
}

private struct HistoryRow: View {
  let record: ScanRecord

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: SymbologyDisplay.iconName(record.symbology))
        .font(.title2)
        .foregroundStyle(.secondary)
        .frame(width: 36, height: 36)
      VStack(alignment: .leading, spacing: 4) {
        Text(record.title ?? record.rawValue)
          .lineLimit(1)
        Text(SymbologyDisplay.friendlyName(record.symbology))
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
  }
}
