# ScanFlow

A modern barcode and QR code scanner & generator for iOS, built with SwiftUI.

## Features

- **Scan** — Real-time camera scanning of QR codes and all major barcode formats
- **Decode from Photo** — Import images from your photo library and decode any barcode found
- **Generate** — Create QR codes and barcodes for 11 content types:
  - Website URL, Phone, Email, Message (SMS), Contact (vCard)
  - Calendar event, Wi-Fi credentials, Plain text, Location, Social profile, Barcode
- **History** — Full scan history stored locally with snapshots
- **Created Codes** — Save and manage generated codes

## Requirements

- iOS 26.0+
- Xcode 26+

## Tech Stack

- SwiftUI
- Vision / AVFoundation — barcode scanning
- Core Image — barcode & QR code generation
- SQLiteData — local persistence

## License

Copyright © Apps Bay Limited. All rights reserved.
