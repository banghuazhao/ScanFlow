//
// Created by Banghua Zhao on 21/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import AVFoundation
import PhotosUI
import SwiftUI
import UIKit

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
        .scanflowScreenBackground()
      } else {
        BarcodeScannerView(isTorchOn: model.isTorchOn) { value, type in
          model.handleScan(value: value, avType: type, hapticsEnabled: hapticsEnabled)
        }
        .ignoresSafeArea()

        ScanViewfinderOverlay()

        VStack(spacing: 0) {
          HStack(spacing: 16) {
            GlassCircleButton(
              systemName: model.isTorchOn ? "flashlight.on.fill" : "flashlight.off.fill",
              isActive: model.isTorchOn
            ) {
              model.isTorchOn.toggle()
              Haptics.light(enabled: hapticsEnabled)
            }

            Spacer()

            PhotosPicker(selection: $photoItem, matching: .images, photoLibrary: .shared()) {
              Image(systemName: "photo.on.rectangle")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .glassEffect(.regular.interactive(), in: Circle())
            }
            .buttonStyle(.plain)
          }
          .padding(.horizontal, 20)
          .padding(.top, 12)

          Text("Scanner")
            .font(.system(size: 34, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.35), radius: 6, y: 2)
            .padding(.top, 4)

          Spacer(minLength: 0)

          Text("Scan a QR code or barcode")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white.opacity(0.92))
            .shadow(color: .black.opacity(0.25), radius: 4, y: 1)
            .padding(.bottom, 12)

          Spacer(minLength: 120)
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
            onDismiss: { model.clearDetail() },
            onDelete: { model.deleteLastScannedIfPresented() }
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
