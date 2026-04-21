//
// Created by Banghua Zhao on 21/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import AVFoundation
import SwiftUI
import UIKit

struct BarcodeScannerView: UIViewRepresentable {
  var isTorchOn: Bool
  var onScan: (String, AVMetadataObject.ObjectType) -> Void

  func makeCoordinator() -> Coordinator {
    Coordinator(onScan: onScan)
  }

  func makeUIView(context: Context) -> ScannerPreviewView {
    let v = ScannerPreviewView()
    v.previewLayer.session = context.coordinator.session
    context.coordinator.previewView = v
    context.coordinator.configure()
    context.coordinator.start()
    return v
  }

  func updateUIView(_ uiView: ScannerPreviewView, context: Context) {
    context.coordinator.setTorch(isTorchOn)
  }

  final class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    let session = AVCaptureSession()
    let metadataOutput = AVCaptureMetadataOutput()
    var previewView: ScannerPreviewView?
    var onScan: (String, AVMetadataObject.ObjectType) -> Void
    private var device: AVCaptureDevice?

    init(onScan: @escaping (String, AVMetadataObject.ObjectType) -> Void) {
      self.onScan = onScan
    }

    deinit {
      stop()
    }

    func configure() {
      session.beginConfiguration()
      session.sessionPreset = .high

      guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: device)
      else {
        session.commitConfiguration()
        return
      }
      self.device = device

      if session.canAddInput(input) { session.addInput(input) }
      if session.canAddOutput(metadataOutput) {
        session.addOutput(metadataOutput)
        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue(label: "scanflow.metadata"))
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
    }

    func start() {
      guard !session.isRunning else { return }
      DispatchQueue.global(qos: .userInitiated).async { [session] in
        session.startRunning()
      }
    }

    func stop() {
      guard session.isRunning else { return }
      DispatchQueue.global(qos: .userInitiated).async { [session] in
        session.stopRunning()
      }
    }

    func setTorch(_ on: Bool) {
      guard let device, device.hasTorch else { return }
      do {
        try device.lockForConfiguration()
        device.torchMode = on ? .on : .off
        device.unlockForConfiguration()
      } catch {}
    }

    func metadataOutput(
      _ output: AVCaptureMetadataOutput,
      didOutput metadataObjects: [AVMetadataObject],
      from connection: AVCaptureConnection
    ) {
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

  override func layoutSubviews() {
    super.layoutSubviews()
    previewLayer.frame = bounds
    previewLayer.videoGravity = .resizeAspectFill
  }
}
