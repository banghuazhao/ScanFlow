//
// Created by Banghua Zhao on 21/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import AVFoundation
import SwiftUI
import UIKit

struct BarcodeScannerView: UIViewRepresentable {
  /// Stops the capture session while a result sheet is shown or a photo is being decoded (avoids overlapping work and stray scans).
  var isSessionPaused: Bool
  var onScan: (String, AVMetadataObject.ObjectType) -> Void

  func makeCoordinator() -> Coordinator {
    Coordinator(onScan: onScan)
  }

  func makeUIView(context: Context) -> ScannerPreviewView {
    let v = ScannerPreviewView()
    context.coordinator.previewView = v
    context.coordinator.onScan = onScan
    context.coordinator.sessionQueue.async {
      context.coordinator.configure(preview: v)
    }
    return v
  }

  func updateUIView(_ uiView: ScannerPreviewView, context: Context) {
    context.coordinator.onScan = onScan
    let paused = isSessionPaused
    context.coordinator.sessionQueue.async { [coordinator = context.coordinator] in
      coordinator.setSessionPaused(paused)
    }
  }

  final class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    let session = AVCaptureSession()
    let metadataOutput = AVCaptureMetadataOutput()
    let sessionQueue = DispatchQueue(label: "com.scanflow.camera.session")
    var previewView: ScannerPreviewView?
    var onScan: (String, AVMetadataObject.ObjectType) -> Void
    var isSessionPaused: Bool = false

    init(onScan: @escaping (String, AVMetadataObject.ObjectType) -> Void) {
      self.onScan = onScan
    }

    deinit {
      sessionQueue.async { [session] in
        session.stopRunning()
      }
    }

    /// Call only from `sessionQueue`. Session setup runs here; preview layer is bound on the main thread.
    func configure(preview: ScannerPreviewView) {
      session.beginConfiguration()
      session.sessionPreset = .high

      guard
        let dev = Self.preferredBackCamera(),
        let input = try? AVCaptureDeviceInput(device: dev)
      else {
        session.commitConfiguration()
        return
      }

      if session.canAddInput(input) { session.addInput(input) }
      if session.canAddOutput(metadataOutput) {
        session.addOutput(metadataOutput)
        metadataOutput.setMetadataObjectsDelegate(self, queue: sessionQueue)
        let wanted: [AVMetadataObject.ObjectType] = [
          .qr,
          .aztec,
          .dataMatrix,
          .pdf417,
          .ean8,
          .ean13,
          .upce,
          .code128,
          .code39,
          .code93,
          .itf14,
          .interleaved2of5,
        ]
        metadataOutput.metadataObjectTypes = wanted.filter { metadataOutput.availableMetadataObjectTypes.contains($0) }
      }
      session.commitConfiguration()
      if isSessionPaused {
        // The result sheet is already up; do not start until `setSessionPaused(false)`.
      } else if !session.isRunning {
        session.startRunning()
      }
      let sessionRef = self.session
      DispatchQueue.main.async { [weak preview] in
        guard let preview else { return }
        preview.previewLayer.session = sessionRef
      }
    }

    /// Call only from `sessionQueue`. Pauses or resumes the session when the result sheet is presented or dismissed.
    func setSessionPaused(_ paused: Bool) {
      isSessionPaused = paused
      if paused {
        if session.isRunning { session.stopRunning() }
        return
      }
      guard !session.inputs.isEmpty else { return }
      if !session.isRunning { session.startRunning() }
    }

    private static func preferredBackCamera() -> AVCaptureDevice? {
      let deviceTypes: [AVCaptureDevice.DeviceType] = [
        .builtInWideAngleCamera,
        .builtInDualWideCamera,
        .builtInDualCamera,
        .builtInTripleCamera,
      ]
      let discovery = AVCaptureDevice.DiscoverySession(
        deviceTypes: deviceTypes,
        mediaType: .video,
        position: .back
      )
      return discovery.devices.first
    }

    func metadataOutput(
      _ output: AVCaptureMetadataOutput,
      didOutput metadataObjects: [AVMetadataObject],
      from connection: AVCaptureConnection
    ) {
      if isSessionPaused { return }
      guard let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
            let value = obj.stringValue
      else { return }
      let type = obj.type
      DispatchQueue.main.async { [onScan] in
        onScan(value, type)
      }
    }
  }
}

final class ScannerPreviewView: UIView {
  override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

  var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
  var session: AVCaptureSession? {
    get { previewLayer.session }
    set { previewLayer.session = newValue }
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    previewLayer.frame = bounds
    previewLayer.videoGravity = .resizeAspectFill
  }
}
