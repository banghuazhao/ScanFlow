//
// Created by Banghua Zhao on 21/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

private enum CreateRoute: Hashable {
  case codeDetail(CreatedCodeRecord)
}

struct CreateListView: View {
  @State private var model = CreateViewModel()
  @State private var path = NavigationPath()
  @State private var showEditor = false
  @State private var seedKind: CreatedCodeKind?
  @State private var seedSocialURL: String?

  var body: some View {
    NavigationStack(path: $path) {
      Group {
        if model.codes.isEmpty {
          ContentUnavailableView(
            "No codes yet",
            systemImage: "qrcode",
            description: Text("Tap + to create a code, then choose a type in the editor.")
          )
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
          List {
            ForEach(model.codes) { record in
              NavigationLink(value: CreateRoute.codeDetail(record)) {
                CreatedCodeGlassRow(record: record)
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
                model.delete(model.codes[index])
              }
            }
          }
          .listStyle(.plain)
          .scrollContentBackground(.hidden)
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .scanflowScreenBackground()
      .navigationTitle("Create")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          Button {
            seedKind = nil
            seedSocialURL = nil
            showEditor = true
          } label: {
            Image(systemName: "plus")
              .font(.system(size: 20, weight: .semibold))
          }
        }
      }
      .navigationDestination(for: CreateRoute.self) { route in
        switch route {
        case .codeDetail(let record):
          CreatedCodeDetailView(record: record, model: model)
        }
      }
      .sheet(isPresented: $showEditor) {
        NavigationStack {
          CreateCodeEditorView(
            model: model,
            mode: .new,
            seedKind: seedKind,
            seedSocialURL: seedSocialURL,
            onFinished: {
              showEditor = false
              seedKind = nil
              seedSocialURL = nil
            }
          )
        }
      }
    }
  }
}

private struct CreatedCodeGlassRow: View {
  let record: CreatedCodeRecord

  var body: some View {
    HStack(spacing: 14) {
      GradientIconBadge(systemName: record.kind == .barcode ? "barcode" : "qrcode", size: 44)
      VStack(alignment: .leading, spacing: 4) {
        Text(record.displayLabel)
          .font(.body.weight(.semibold))
          .lineLimit(1)
        Text(record.kind.title)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
      Spacer()
      Image(systemName: "chevron.right")
        .font(.caption.weight(.semibold))
        .foregroundStyle(.tertiary)
    }
    .padding(.vertical, 6)
  }
}
