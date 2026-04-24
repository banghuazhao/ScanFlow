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
        context.coordinator.previewView = v
        context.coordinator.sessionQueue.async {
            context.coordinator.configure(preview: v)
        }
        return v
    }

    func updateUIView(_ uiView: ScannerPreviewView, context: Context) {
        let on = isTorchOn
        context.coordinator.sessionQueue.async {
            context.coordinator.setTorch(on)
        }
    }

    final class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        let session = AVCaptureSession()
        let metadataOutput = AVCaptureMetadataOutput()
        let sessionQueue = DispatchQueue(label: "com.scanflow.camera.session")
        var previewView: ScannerPreviewView?
        var onScan: (String, AVMetadataObject.ObjectType) -> Void
        var device: AVCaptureDevice?
        var torchOn = false
        var sessionConfigured = false

        init(onScan: @escaping (String, AVMetadataObject.ObjectType) -> Void) {
            self.onScan = onScan
        }

        deinit {
            sessionQueue.async { [session] in
                session.stopRunning()
            }
        }

        /// Call only from `sessionQueue`. Session setup, start, and torch run here; the preview
        /// layer is bound on the main thread (UIKit layer access is main-only).
        func configure(preview: ScannerPreviewView) {
            session.beginConfiguration()
            session.sessionPreset = .high

            guard let dev = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let input = try? AVCaptureDeviceInput(device: dev)
            else {
                session.commitConfiguration()
                return
            }
            device = dev

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
            if !session.isRunning {
                session.startRunning()
            }
            sessionConfigured = true
            // `UIView.layer` / `AVCaptureVideoPreviewLayer` must be touched on the main thread.
            let sessionRef = self.session
            DispatchQueue.main.async { [weak self, weak preview] in
                guard let self, let preview else { return }
                preview.previewLayer.session = sessionRef
                self.sessionQueue.async { self.setTorch(self.torchOn) }
            }
        }

        func setTorch(_ on: Bool) {
            torchOn = on
            guard sessionConfigured, let device, device.hasTorch else { return }
            do {
                try device.lockForConfiguration()
                if on {
                    if device.isTorchModeSupported(.on) {
                        try device.setTorchModeOn(level: 1.0)
                    }
                } else if device.isTorchModeSupported(.off) {
                    device.torchMode = .off
                }
                device.unlockForConfiguration()
            } catch {
                do {
                    try device.lockForConfiguration()
                    if on, device.isTorchModeSupported(.on) {
                        device.torchMode = .on
                    } else {
                        device.torchMode = .off
                    }
                    device.unlockForConfiguration()
                } catch {}
            }
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
