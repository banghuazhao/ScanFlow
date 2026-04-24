//
// Created by Banghua Zhao on 21/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

/// Full-screen dimming with a clear rounded “window” and white corner brackets.
struct ScanViewfinderOverlay: View {
  var body: some View {
    GeometryReader { geo in
      let side = min(geo.size.width * 0.76, 304)
      let center = CGPoint(x: geo.size.width / 2, y: geo.size.height * 0.38)

      ZStack {
        ZStack {
          Rectangle()
            .fill(Color.black.opacity(0.42))
            .ignoresSafeArea()
          RoundedRectangle(cornerRadius: LiquidGlass.cornerMedium, style: .continuous)
            .frame(width: side, height: side)
            .position(center)
            .blendMode(.destinationOut)
        }
        .compositingGroup()
        .allowsHitTesting(false)

        ViewfinderCornerBrackets(side: side, arm: 36, lineWidth: 5)
          .position(center)
      }
      .frame(width: geo.size.width, height: geo.size.height)
    }
  }
}

private struct ViewfinderCornerBrackets: View {
  var side: CGFloat
  var arm: CGFloat
  var lineWidth: CGFloat

  private var stroke: StrokeStyle {
    var s = StrokeStyle()
    s.lineWidth = lineWidth
    s.lineCap = .round
    s.lineJoin = .round
    s.miterLimit = 2
    return s
  }

  var body: some View {
    Canvas { context, _ in
      let w = side
      let a = min(arm, w * 0.48)
      let stroke = self.stroke
      let white = Color.white

      // True L at each window corner: the inner 90° is a smooth fillet from `lineJoin: .round`;
      // arm ends use `lineCap: .round` (no ad‑hoc arcs, which were easy to get wrong in Y-down space).
      var tl = Path()
      tl.move(to: CGPoint(x: 0, y: a))
      tl.addLine(to: CGPoint(x: 0, y: 0))
      tl.addLine(to: CGPoint(x: a, y: 0))
      context.stroke(tl, with: .color(white), style: stroke)

      var tr = Path()
      tr.move(to: CGPoint(x: w - a, y: 0))
      tr.addLine(to: CGPoint(x: w, y: 0))
      tr.addLine(to: CGPoint(x: w, y: a))
      context.stroke(tr, with: .color(white), style: stroke)

      var br = Path()
      br.move(to: CGPoint(x: w, y: w - a))
      br.addLine(to: CGPoint(x: w, y: w))
      br.addLine(to: CGPoint(x: w - a, y: w))
      context.stroke(br, with: .color(white), style: stroke)

      var bl = Path()
      bl.move(to: CGPoint(x: a, y: w))
      bl.addLine(to: CGPoint(x: 0, y: w))
      bl.addLine(to: CGPoint(x: 0, y: w - a))
      context.stroke(bl, with: .color(white), style: stroke)
    }
    .frame(width: side, height: side)
    .shadow(color: .black.opacity(0.35), radius: 2, y: 1)
  }
}
