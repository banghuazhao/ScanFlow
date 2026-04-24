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

    let fg = UIColor(hex: style.foregroundHex) ?? .black
    let bg = UIColor(hex: style.backgroundHex) ?? .white

    guard let withModules = drawQRByModules(
      mask: output,
      outputSize: size,
      foreground: fg,
      background: bg,
      moduleShape: style.moduleShape
    ) else {
      // Fallback: flat CI render (no per-cell shaping) if module raster fails.
      return qrUIImageFlatFallback(
        from: output,
        style: style,
        centerImage: centerImage,
        size: size,
        fg: fg,
        bg: bg
      )
    }

    var ui = withModules
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

    return ui
  }

  /// Each QR module (cell) is drawn with the chosen shape. Previously `CodeModuleShape` only clipped the
  /// whole image, which only changed the outer frame rather than the data cells.
  private static func drawQRByModules(
    mask: CIImage,
    outputSize: CGFloat,
    foreground: UIColor,
    background: UIColor,
    moduleShape: CodeModuleShape
  ) -> UIImage? {
    let colored = applyFalseColor(image: mask, foreground: foreground, background: background) ?? mask
    guard let cg = context.createCGImage(colored, from: colored.extent) else { return nil }
    let w = max(Int(cg.width), 1)
    let h = max(Int(cg.height), 1)
    let dim = min(w, h)

    guard
      let grid = makeDarkGrid(
        from: cg,
        dim: dim,
        width: w,
        height: h,
        foreground: foreground,
        background: background
      )
    else { return nil }

    UIGraphicsBeginImageContextWithOptions(
      CGSize(width: outputSize, height: outputSize),
      true,
      0
    )
    defer { UIGraphicsEndImageContext() }
    guard let gctx = UIGraphicsGetCurrentContext() else { return nil }
    gctx.setShouldAntialias(true)

    background.setFill()
    gctx.fill(CGRect(x: 0, y: 0, width: outputSize, height: outputSize))

    let cell = outputSize / CGFloat(dim)
    let isDark: (Int, Int) -> Bool = { c, r in
      if c < 0 || r < 0 || c >= dim || r >= dim { return false }
      return grid[r * dim + c]
    }

    gctx.setFillColor(foreground.cgColor)
    for r in 0 ..< dim {
      for c in 0 ..< dim {
        guard isDark(c, r) else { continue }
        let x = CGFloat(c) * cell
        let y = CGFloat(r) * cell
        let frame = CGRect(x: x, y: y, width: cell, height: cell)
        addModulePath(in: frame, shape: moduleShape, context: gctx)
        gctx.drawPath(using: .fill)
      }
    }

    return UIGraphicsGetImageFromCurrentImageContext()
  }

  /// One entry per module, row-major, top row first. `dim` is the QR module count per side.
  private static func makeDarkGrid(
    from cg: CGImage,
    dim: Int,
    width: Int,
    height: Int,
    foreground: UIColor,
    background: UIColor
  ) -> [Bool]? {
    let fgRGB = rgbComponents(foreground)
    let bgRGB = rgbComponents(background)
    let w = width
    let h = height
    var bytes = [UInt8](repeating: 0, count: w * h * 4)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bytesPerRow = w * 4
    guard let cctx = CGContext(
      data: &bytes,
      width: w,
      height: h,
      bitsPerComponent: 8,
      bytesPerRow: bytesPerRow,
      space: colorSpace,
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { return nil }

    cctx.setShouldAntialias(false)
    cctx.draw(
      cg,
      in: CGRect(x: 0, y: 0, width: w, height: h)
    )

    // Downsample to dim×dim: average each cell in case CI output size differs.
    var out = [Bool](repeating: false, count: dim * dim)
    if w == dim && h == dim {
      for r in 0 ..< h {
        for c in 0 ..< w {
          let o = (r * bytesPerRow) + c * 4
          if o + 2 < bytes.count {
            out[r * dim + c] = isNearerForeground(
              b: bytes[o], g: bytes[o + 1], r: bytes[o + 2],
              fg: fgRGB, bg: bgRGB
            )
          }
        }
      }
    } else {
      for j in 0 ..< dim {
        for i in 0 ..< dim {
          let x0 = i * w / dim, x1 = (i + 1) * w / dim
          let y0 = j * h / dim, y1 = (j + 1) * h / dim
          var sr: Double = 0, sg: Double = 0, sb: Double = 0
          var n = 0
          for y in y0 ..< y1 {
            for x in x0 ..< x1 {
              let o = (y * bytesPerRow) + x * 4
              if o + 2 < bytes.count {
                sr += Double(bytes[o + 2]); sg += Double(bytes[o + 1]); sb += Double(bytes[o])
                n += 1
              }
            }
          }
          if n > 0 {
            let b = UInt8(sb / Double(n)), g = UInt8(sg / Double(n)), r = UInt8(sr / Double(n))
            out[j * dim + i] = isNearerForeground(b: b, g: g, r: r, fg: fgRGB, bg: bgRGB)
          }
        }
      }
    }

    return out
  }

  private static func rgbComponents(_ c: UIColor) -> (CGFloat, CGFloat, CGFloat) {
    if let comp = c.cgColor.components, comp.count >= 3 { return (comp[0], comp[1], comp[2]) }
    if let comp = c.cgColor.components, comp.count == 2 { let g = comp[0]; return (g, g, g) }
    var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
    if c.getRed(&r, green: &g, blue: &b, alpha: &a) { return (r, g, b) }
    return (0, 0, 0)
  }

  /// Classify a pixel as foreground (module) vs background after `CIFalseColor` (two-color, may be non-black).
  private static func isNearerForeground(
    b: UInt8, g: UInt8, r: UInt8,
    fg: (CGFloat, CGFloat, CGFloat),
    bg: (CGFloat, CGFloat, CGFloat)
  ) -> Bool {
    let pr = Double(r) / 255, pg = Double(g) / 255, pb = Double(b) / 255
    let dF = (pr - Double(fg.0)) * (pr - Double(fg.0))
      + (pg - Double(fg.1)) * (pg - Double(fg.1))
      + (pb - Double(fg.2)) * (pb - Double(fg.2))
    let dB = (pr - Double(bg.0)) * (pr - Double(bg.0))
      + (pg - Double(bg.1)) * (pg - Double(bg.1))
      + (pb - Double(bg.2)) * (pb - Double(bg.2))
    return dF < dB
  }

  private static func addModulePath(in cell: CGRect, shape: CodeModuleShape, context: CGContext) {
    switch shape {
    case .square:
      context.addRect(cell)
    case .rounded:
      let r = min(cell.width, cell.height) * 0.3
      let p = UIBezierPath(roundedRect: cell, cornerRadius: r)
      context.addPath(p.cgPath)
    case .circle:
      let pad = min(cell.width, cell.height) * 0.1
      let inner = cell.insetBy(dx: pad, dy: pad)
      context.addEllipse(in: inner)
    }
  }

  private static func applyFalseColor(
    image: CIImage,
    foreground: UIColor,
    background: UIColor
  ) -> CIImage? {
    let colorFilter = CIFilter.falseColor()
    colorFilter.inputImage = image
    colorFilter.color0 = CIColor(color: background)
    colorFilter.color1 = CIColor(color: foreground)
    return colorFilter.outputImage
  }

  private static func qrUIImageFlatFallback(
    from output: CIImage,
    style: CodeStyleConfiguration,
    centerImage: UIImage?,
    size: CGFloat,
    fg: UIColor,
    bg: UIColor
  ) -> UIImage? {
    let scale = size / output.extent.width
    let scaled = output.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
    guard let colored = applyFalseColor(image: scaled, foreground: fg, background: bg) else { return nil }
    guard let cgi = context.createCGImage(colored, from: colored.extent) else { return nil }
    var ui = UIImage(cgImage: cgi, scale: 1, orientation: .up)
    ui = drawPupilOverlay(on: ui, style: style.pupilShape, foreground: fg, background: bg) ?? ui
    if style.centerMode != .none {
      if let centerImage {
        ui = overlayCenterLogo(on: ui, logo: centerImage, foreground: fg) ?? ui
      } else if style.centerMode == .auto {
        if let s = UIImage(systemName: "qrcode")?.withTintColor(fg, renderingMode: .alwaysOriginal) {
          ui = overlayCenterLogo(on: ui, logo: s, foreground: fg) ?? ui
        }
      }
    }
    return ui
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

  private static func drawPupilOverlay(
    on image: UIImage,
    style: CodePupilShape,
    foreground: UIColor,
    background: UIColor
  ) -> UIImage? {
    let s = image.size
    UIGraphicsBeginImageContextWithOptions(s, false, image.scale)
    defer { UIGraphicsEndImageContext() }
    guard let ctx = UIGraphicsGetCurrentContext() else { return nil }
    image.draw(in: CGRect(origin: .zero, size: s))

    let patch = min(s.width, s.height) * 0.26
    let inset = min(s.width, s.height) * 0.065
    let corners: [CGPoint] = [
      CGPoint(x: inset, y: inset),
      CGPoint(x: s.width - inset - patch, y: inset),
      CGPoint(x: inset, y: s.height - inset - patch),
    ]

    for origin in corners {
      let r = CGRect(origin: origin, size: CGSize(width: patch, height: patch))
      ctx.setFillColor(background.cgColor)
      fillPupil(rect: r, style: style, in: ctx, color: background)
      let inner = r.insetBy(dx: r.width * 0.18, dy: r.height * 0.18)
      ctx.setFillColor(foreground.cgColor)
      fillPupil(rect: inner, style: style, in: ctx, color: foreground)
    }

    return UIGraphicsGetImageFromCurrentImageContext()
  }

  private static func fillPupil(rect: CGRect, style: CodePupilShape, in ctx: CGContext, color: UIColor) {
    ctx.setFillColor(color.cgColor)
    switch style {
    case .square:
      ctx.fill(rect)
    case .rounded:
      let p = UIBezierPath(roundedRect: rect, cornerRadius: rect.width * 0.18)
      ctx.addPath(p.cgPath)
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
    let p = UIBezierPath(roundedRect: bgRect, cornerRadius: 8)
    UIColor.white.setFill()
    p.fill()

    logo.draw(in: CGRect(origin: origin, size: CGSize(width: side, height: side)))
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
