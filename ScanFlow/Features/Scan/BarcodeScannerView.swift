//
// Created by Banghua Zhao on 21/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import AVFoundation
import SwiftUI
import UIKit

struct BarcodeScannerView: UIViewRepresentable {
    @Binding var isTorchOn: Bool
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
        // Keep the scan handler in sync; closure can change when parent re-renders.
        let coordinator = context.coordinator
        coordinator.onScan = onScan
        let on = isTorchOn
        coordinator.sessionQueue.async {
            coordinator.setTorch(on)
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
        private var sessionStartObserver: NSObjectProtocol?

        init(onScan: @escaping (String, AVMetadataObject.ObjectType) -> Void) {
            self.onScan = onScan
        }

        deinit {
            if let o = sessionStartObserver {
                NotificationCenter.default.removeObserver(o)
            }
            sessionQueue.async { [session] in
                session.stopRunning()
            }
        }

        /// Call only from `sessionQueue`. Session setup, start, and torch run here; the preview
        /// layer is bound on the main thread (UIKit layer access is main-only).
        func configure(preview: ScannerPreviewView) {
            session.beginConfiguration()
            session.sessionPreset = .high

            guard
                let dev = Self.preferredBackCameraForTorch(),
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
            DispatchQueue.main.async { [weak preview] in
                guard let preview else { return }
                preview.previewLayer.session = sessionRef
            }
            // Re-apply torch when the session actually starts; torch set too early is often ignored.
            sessionStartObserver = NotificationCenter.default.addObserver(
                forName: AVCaptureSession.didStartRunningNotification,
                object: session,
                queue: .main
            ) { [weak self] _ in
                guard let self else { return }
                self.sessionQueue.async { [weak self] in
                    guard let self else { return }
                    self.setTorch(self.torchOn)
                }
            }
            // Re-apply last requested torch (may have been set in `setTorch` before we were ready).
            setTorch(torchOn)
        }

        func setTorch(_ on: Bool) {
            let wantOn = on
            torchOn = wantOn
            guard sessionConfigured else { return }
            // Always use the same device the session is actually capturing from (avoids
            // torch no-ops on multi-lens + session-open edge cases).
            let dev = self.sessionVideoDevice() ?? self.device
            guard let dev, dev.hasTorch else { return }
            do {
                try dev.lockForConfiguration()
            } catch {
                return
            }
            defer { dev.unlockForConfiguration() }
            Self.applyTorch(wantOn, to: dev)
        }

        /// Device currently attached to the session (the one that must be torched while preview runs).
        private func sessionVideoDevice() -> AVCaptureDevice? {
            for case let i as AVCaptureDeviceInput in session.inputs where i.device.hasMediaType(.video) {
                return i.device
            }
            return nil
        }

        /// Picks a back video device that can drive the LED while recording (same as many stock apps try).
        private static func preferredBackCameraForTorch() -> AVCaptureDevice? {
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
            if let t = discovery.devices.first(where: { $0.hasTorch }) { return t }
            return discovery.devices.first
        }

        private static func applyTorch(_ on: Bool, to d: AVCaptureDevice) {
            if on {
                guard d.isTorchModeSupported(.on) else { return }
                // While a session is running, the level-based API with a valid max (not always 1.0)
                // is what reliably drives the LED on many iPhones; fixed 1.0 often throws.
                let cap = maxSupportedTorchLevel(for: d)
                do {
                    try d.setTorchModeOn(level: cap)
                } catch {
                    d.torchMode = .on
                }
            } else {
                if d.isTorchModeSupported(.off) { d.torchMode = .off }
            }
        }

        private static func maxSupportedTorchLevel(for d: AVCaptureDevice) -> Float {
            if let f = d.value(forKey: "maxAvailableTorchLevel") as? Float, f > 0 {
                return min(1, f)
            }
            if let f = d.value(forKey: "maxAvailableTorchLevel") as? Double, f > 0 {
                return min(1, Float(f))
            }
            return 1.0
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
