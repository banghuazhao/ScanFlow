//
// Created by Banghua Zhao on 21/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import PhotosUI
import SwiftUI
import UIKit

struct ScanView: View {
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.openURL) private var openURL
  @Bindable var model: ScanViewModel
  @AppStorage("scanflow.hapticsEnabled") private var hapticsEnabled = true
  @State private var photoItem: PhotosPickerItem?
  @State private var photoLoadError = false
  @State private var isDecodingPhoto = false

  var body: some View {
    ZStack {
      if shouldShowCameraDeniedPlaceholder {
        ContentUnavailableView {
          Label(cameraDeniedTitle, systemImage: "camera.fill")
        } description: {
          cameraDeniedDescription
        } actions: {
          VStack(spacing: 12) {
            if model.cameraAccess == .denied, let url = URL(string: UIApplication.openSettingsURLString) {
              Button("Open Settings") {
                openURL(url)
              }
              .buttonStyle(.borderedProminent)
            }
            PhotosPicker(selection: $photoItem, matching: .images, photoLibrary: .shared()) {
              Label("Scan a photo from your library", systemImage: "photo.on.rectangle")
                .frame(maxWidth: .infinity, alignment: .center)
                .contentShape(.rect)
            }
            .buttonStyle(.bordered)
          }
        }
        .scanflowScreenBackground()
      } else {
        BarcodeScannerView(isSessionPaused: model.scanDetailPresented || isDecodingPhoto) { value, type in
          model.handleScan(value: value, avType: type, hapticsEnabled: hapticsEnabled)
        }
        .id(model.cameraScannerViewID)
        .ignoresSafeArea()

        ScanViewfinderOverlay()

        VStack(spacing: 0) {
          HStack(spacing: 16) {
            Spacer()

            PhotosPicker(selection: $photoItem, matching: .images, photoLibrary: .shared()) {
              Image(systemName: "photo.on.rectangle")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .frame(minWidth: 48, minHeight: 48)
                .contentShape(Circle())
                .glassEffect(.regular.interactive(), in: Circle())
            }
            // `.plain` with `glassEffect` can eat the first touch on some iOS versions; `borderless` is more reliable.
            .buttonStyle(.borderless)
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

        if isDecodingPhoto {
          Color.black.opacity(0.4)
            .ignoresSafeArea()
            .allowsHitTesting(true)
          VStack(spacing: 14) {
            ProgressView()
              .tint(.white)
              .controlSize(.large)
            Text("Reading photo…")
              .font(.subheadline.weight(.semibold))
              .foregroundStyle(.white)
          }
          .accessibilityElement(children: .combine)
          .accessibilityLabel("Reading photo")
        }
      }
    }
    .onAppear { model.checkCameraAuthorization() }
    .onChange(of: scenePhase) { _, phase in
      if phase == .active {
        model.checkCameraAuthorization()
      }
    }
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

  private var shouldShowCameraDeniedPlaceholder: Bool {
    model.cameraAccess == .denied || model.cameraAccess == .restricted
  }

  private var cameraDeniedTitle: String {
    switch model.cameraAccess {
    case .denied:
      "Camera off"
    case .restricted:
      "Camera restricted"
    default:
      "Camera unavailable"
    }
  }

  private var cameraDeniedDescription: Text {
    switch model.cameraAccess {
    case .denied:
      Text("To scan with the camera, allow access for ScanFlow in Settings. You can still scan codes from a photo in your library.")
    case .restricted:
      Text("This device or profile does not allow camera use (for example Screen Time or device management). You can still try scanning a code from a photo in your library.")
    default:
      Text("Camera is not available.")
    }
  }

  private func loadPhoto(item: PhotosPickerItem) async {
    await MainActor.run { isDecodingPhoto = true }
    defer {
      Task { @MainActor in
        isDecodingPhoto = false
      }
    }
    do {
      guard let data = try await item.loadTransferable(type: Data.self),
            let image = UIImage(data: data)
      else {
        await MainActor.run { photoItem = nil }
        return
      }
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
