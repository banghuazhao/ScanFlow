//
// Created by Banghua Zhao on 21/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

struct MainTabView: View {
  @AppStorage("scanflow.startWithCamera") private var startWithCamera = true
  @State private var tab: Int = 0
  @State private var scanModel = ScanViewModel()

  var body: some View {
    TabView(selection: $tab) {
      ScanView(model: scanModel)
        .tabItem { Label("Scan", systemImage: "viewfinder") }
        .tag(0)

      HistoryView()
        .tabItem { Label("History", systemImage: "clock") }
        .tag(1)

      CreateListView()
        .tabItem { Label("Create", systemImage: "qrcode") }
        .tag(2)

      SettingsView()
        .tabItem { Label("Settings", systemImage: "gearshape") }
        .tag(3)
    }
    .onAppear {
      if startWithCamera {
        tab = 0
      }
    }
  }
}
