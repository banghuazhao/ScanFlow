//
// Created by Banghua Zhao on 21/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
  @AppStorage("scanflow.startWithCamera") private var startWithCamera = true
  @AppStorage("scanflow.hapticsEnabled") private var hapticsEnabled = true
  @AppStorage("scanflow.usingInMemoryStore") private var usingInMemoryStore = false
  @State private var showDeleteScansConfirm = false
  @State private var showDeleteCreatedConfirm = false
  @State private var model = SettingsViewModel()

  var body: some View {
    NavigationStack {
      Form {
        if usingInMemoryStore {
          Section {
            Label {
              VStack(alignment: .leading, spacing: 4) {
                Text("Temporary storage")
                Text(
                  "The app could not use its normal on-device database (for example, very low storage). History and created codes may not persist after you quit. Free space or reinstall if this persists."
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
              }
            } icon: {
              Image(systemName: "exclamationmark.triangle.fill")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.orange)
            }
          }
        }
        Section {
          Toggle("Start on Scan tab", isOn: $startWithCamera)
          Toggle("Haptics", isOn: $hapticsEnabled)
        }
        Section {
          Button("Delete all scan history", role: .destructive) {
            showDeleteScansConfirm = true
          }
          Button("Delete all created codes", role: .destructive) {
            showDeleteCreatedConfirm = true
          }
        } footer: {
          Text("Each action only affects that list on this device. Scan history is shown in History; created codes are in Create.")
        }
      }
      .scrollContentBackground(.hidden)
      .scanflowScreenBackground()
      .navigationTitle("Settings")
      .confirmationDialog(
        "Delete all scan history?",
        isPresented: $showDeleteScansConfirm,
        titleVisibility: .visible
      ) {
        Button("Delete scan history", role: .destructive) {
          model.deleteAllScanRecords()
        }
        Button("Cancel", role: .cancel) {}
      } message: {
        Text("This removes every item in History. It cannot be undone.")
      }
      .confirmationDialog(
        "Delete all created codes?",
        isPresented: $showDeleteCreatedConfirm,
        titleVisibility: .visible
      ) {
        Button("Delete created codes", role: .destructive) {
          model.deleteAllCreatedCodes()
        }
        Button("Cancel", role: .cancel) {}
      } message: {
        Text("This removes every code you created. It cannot be undone.")
      }
    }
  }
}
