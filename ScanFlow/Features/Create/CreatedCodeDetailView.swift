//
// Created by Banghua Zhao on 21/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Photos
import SwiftUI
import UIKit

struct CreatedCodeDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let record: CreatedCodeRecord
    let model: CreateViewModel

    @AppStorage("scanflow.hapticsEnabled") private var hapticsEnabled = true
    @State private var showEdit = false
    @State private var showCopiedToast = false
    @State private var isSavingToPhotos = false
    @State private var showSavedToast = false
    @State private var showPhotoAccessDenied = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerSection
                contentSection
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Code")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(isPresented: $showEdit) {
            NavigationStack {
                CreateCodeEditorView(
                    model: model,
                    mode: .edit(record),
                    onFinished: { showEdit = false }
                )
            }
        }
        .copiedToast(isPresented: $showCopiedToast)
        .copiedToast("Saved to Photos", isPresented: $showSavedToast)
        .alert("Photos Access", isPresented: $showPhotoAccessDenied) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Allow access in Settings to save your code image to the library.")
        }
    }

    private var isOpenable: Bool {
        OpenDestination.url(for: record.payload) != nil
    }

    private var headerSection: some View {
        VStack(spacing: 18) {
            Text(record.displayLabel)
                .font(.headline.weight(.bold))
                .foregroundStyle(.primary)
                .lineLimit(1)

            if let ui = model.image(for: record) {
                Image(uiImage: ui)
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
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 28)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial)
    }

    private var contentSection: some View {
        VStack(spacing: 16) {
            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Kind")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(record.kind.title)
                        .font(.body.weight(.medium))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            GlassCard {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Content")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(record.payload)
                            .font(.body.weight(.semibold))
                            .textSelection(.enabled)
                    }
                    Spacer()
                    Button {
                        UIPasteboard.general.string = record.payload
                        Haptics.light(enabled: hapticsEnabled)
                        showCopiedToast = true
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 12) {
                if isOpenable {
                    secondaryPill(title: "Open", systemName: "arrow.up.right.circle.fill") {
                        openPayload()
                    }
                }
                if record.kind == .phone, let url = URL(string: record.payload), url.scheme == "tel" {
                    secondaryPill(title: "Call", systemName: "phone.fill") {
                        UIApplication.shared.open(url)
                    }
                }
            }

            HStack(spacing: 12) {
                secondaryPill(title: "Edit", systemName: "pencil") {
                    showEdit = true
                }
                secondaryPill(
                    title: "Save to Photos",
                    systemName: "photo.badge.arrow.down",
                    isLoading: isSavingToPhotos
                ) {
                    Task { await saveCodeImageToPhotoLibrary() }
                }
            }

            Button(role: .destructive) {
                model.delete(record)
                dismiss()
            } label: {
                Text("Delete")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundStyle(.red)
                    .background {
                        RoundedRectangle(cornerRadius: LiquidGlass.cornerMedium, style: .continuous)
                            .fill(.clear)
                            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: LiquidGlass.cornerMedium, style: .continuous))
                    }
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
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

    private func secondaryPill(
        title: String,
        systemName: String,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                } else {
                    Image(systemName: systemName)
                }
                Text(title)
                    .font(.body.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background {
                RoundedRectangle(cornerRadius: LiquidGlass.cornerMedium, style: .continuous)
                    .fill(.clear)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: LiquidGlass.cornerMedium, style: .continuous))
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }

    @MainActor
    private func saveCodeImageToPhotoLibrary() async {
        guard !isSavingToPhotos else { return }
        isSavingToPhotos = true
        await Task.yield()
        let image = model.image(for: record)
        guard let image else {
            isSavingToPhotos = false
            return
        }

        var status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        if status == .notDetermined {
            status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        }
        guard status == .authorized else {
            isSavingToPhotos = false
            if status == .denied || status == .restricted {
                showPhotoAccessDenied = true
            }
            return
        }

        let saved = await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, _ in
                cont.resume(returning: success)
            }
        }
        isSavingToPhotos = false
        if saved {
            Haptics.light(enabled: hapticsEnabled)
            showSavedToast = true
        }
    }

    private func openPayload() {
        guard let u = OpenDestination.url(for: record.payload) else { return }
        UIApplication.shared.open(u)
    }
}
