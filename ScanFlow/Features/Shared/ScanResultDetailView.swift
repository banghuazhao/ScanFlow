//
// Created by Banghua Zhao on 21/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI
import UIKit

struct ScanResultDetailView: View {
    var showDismissButton: Bool = true
    let symbology: String
    let rawValue: String
    let previewImage: UIImage?
    var onDismiss: () -> Void
    var onDelete: (() -> Void)? = nil

    @AppStorage("scanflow.hapticsEnabled") private var hapticsEnabled = true
    @State private var showShare = false
    @State private var shareItems: [Any] = []
    @State private var showCopiedToast = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerSection
                contentSection
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Scan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showDismissButton {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: onDismiss) {
                        if #available(iOS 26.0, *) {
                            Image(systemName: "xmark")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.primary)
                                .frame(width: 34, height: 34)
                                .glassEffect(.regular, in: Circle())
                        } else {
                            Image(systemName: "xmark")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.primary)
                                .frame(width: 34, height: 34)
                        }
                    }
                }
            }
        }
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(isPresented: $showShare) {
            ShareSheet(items: shareItems)
        }
        .copiedToast(isPresented: $showCopiedToast)
    }

    private var headerSection: some View {
        VStack(spacing: 18) {
            Text(headerTitle)
                .font(.headline.weight(.bold))
                .foregroundStyle(.primary)
                .padding(.top, 4)

            Group {
                if let previewImage {
                    Image(uiImage: previewImage)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .padding(18)
                        .frame(maxWidth: 260, maxHeight: 260)
                        .background {
                            RoundedRectangle(cornerRadius: LiquidGlass.cornerMedium, style: .continuous)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
                        }
                } else {
                    if #available(iOS 26.0, *) {
                        Image(systemName: "qrcode")
                            .font(.system(size: 72))
                            .foregroundStyle(.secondary)
                            .frame(width: 200, height: 200)
                            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: LiquidGlass.cornerMedium, style: .continuous))
                    } else {
                        Image(systemName: "qrcode")
                            .font(.system(size: 72))
                            .foregroundStyle(.secondary)
                            .frame(width: 200, height: 200)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 28)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial)
    }

    private var headerTitle: String {
        let t = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.count > 28 { return String(t.prefix(25)) + "…" }
        return t.isEmpty ? "Scan" : t
    }

    private var isOpenable: Bool {
        OpenDestination.url(for: rawValue) != nil
    }

    private var symbologyLabel: String {
        SymbologyDisplay.friendlyName(symbology)
    }

    private var webSearchAction: ScanWebSearchAction? {
        ProductLookup.webSearchAction(raw: rawValue, symbology: symbology)
    }

    private var contentSection: some View {
        VStack(spacing: 16) {
            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Type")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(symbologyLabel)
                        .font(.body.weight(.medium))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            GlassCard {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Value")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(rawValue)
                            .font(.body.weight(.semibold))
                            .textSelection(.enabled)
                    }
                    Spacer()
                    Button {
                        copyToClipboard(rawValue)
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                }
            }

            if let action = webSearchAction {
                Link(destination: action.url) {
                    GlassCard(padding: 14) {
                        HStack {
                            Image(systemName: action.systemImage)
                                .foregroundStyle(.blue)
                            Text(action.title)
                                .font(.body.weight(.semibold))
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.tertiary)
                        }
                        .contentShape(.rect)
                    }
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 12) {
                if isOpenable {
                    actionPill(title: "Open", systemName: "arrow.up.right.circle.fill", role: nil) {
                        openValue()
                    }
                }
                actionPill(title: "Share", systemName: "square.and.arrow.up", role: nil) {
                    if let img = previewImage ?? synthesizedImage() {
                        shareItems = [rawValue, img]
                    } else {
                        shareItems = [rawValue]
                    }
                    showShare = true
                }
            }

            if let onDelete {
                Button(role: .destructive, action: onDelete) {
                    Text("Delete")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundStyle(.red)
                        .background {
                            if #available(iOS 26.0, *) {
                                RoundedRectangle(cornerRadius: LiquidGlass.cornerMedium, style: .continuous)
                                    .fill(.clear)
                                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: LiquidGlass.cornerMedium, style: .continuous))
                            } else {
                                RoundedRectangle(cornerRadius: LiquidGlass.cornerMedium, style: .continuous)
                                    .fill(.clear)
                            }
                        }
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
        .padding(16)
        .padding(.top, 8)
        .background {
            UnevenRoundedRectangle(
                cornerRadii: RectangleCornerRadii(
                    topLeading: LiquidGlass.cornerLarge,
                    bottomLeading: 0,
                    bottomTrailing: 0,
                    topTrailing: LiquidGlass.cornerLarge
                ),
                style: .continuous
            )
            .fill(Color(.systemGroupedBackground))
            .shadow(color: .black.opacity(0.06), radius: 16, y: -4)
        }
        .offset(y: -12)
    }

    private func actionPill(title: String, systemName: String, role: ButtonRole?, action: @escaping () -> Void) -> some View {
        Button(role: role, action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemName)
                Text(title)
                    .font(.body.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background {
                if #available(iOS 26.0, *) {
                    RoundedRectangle(cornerRadius: LiquidGlass.cornerMedium, style: .continuous)
                        .fill(.clear)
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: LiquidGlass.cornerMedium, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: LiquidGlass.cornerMedium, style: .continuous)
                        .fill(.clear)
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    private func synthesizedImage() -> UIImage? {
        let style = CodeStyleConfiguration.default
        if symbology.localizedCaseInsensitiveContains("qr") {
            return QRBarcodeImageGenerator.qrUIImage(payload: rawValue, style: style, centerImage: nil)
        }
        return QRBarcodeImageGenerator.linearBarcodeUIImage(payload: rawValue, style: style)
    }

    private func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
        Haptics.light(enabled: hapticsEnabled)
        showCopiedToast = true
    }

    private func openValue() {
        guard let u = OpenDestination.url(for: rawValue) else { return }
        UIApplication.shared.open(u)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
