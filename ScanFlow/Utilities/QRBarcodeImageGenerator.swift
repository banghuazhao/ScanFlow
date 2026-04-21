//
// Created by Banghua Zhao on 21/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

enum QRBarcodeImageGenerator {
  private static let context = CIContext(options: [.useSoftwareRenderer: false])

  static func qrUIImage(
    payload: String,
    style: CodeStyleConfiguration,
    centerImage: UIImage?,
    size: CGFloat = 512
  ) -> UIImage? {
    let filter = CIFilter.qrCodeGenerator()
    filter.message = Data(payload.utf8)
    filter.correctionLevel = "H"
    guard let output = filter.outputImage else { return nil }

    let scale = size / output.extent.width
    let scaled = output.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

    let fg = UIColor(hex: style.foregroundHex) ?? .black
    let bg = UIColor(hex: style.backgroundHex) ?? .white

    guard let colored = applyFalseColor(image: scaled, foreground: fg, background: bg) else { return nil }
    guard let cgImage = context.createCGImage(colored, from: colored.extent) else { return nil }
    var ui = UIImage(cgImage: cgImage, scale: 1, orientation: .up)

    ui = drawPupilOverlay(on: ui, style: style.pupilShape, foreground: fg, background: bg) ?? ui

    if style.centerMode != .none {
      if let centerImage {
        ui = overlayCenterLogo(on: ui, logo: centerImage, foreground: fg) ?? ui
      } else if style.centerMode == .auto {
        let symbol = UIImage(systemName: "qrcode")?.withTintColor(fg, renderingMode: .alwaysOriginal)
        if let symbol {
          ui = overlayCenterLogo(on: ui, logo: symbol, foreground: fg) ?? ui
        }
      }
    }

    return clipQR(ui, moduleShape: style.moduleShape)
  }

  static func linearBarcodeUIImage(
    payload: String,
    style: CodeStyleConfiguration,
    size: CGSize = CGSize(width: 512, height: 200)
  ) -> UIImage? {
    guard let filter = CIFilter(name: "CICode128BarcodeGenerator") else { return nil }
    filter.setValue(Data(payload.utf8), forKey: "inputMessage")
    guard let output = filter.outputImage else { return nil }

    let scaleX = size.width / output.extent.width
    let scaleY = size.height / output.extent.height
    let scaled = output.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

    let fg = UIColor(hex: style.foregroundHex) ?? .black
    let bg = UIColor(hex: style.backgroundHex) ?? .white
    guard let colored = applyFalseColor(image: scaled, foreground: fg, background: bg) else { return nil }

    guard let cgImage = context.createCGImage(colored, from: colored.extent) else { return nil }
    return UIImage(cgImage: cgImage, scale: 1, orientation: .up)
  }

  private static func applyFalseColor(image: CIImage, foreground: UIColor, background: UIColor) -> CIImage? {
    let colorFilter = CIFilter.falseColor()
    colorFilter.inputImage = image
    colorFilter.color0 = CIColor(color: background)
    colorFilter.color1 = CIColor(color: foreground)
    return colorFilter.outputImage
  }

  private static func drawPupilOverlay(on image: UIImage, style: CodePupilShape, foreground: UIColor, background: UIColor) -> UIImage? {
    let size = image.size
    UIGraphicsBeginImageContextWithOptions(size, false, image.scale)
    defer { UIGraphicsEndImageContext() }
    guard let ctx = UIGraphicsGetCurrentContext() else { return nil }
    image.draw(in: CGRect(origin: .zero, size: size))

    let patch = min(size.width, size.height) * 0.26
    let inset = min(size.width, size.height) * 0.065
    let corners: [CGPoint] = [
      CGPoint(x: inset, y: inset),
      CGPoint(x: size.width - inset - patch, y: inset),
      CGPoint(x: inset, y: size.height - inset - patch),
    ]

    for origin in corners {
      let rect = CGRect(origin: origin, size: CGSize(width: patch, height: patch))
      ctx.setFillColor(background.cgColor)
      fill(rect: rect, style: style, in: ctx, color: background)
      let inner = rect.insetBy(dx: rect.width * 0.18, dy: rect.height * 0.18)
      ctx.setFillColor(foreground.cgColor)
      fill(rect: inner, style: style, in: ctx, color: foreground)
    }

    return UIGraphicsGetImageFromCurrentImageContext()
  }

