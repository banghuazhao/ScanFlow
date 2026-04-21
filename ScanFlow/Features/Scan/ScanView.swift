//
// Created by Banghua Zhao on 21/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import AVFoundation
import PhotosUI
import SwiftUI

struct ScanView: View {
  @Bindable var model: ScanViewModel
  @AppStorage("scanflow.hapticsEnabled") private var hapticsEnabled = true
  @State private var photoItem: PhotosPickerItem?
  @State private var photoLoadError = false

  var body: some View {
    ZStack {
      if model.cameraDenied {
        ContentUnavailableView(
          "Camera unavailable",
          systemImage: "camera.fill",
          description: Text("Allow camera access in Settings to scan codes.")
        )
      } else {
        BarcodeScannerView(isTorchOn: model.isTorchOn) { value, type in
          model.handleScan(value: value, avType: type, hapticsEnabled: hapticsEnabled)
        }
        .ignoresSafeArea()

        VStack {
          HStack {
            Spacer()
            PhotosPicker(selection: $photoItem, matching: .images, photoLibrary: .shared()) {
              Label("Import", systemImage: "photo.on.rectangle")
                .padding(10)
                .background(.ultraThinMaterial, in: Capsule())
            }
            Button {
              model.isTorchOn.toggle()
            } label: {
              Image(systemName: model.isTorchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                .padding(10)
                .background(.ultraThinMaterial, in: Circle())
            }
          }
          .padding()
          Spacer()
        }
      }
    }
    .onAppear { model.checkCameraAuthorization() }
    .onChange(of: photoItem) { _, new in
      guard let new else { return }
      Task {
        await loadPhoto(item: new)
      }
    }
    .alert("Could not read code", isPresented: $photoLoadError) {
      Button("OK", role: .cancel) {}
    }
    .sheet(isPresented: $model.scanDetailPresented) {
      if let v = model.lastScannedValue, let s = model.lastSymbology {
        NavigationStack {
          ScanResultDetailView(
            symbology: s,
            rawValue: v,
            previewImage: model.lastPreviewImage,
            onDismiss: { model.clearDetail() }
          )
        }
      }
    }
  }

  private func loadPhoto(item: PhotosPickerItem) async {
    do {
      guard let data = try await item.loadTransferable(type: Data.self),
            let image = UIImage(data: data)
      else { return }
      let results = try await BarcodePhotoDecoder.decode(image: image)
      await MainActor.run {
        if results.isEmpty {
          photoLoadError = true
        } else {
          model.handlePhotoScan(results: results, hapticsEnabled: hapticsEnabled)
        }
        photoItem = nil
      }
    } catch {
      await MainActor.run {
        photoLoadError = true
        photoItem = nil
      }
    }
  }
}
