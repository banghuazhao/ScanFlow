//
// Created by Banghua Zhao on 21/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI
import UIKit

private enum HistorySort: String, CaseIterable {
  case newest
  case oldest
  case alphabetical

  var title: String {
    switch self {
    case .newest: "Newest first"
    case .oldest: "Oldest first"
    case .alphabetical: "A to Z"
    }
  }
}

struct HistoryView: View {
  @State private var model = HistoryViewModel()
  @State private var search = ""
  @State private var sort: HistorySort = .newest

  private var filtered: [ScanRecord] {
    let q = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    guard !q.isEmpty else { return model.scans }
    return model.scans.filter {
      $0.rawValue.lowercased().contains(q)
        || $0.symbology.lowercased().contains(q)
        || ($0.title?.lowercased().contains(q) ?? false)
    }
  }

  private var displayed: [ScanRecord] {
    var base = filtered
    switch sort {
    case .newest:
      base.sort { $0.createdAt > $1.createdAt }
    case .oldest:
      base.sort { $0.createdAt < $1.createdAt }
    case .alphabetical:
      base.sort {
        ($0.title ?? $0.rawValue).localizedCaseInsensitiveCompare($1.title ?? $1.rawValue) == .orderedAscending
      }
    }
    return base
  }

  var body: some View {
    NavigationStack {
      Group {
        if model.scans.isEmpty {
          ContentUnavailableView(
            "No scans yet",
            systemImage: "clock",
            description: Text("Codes you scan appear here.")
          )
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
          List {
            ForEach(displayed) { record in
              NavigationLink(value: record) {
                HistoryGlassRow(record: record)
              }
              .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
              .listRowSeparator(.hidden)
              .listRowBackground(
                RoundedRectangle(cornerRadius: LiquidGlass.cornerMedium, style: .continuous)
                  .fill(.clear)
                  .glassEffect(.regular, in: RoundedRectangle(cornerRadius: LiquidGlass.cornerMedium, style: .continuous))
                  .padding(.vertical, 4)
              )
            }
            .onDelete { indexSet in
              for index in indexSet {
                model.delete(displayed[index])
              }
            }
          }
          .listStyle(.plain)
          .scrollContentBackground(.hidden)
          .searchable(text: $search, prompt: "Search codes…")
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .scanflowScreenBackground()
      .navigationTitle("History")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Menu {
            Picker("Sort", selection: $sort) {
              ForEach(HistorySort.allCases, id: \.self) { option in
                Text(option.title).tag(option)
              }
            }
          } label: {
            Image(systemName: "arrow.up.arrow.down.circle")
              .font(.system(size: 20, weight: .medium))
              .symbolRenderingMode(.hierarchical)
          }
        }
      }
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

private struct HistoryGlassRow: View {
  let record: ScanRecord

  var body: some View {
    HStack(spacing: 14) {
      GradientIconBadge(systemName: SymbologyDisplay.iconName(record.symbology), size: 48)
      VStack(alignment: .leading, spacing: 4) {
        Text(record.title ?? record.rawValue)
          .font(.body.weight(.semibold))
          .foregroundStyle(.primary)
          .lineLimit(1)
        Text(SymbologyDisplay.friendlyName(record.symbology))
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
      Spacer(minLength: 8)
      Image(systemName: "ellipsis.circle")
        .font(.system(size: 22))
        .foregroundStyle(.tertiary)
    }
    .padding(.vertical, 6)
  }
}
