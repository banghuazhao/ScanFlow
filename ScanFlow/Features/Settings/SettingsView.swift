//
// Created by Banghua Zhao on 21/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
  @AppStorage("scanflow.startWithCamera") private var startWithCamera = true
  @AppStorage("scanflow.hapticsEnabled") private var hapticsEnabled = true
  @State private var showDeleteConfirm = false
  @State private var model = SettingsViewModel()

  var body: some View {
    NavigationStack {
      Form {
        Section {
          Toggle("Start on Scan tab", isOn: $startWithCamera)
          Toggle("Haptics", isOn: $hapticsEnabled)
        }
        Section {
          Button("Delete all data", role: .destructive) {
            showDeleteConfirm = true
          }
        } footer: {
          Text("Removes scan history and created codes from this device.")
        }
      }
      .scrollContentBackground(.hidden)
      .scanflowScreenBackground()
      .navigationTitle("Settings")
      .confirmationDialog(
        "Delete all data?",
        isPresented: $showDeleteConfirm,
        titleVisibility: .visible
      ) {
        Button("Delete everything", role: .destructive) {
          model.deleteAllData()
        }
        Button("Cancel", role: .cancel) {}
      }
    }
  }
}
