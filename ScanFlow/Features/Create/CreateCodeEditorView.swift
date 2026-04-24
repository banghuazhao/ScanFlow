//
// Created by Banghua Zhao on 21/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import PhotosUI
import SwiftUI
import UIKit

enum CreateEditorMode {
    case new
    case edit(CreatedCodeRecord)
}

struct CreateCodeEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let model: CreateViewModel
    let mode: CreateEditorMode
    /// Pre-select kind when creating from the hub (ignored for edit).
    var seedKind: CreatedCodeKind? = nil
    /// Pre-fill social URL for branded shortcuts from the hub.
    var seedSocialURL: String? = nil
    let onFinished: () -> Void

    @State private var kind: CreatedCodeKind = .text
    @State private var phone = ""
    @State private var web = ""
    @State private var emailAddress = ""
    @State private var emailSubject = ""
    @State private var emailBody = ""
    @State private var smsNumber = ""
    @State private var smsBody = ""
    @State private var contactName = ""
    @State private var contactPhone = ""
    @State private var contactEmail = ""
    @State private var eventTitle = ""
    @State private var eventLocation = ""
    @State private var eventStart = Date()
    @State private var eventEnd = Date().addingTimeInterval(3600)
    @State private var wifiSSID = ""
    @State private var wifiPassword = ""
    @State private var wifiSecurity = "WPA"
    @State private var plainText = ""
    @State private var latitude = ""
    @State private var longitude = ""
    @State private var barcodeText = ""
    @State private var socialURL = ""

    @State private var style = CodeStyleConfiguration.default
    @State private var foregroundColor = Color.black
    @State private var backgroundColor = Color.white
    @State private var centerPhotoItem: PhotosPickerItem?
    @State private var centerImageData: Data?
    @State private var showTypePicker = false

    var body: some View {
        Form {
            Section {
                if isEdit {
                    HStack {
                        Text("Kind")
                        Spacer()
                        Text(kind.title)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Button {
                        showTypePicker = true
                    } label: {
                        HStack {
                            Text("Kind")
                            Spacer()
                            Text(kind.title)
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }

            previewSection
            contentSection
            styleSections
        }
        .scrollDismissesKeyboard(.immediately)
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .scanflowScreenBackground()
        .navigationTitle(isEdit ? "Edit code" : "New code")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                    onFinished()
                }
                .tint(.primary)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save)
                    .fontWeight(.semibold)
            }
        }
        .onAppear(perform: load)
        .onChange(of: foregroundColor) { _, newValue in
            style.foregroundHex = newValue.rgbHexString()
        }
        .onChange(of: backgroundColor) { _, newValue in
            style.backgroundHex = newValue.rgbHexString()
        }
        .onChange(of: centerPhotoItem) { _, new in
            guard let new else { return }
            Task {
                if let data = try? await new.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        centerImageData = data
                        centerPhotoItem = nil
                    }
                }
            }
        }
        .sheet(isPresented: $showTypePicker) {
            NavigationStack {
                CreateTypePickerView { picked, social in
                    if let s = social, !s.isEmpty {
                        kind = .social
                        socialURL = s
                    } else if let picked {
                        kind = picked
                    }
                    showTypePicker = false
                }
            }
        }
    }

    private var isEdit: Bool {
        if case .edit = mode { return true }
        return false
    }

    @ViewBuilder
    private var styleSections: some View {
        Section {
            ColorPicker("Foreground", selection: $foregroundColor, supportsOpacity: false)
            ColorPicker("Background", selection: $backgroundColor, supportsOpacity: false)
            if kind != .barcode {
                Picker("Modules", selection: $style.moduleShape) {
                    Text("Square").tag(CodeModuleShape.square)
                    Text("Rounded").tag(CodeModuleShape.rounded)
                    Text("Circle").tag(CodeModuleShape.circle)
                }
                .pickerStyle(.menu)
                Picker("Eyes", selection: $style.pupilShape) {
                    Text("Square").tag(CodePupilShape.square)
                    Text("Rounded").tag(CodePupilShape.rounded)
                    Text("Circle").tag(CodePupilShape.circle)
                }
                .pickerStyle(.menu)
                Picker("Center", selection: $style.centerMode) {
                    Text("None").tag(CodeCenterMode.none)
                    Text("Auto").tag(CodeCenterMode.auto)
                    Text("Custom").tag(CodeCenterMode.custom)
                }
                .pickerStyle(.menu)
                if style.centerMode == .custom {
                    PhotosPicker(selection: $centerPhotoItem, matching: .images, photoLibrary: .shared()) {
                        Label(centerImageData == nil ? "Image" : "Replace", systemImage: "photo")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var previewSection: some View {
        Section {
            if let image = makePreviewImage() {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(maxHeight: 240)
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background {
                        RoundedRectangle(cornerRadius: LiquidGlass.cornerMedium, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                    }
                    .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                    .listRowBackground(Color.clear)
            } else {
                Image(systemName: "qrcode")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .listRowBackground(Color.clear)
            }
        }
    }

    /// Payload as it will be saved; empty if required fields are missing.
    private func builtPayload() -> String {
        CodePayloadBuilder.payload(
            kind: kind,
            phone: phone,
            web: web,
            emailAddress: emailAddress,
            emailSubject: emailSubject,
            emailBody: emailBody,
            smsNumber: smsNumber,
            smsBody: smsBody,
            contactName: contactName,
            contactPhone: contactPhone,
            contactEmail: contactEmail,
            eventTitle: eventTitle,
            eventLocation: eventLocation,
            eventStart: eventStart,
            eventEnd: eventEnd,
            wifiSSID: wifiSSID,
            wifiPassword: wifiPassword,
            wifiSecurity: wifiSecurity,
            plainText: plainText,
            latitude: latitude,
            longitude: longitude,
            barcodeText: barcodeText,
            socialURL: socialURL
        )
    }

    private func makePreviewImage() -> UIImage? {
        let real = builtPayload()
        let payload = previewPayload(forReal: real)
        let centerUIImage = centerImageData.flatMap { UIImage(data: $0) }
        switch kind {
        case .barcode:
            return QRBarcodeImageGenerator.linearBarcodeUIImage(
                payload: payload,
                style: style,
                size: CGSize(width: 480, height: 180)
            )
        default:
            return QRBarcodeImageGenerator.qrUIImage(
                payload: payload,
                style: style,
                centerImage: centerUIImage,
                size: 320
            )
        }
    }

    /// When fields are incomplete, still render a preview using neutral sample strings.
    private func previewPayload(forReal real: String) -> String {
        if !real.isEmpty { return real }
        switch kind {
        case .barcode:
            return "PREVIEW"
        default:
            return "https://scanflow.app/preview"
        }
    }

    @ViewBuilder
    private var contentSection: some View {
        switch kind {
        case .phone:
            Section("Phone") {
                TextField("Number", text: $phone)
                    .keyboardType(.phonePad)
            }
        case .web:
            Section("Website") {
                TextField("URL", text: $web)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
            }
        case .email:
            Section("Email") {
                TextField("Address", text: $emailAddress)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                TextField("Subject", text: $emailSubject)
                TextField("Body", text: $emailBody, axis: .vertical)
                    .lineLimit(3 ... 8)
            }
        case .message:
            Section("Message") {
                TextField("Phone number", text: $smsNumber)
                    .keyboardType(.phonePad)
                TextField("Message", text: $smsBody, axis: .vertical)
                    .lineLimit(3 ... 8)
            }
        case .contact:
            Section("Contact") {
                TextField("Name", text: $contactName)
                TextField("Phone", text: $contactPhone)
                    .keyboardType(.phonePad)
                TextField("Email", text: $contactEmail)
                    .keyboardType(.emailAddress)
            }
        case .calendar:
            Section("Event") {
                TextField("Title", text: $eventTitle)
                TextField("Location", text: $eventLocation)
                DatePicker("Starts", selection: $eventStart)
                DatePicker("Ends", selection: $eventEnd)
            }
        case .wifi:
            Section("Network") {
                TextField("Name (SSID)", text: $wifiSSID)
                SecureField("Password", text: $wifiPassword)
                Picker("Security", selection: $wifiSecurity) {
                    Text("WPA/WPA2").tag("WPA")
                    Text("WEP").tag("WEP")
                    Text("None").tag("nopass")
                }
            }
        case .text:
            Section("Text") {
                TextField("Content", text: $plainText, axis: .vertical)
                    .lineLimit(4 ... 12)
            }
        case .location:
            Section("Coordinates") {
                TextField("Latitude", text: $latitude)
                    .keyboardType(.numbersAndPunctuation)
                TextField("Longitude", text: $longitude)
                    .keyboardType(.numbersAndPunctuation)
            }
        case .barcode:
            Section("Barcode") {
                TextField("Content (Code 128)", text: $barcodeText)
            }
        case .social:
            Section("Social profile") {
                TextField("Profile URL", text: $socialURL)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
            }
        }
    }

    private func load() {
        switch mode {
        case .new:
            if let url = seedSocialURL, !url.isEmpty {
                kind = .social
                socialURL = url
            } else if let s = seedKind {
                kind = s
            }
        case let .edit(record):
            kind = record.kind
            style = CodeStyleConfiguration.decode(from: record.styleJSON)
            centerImageData = record.centerImageData
            splitPayload(record)
        }
        syncColorsFromStyle()
    }

    private func syncColorsFromStyle() {
        foregroundColor = Color(rgbHex: style.foregroundHex) ?? .black
        backgroundColor = Color(rgbHex: style.backgroundHex) ?? .white
    }

    private func splitPayload(_ record: CreatedCodeRecord) {
        let p = record.payload
        switch record.kind {
        case .phone:
            phone = p.replacingOccurrences(of: "tel:", with: "")
        case .web:
            web = p
        case .email:
            let base = p.split(separator: "?").first.map(String.init) ?? p
            emailAddress = base.replacingOccurrences(of: "mailto:", with: "", options: .caseInsensitive)
        case .message:
            smsNumber = ""
            smsBody = ""
            if p.hasPrefix("sms:") {
                let rest = String(p.dropFirst(4))
                if let q = rest.split(separator: "?").dropFirst().first,
                   q.hasPrefix("body=") {
                    let bodyPart = String(q.dropFirst(5)).removingPercentEncoding ?? ""
                    smsBody = bodyPart
                }
                let numPart = rest.split(separator: "?").first.map(String.init) ?? rest
                smsNumber = numPart.replacingOccurrences(of: "sms:", with: "")
            }
        case .contact:
            contactName = ""
            contactPhone = ""
            contactEmail = ""
            p.components(separatedBy: "\n").forEach { line in
                if line.hasPrefix("FN:") { contactName = String(line.dropFirst(3)) }
                if line.hasPrefix("TEL") { contactPhone = line.components(separatedBy: ":").last ?? "" }
                if line.hasPrefix("EMAIL") { contactEmail = line.components(separatedBy: ":").last ?? "" }
            }
        case .calendar:
            eventTitle = ""
            eventLocation = ""
            p.components(separatedBy: "\n").forEach { line in
                if line.hasPrefix("SUMMARY:") { eventTitle = String(line.dropFirst(8)) }
                if line.hasPrefix("LOCATION:") { eventLocation = String(line.dropFirst(9)) }
            }
        case .wifi:
            wifiSSID = ""
            wifiPassword = ""
            let parts = p.replacingOccurrences(of: "WIFI:", with: "").split(separator: ";")
            for part in parts {
                if part.hasPrefix("S:") { wifiSSID = String(part.dropFirst(2)) }
                if part.hasPrefix("P:") { wifiPassword = String(part.dropFirst(2)) }
                if part.hasPrefix("T:") { wifiSecurity = String(part.dropFirst(2)) }
            }
        case .text:
            plainText = p
        case .location:
            let coords = p.replacingOccurrences(of: "geo:", with: "").split(separator: ",")
            if coords.count >= 2 {
                latitude = String(coords[0])
                longitude = String(coords[1])
            }
        case .barcode:
            barcodeText = p
        case .social:
            socialURL = p
        }
    }

    private func save() {
        let payload = builtPayload()
        guard !payload.isEmpty else { return }
        let label = CodePayloadBuilder.defaultLabel(kind: kind, payload: payload)
        let center: Data?
        switch style.centerMode {
        case .custom:
            center = centerImageData
        case .auto, .none:
            center = nil
        }
        switch mode {
        case .new:
            model.saveNew(kind: kind, payload: payload, label: label, style: style, centerImageData: center)
        case let .edit(original):
            var updated = original
            updated.kind = kind
            updated.payload = payload
            updated.displayLabel = label
            updated.styleJSON = style.encodedJSON()
            updated.centerImageData = center
            updated.updatedAt = Date()
            model.update(updated)
        }
        dismiss()
        onFinished()
    }
}