  private static func fill(rect: CGRect, style: CodePupilShape, in ctx: CGContext, color: UIColor) {
    ctx.setFillColor(color.cgColor)
    switch style {
    case .square:
      ctx.fill(rect)
    case .rounded:
      let path = UIBezierPath(roundedRect: rect, cornerRadius: rect.width * 0.18)
      ctx.addPath(path.cgPath)
      ctx.fillPath()
    case .circle:
      ctx.fillEllipse(in: rect)
    }
  }

  private static func overlayCenterLogo(on qr: UIImage, logo: UIImage, foreground: UIColor) -> UIImage? {
    let size = qr.size
    UIGraphicsBeginImageContextWithOptions(size, false, qr.scale)
    defer { UIGraphicsEndImageContext() }
    qr.draw(in: CGRect(origin: .zero, size: size))

    let side = min(size.width, size.height) * 0.24
    let origin = CGPoint(x: (size.width - side) / 2, y: (size.height - side) / 2)
    let pad: CGFloat = 6
    let bgRect = CGRect(x: origin.x - pad, y: origin.y - pad, width: side + pad * 2, height: side + pad * 2)
    let path = UIBezierPath(roundedRect: bgRect, cornerRadius: 8)
    UIColor.white.setFill()
    path.fill()

    logo.draw(in: CGRect(origin: origin, size: CGSize(width: side, height: side)))
    return UIGraphicsGetImageFromCurrentImageContext()
  }

  private static func clipQR(_ image: UIImage, moduleShape: CodeModuleShape) -> UIImage? {
    switch moduleShape {
    case .square:
      return image
    case .rounded:
      return image.withRoundedCorners(radius: 18)
    case .circle:
      return image.circular()
    }
  }
}

private extension UIImage {
  func withRoundedCorners(radius: CGFloat) -> UIImage? {
    let rect = CGRect(origin: .zero, size: size)
    UIGraphicsBeginImageContextWithOptions(size, false, scale)
    defer { UIGraphicsEndImageContext() }
    let path = UIBezierPath(roundedRect: rect, cornerRadius: radius)
    path.addClip()
    draw(in: rect)
    return UIGraphicsGetImageFromCurrentImageContext()
  }

  func circular() -> UIImage? {
    let shortest = min(size.width, size.height)
    UIGraphicsBeginImageContextWithOptions(CGSize(width: shortest, height: shortest), false, scale)
    defer { UIGraphicsEndImageContext() }
    let path = UIBezierPath(ovalIn: CGRect(origin: .zero, size: CGSize(width: shortest, height: shortest)))
    path.addClip()
    draw(in: CGRect(x: (shortest - size.width) / 2, y: (shortest - size.height) / 2, width: size.width, height: size.height))
    return UIGraphicsGetImageFromCurrentImageContext()
  }
}

extension UIColor {
  convenience init?(hex: String) {
    var s = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    if s.hasPrefix("#") { s.removeFirst() }
    guard s.count == 6 || s.count == 8 else { return nil }
    var value: UInt64 = 0
    guard Scanner(string: s).scanHexInt64(&value) else { return nil }
    if s.count == 6 {
      self.init(
        red: CGFloat((value & 0xFF0000) >> 16) / 255,
        green: CGFloat((value & 0x00FF00) >> 8) / 255,
        blue: CGFloat(value & 0x0000FF) / 255,
        alpha: 1
      )
    } else {
      self.init(
        red: CGFloat((value & 0xFF00_0000) >> 24) / 255,
        green: CGFloat((value & 0x00FF_0000) >> 16) / 255,
        blue: CGFloat((value & 0x0000_FF00) >> 8) / 255,
        alpha: CGFloat(value & 0x0000_00FF) / 255
      )
    }
  }
}
