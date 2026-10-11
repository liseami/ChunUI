/**
 * [INPUT]: 依赖 SwiftUI Canvas、CoreGraphics 的圆角矩形判定
 * [OUTPUT]: 提供 CCGrilleLayout.holes、CCGrilleLayout.image 与 CCMicGrille。孔心在胶囊内缩后的圆角矩形里，奇数行错开半距，中间字带不打孔。每孔先铺暗底，再从孔沿向内投一道阴影：下移 0.75、模糊 1。image 给出同一张孔阵图，按住说话的板用它
 * [POS]: Components 的麦克风网罩。Chat0IM 录制态把它叠在输入坞中间那片玻璃上。孔是半透明暗底加一道下沉阴影，玻璃从孔里透出来
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI
import UIKit

public enum CCGrilleLayout {
    /// 孔心。label 是中间要让开的字框，.zero 表示不让
    public static func holes(
        size: CGSize,
        radius: CGFloat,
        label: CGSize,
        hole: CGFloat = 3,
        pitch: CGFloat = 7,
        insetH: CGFloat = 12,
        insetV: CGFloat = 6,
        labelPad: CGFloat = 10
    ) -> [CGPoint] {
        guard pitch > 0 else { return [] }
        let box = CGRect(origin: .zero, size: size).insetBy(dx: insetH + hole / 2, dy: insetV + hole / 2)
        guard box.width >= 0, box.height >= 0 else { return [] }
        let r = max(0, min(radius - insetV - hole / 2, box.width / 2, box.height / 2))
        let rows = Int(floor(box.height / pitch)) + 1
        let cols = Int(floor(box.width / pitch)) + 1
        let top = box.minY + (box.height - CGFloat(rows - 1) * pitch) / 2
        let clear = label.width > 0 && label.height > 0
            ? CGRect(
                x: (size.width - label.width) / 2 - labelPad,
                y: (size.height - label.height) / 2,
                width: label.width + labelPad * 2,
                height: label.height
            ).insetBy(dx: -hole / 2, dy: -hole / 2)
            : CGRect.null
        var out: [CGPoint] = []
        for row in 0..<rows {
            let n = row % 2 == 0 ? cols : cols - 1
            guard n > 0 else { continue }
            let left = box.minX + (box.width - CGFloat(n - 1) * pitch) / 2
            let y = top + CGFloat(row) * pitch
            for c in 0..<n {
                let p = CGPoint(x: left + CGFloat(c) * pitch, y: y)
                guard inside(p, box: box, radius: r), !clear.contains(p) else { continue }
                out.append(p)
            }
        }
        return out
    }

    /// 孔阵图。浅色暗度 0.32，深色 0.6。暗底是暗度的一半，内阴影下移 0.75、模糊 1
    public static func image(size: CGSize, radius: CGFloat, label: CGSize, dark: Bool, scale: CGFloat) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = max(1, scale)
        format.opaque = false
        let depth: CGFloat = dark ? 0.6 : 0.32
        let hole: CGFloat = 3
        let floor = UIColor.black.withAlphaComponent(depth * 0.5).cgColor
        let shade = UIColor.black.withAlphaComponent(depth).cgColor
        return UIGraphicsImageRenderer(size: size, format: format).image { renderer in
            let ctx = renderer.cgContext
            for center in holes(size: size, radius: radius, label: label) {
                let box = CGRect(x: center.x - hole / 2, y: center.y - hole / 2, width: hole, height: hole)
                ctx.setFillColor(floor)
                ctx.fillEllipse(in: box)
                ctx.saveGState()
                ctx.addEllipse(in: box)
                ctx.clip()
                ctx.setShadow(offset: CGSize(width: 0, height: 0.75), blur: 1, color: shade)
                ctx.addRect(box.insetBy(dx: -6, dy: -6))
                ctx.addEllipse(in: box)
                ctx.setFillColor(UIColor.black.cgColor)
                ctx.fillPath(using: .evenOdd)
                ctx.restoreGState()
            }
        }
    }

    private static func inside(_ p: CGPoint, box: CGRect, radius r: CGFloat) -> Bool {
        let e: CGFloat = 1e-6
        guard p.x >= box.minX - e, p.x <= box.maxX + e, p.y >= box.minY - e, p.y <= box.maxY + e else { return false }
        let cx = min(max(p.x, box.minX + r), box.maxX - r)
        let cy = min(max(p.y, box.minY + r), box.maxY - r)
        return hypot(p.x - cx, p.y - cy) <= r + e
    }
}

/// 录制时铺在玻璃上的网罩。clear 是中间让开的字带
public struct CCMicGrille: View {
    public var cornerRadius: CGFloat
    public var clear: CGSize

    @Environment(\.colorScheme) private var scheme

    public init(cornerRadius: CGFloat = 24, clear: CGSize = .zero) {
        self.cornerRadius = cornerRadius
        self.clear = clear
    }

    public var body: some View {
        Canvas { context, size in
            let depth = scheme == .dark ? 0.6 : 0.32
            let hole: CGFloat = 3
            let floor = Color.black.opacity(depth * 0.5)
            let shade = Color.black.opacity(depth)
            for center in CCGrilleLayout.holes(size: size, radius: cornerRadius, label: clear) {
                let box = CGRect(x: center.x - hole / 2, y: center.y - hole / 2, width: hole, height: hole)
                context.fill(Path(ellipseIn: box), with: .color(floor))
                context.drawLayer { layer in
                    layer.clip(to: Path(ellipseIn: box))
                    layer.addFilter(.shadow(color: shade, radius: 1, x: 0, y: 0.75))
                    let pad: CGFloat = 6
                    var punch = Path(box.insetBy(dx: -pad, dy: -pad))
                    punch.addEllipse(in: box)
                    layer.fill(punch, with: .color(.black), style: FillStyle(eoFill: true))
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
