/**
 * [INPUT]: 依赖 CoreGraphics 的 CGContext 与渐变、Accelerate 的 vImage 卷积（rim 的高斯模糊）；同目录 CCSkin 的层表 CCSkinLayer
 * [OUTPUT]: 对外提供 CCSkinPaint：draw 按层表把一副皮画进任意 CGContext；margin 给画到轮廓外的余量
 * [POS]: Components 的 Cromma 质感画法，四端唯一一份（Cromma CCBubblePaint 逐字同算法）。不造轮廓、不定跑道：
 *        轮廓 path 与中线光斑的跑道宽 plateau 由宿主按自己的几何给（胃之书 BellyBubblePaint.stretch、阿奇 ChatCrommaPaint、卡 CCFormCardSurface）。
 *        位图与 SwiftUI Canvas 两种上下文逐像素相同：只认用户空间，不用 CG 阴影。原胃之书 BellyBubblePaint、阿奇 ChatCrommaBubblePaint、ChunUI CCFormSkin 三份画法 2026-11-02 收归本文件
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import Accelerate
import CoreGraphics
import Foundation

nonisolated public enum CCSkinPaint {
    /// 一副皮画出轮廓外的余量（pt）：投影的 3σ 加下移
    public static func margin(_ layers: [CCSkinLayer]) -> CGFloat {
        var m: CGFloat = 0
        for case let .shadow(_, blur, y) in layers { m = max(m, blur * 3 + abs(y)) }
        return m
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 画：ctx 的用户空间是 pt、y 向下；body 是体（不含尾巴），path 是轮廓；pixel 是一个物理像素多少 pt
    // outgoing：尾巴在右（tail 边与 rim 光向随之镜像）；卡按 false 画。plateau：中线光斑从纵剖面拉开的半宽，0 不拉
    // 先画轮廓外的投影，再裁进轮廓按序画竖向渐变 · 径向光斑 · 内侧柔光 · 定向边缘高光 · 线
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    public static func draw(_ layers: [CCSkinLayer], path: CGPath, body: CGRect, outgoing: Bool = false, plateau: CGFloat = 0,
                            unit: CGFloat = CCSkin.unit, pixel: CGFloat, in ctx: CGContext) {
        guard body.width > 1, body.height > 1 else { return }
        let top = CGPoint(x: body.midX, y: body.minY)
        let bottom = CGPoint(x: body.midX, y: body.maxY)
        ctx.saveGState()
        defer { ctx.restoreGState() }
        ctx.setLineJoin(.round)

        for case let .shadow(color, blur, y) in layers {
            ctx.saveGState()
            ctx.addRect(body.insetBy(dx: -(blur * 3 + unit), dy: -(blur * 3 + unit)))
            ctx.addPath(path)
            ctx.clip(using: .evenOdd)
            ctx.translateBy(x: 0, y: y)
            band(path, color: color, half: 0, sigma: blur, filled: true, pixel: pixel, in: ctx)
            ctx.restoreGState()
        }

        ctx.saveGState()
        ctx.addPath(path)
        ctx.clip()
        for layer in layers {
            switch layer {
            case let .linear(stops):
                ctx.drawLinearGradient(gradient(stops), start: top, end: bottom, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
            case let .radial(color, x, y, radius, yScale, falloff):
                let towardTail: CGFloat = outgoing ? 1 : -1
                let dx = x.1 * unit
                let cx: CGFloat = switch x.0 {
                case .far: outgoing ? body.minX + dx : body.maxX - dx
                case .center: body.midX + towardTail * dx
                default: outgoing ? body.maxX - dx : body.minX + dx
                }
                let cy = y.0 == .bottom ? body.maxY - y.1 * unit : body.minY + y.1 * unit
                spot(color: color, center: CGPoint(x: cx, y: cy), radius: radius * unit, yScale: yScale, falloff: falloff,
                     plateau: x.0 == .center ? plateau : 0, height: body.height, in: ctx)
            case let .glow(color, width, blur):
                band(path, color: color, half: width / 2, sigma: blur, filled: false, pixel: pixel, in: ctx)
            case let .rim(color, angle, width, blur):
                rim(path, color: color, angle: angle, width: width, blur: blur, outgoing: outgoing, pixel: pixel, in: ctx)
            case let .line(width, stops):
                ctx.saveGState()
                ctx.addPath(path)
                ctx.setLineWidth(width * 2)
                ctx.replacePathWithStrokedPath()
                ctx.clip()
                ctx.drawLinearGradient(gradient(stops), start: top, end: bottom, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
                ctx.restoreGState()
            case .shadow:
                continue
            }
        }
        ctx.restoreGState()
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 光斑：颜色到透明的径向渐变，按 falloff 衰减，yScale 压扁；plateau > 0 时从中心纵剖面拉开成跑道
    // 衰减：t = 离心距 / 半径，f(0) = 1、f(1) = 0。linear f = 1 − t；gaussian f = (e^(−k·t²) − e^(−k)) / (1 − e^(−k))，
    // k = 3² / 2，半径即 3σ。渐变在色标间线性插值：gaussian 取等距 9 个色标近似，与 web 的 BubbleSurface 同一组色标。
    // 纵剖面是同一条曲线对中线的镜像（位置 0.5 ∓ t/2 取 f(t)），与径向渐变在中心那一列逐点相同，拼缝处无接痕
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private static func profile(_ kind: CCSkinLayer.Falloff) -> [(CGFloat, CGFloat)] {
        switch kind {
        case .linear:
            return [(0, 1), (1, 0)]
        case .gaussian:
            let k: CGFloat = 4.5
            let n = 9
            return (0..<n).map { j in
                let t = CGFloat(j) / CGFloat(n - 1)
                return (t, (exp(-k * t * t) - exp(-k)) / (1 - exp(-k)))
            }
        }
    }

    private static func spot(color: CCSkinLayer.RGBA, center c: CGPoint, radius r: CGFloat, yScale: CGFloat, falloff: CCSkinLayer.Falloff,
                             plateau e: CGFloat, height: CGFloat, in ctx: CGContext) {
        let curve = profile(falloff)
        let tint = { (f: CGFloat) -> CCSkinLayer.RGBA in (color.r, color.g, color.b, color.a * Double(f)) }
        let g = gradient(curve.map { ($0.0, tint($0.1)) })
        let far = r + height + e
        for (x, clip) in [(c.x - e, CGRect(x: c.x - e - far, y: c.y - far, width: far, height: far * 2)),
                          (c.x + e, CGRect(x: c.x + e, y: c.y - far, width: far, height: far * 2))] {
            ctx.saveGState()
            if e > 0 { ctx.clip(to: clip) }
            ctx.translateBy(x: x, y: c.y)
            ctx.scaleBy(x: 1, y: yScale)
            ctx.drawRadialGradient(g, startCenter: .zero, startRadius: 0, endCenter: .zero, endRadius: r, options: [])
            ctx.restoreGState()
            if e <= 0 { return }
        }
        let reach = r * yScale
        let mirrored = curve.reversed().map { (0.5 - $0.0 / 2, tint($0.1)) } + curve.dropFirst().map { (0.5 + $0.0 / 2, tint($0.1)) }
        ctx.saveGState()
        ctx.clip(to: CGRect(x: c.x - e, y: c.y - reach, width: e * 2, height: reach * 2))
        ctx.drawLinearGradient(gradient(mirrored), start: CGPoint(x: c.x, y: c.y - reach), end: CGPoint(x: c.x, y: c.y + reach), options: [])
        ctx.restoreGState()
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 高斯带：宽 2·half 的描边（居中）经 σ 模糊后的横截面，用一叠同色、由宽到窄的描边按像素分档叠出来
    // 离轮廓 d 处的目标覆盖 T(d) = a·[Φ((half−d)/σ) − Φ((−half−d)/σ)]（filled 即实心形状的边：a·Φ(−d/σ)，投影用）；第 j 道描边半宽 j·step，
    // 叠加后 d 落在第 j 档时覆盖 = 1 − Π_{k≥j}(1 − a_k)，逐档解出 a_j
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private static func band(_ path: CGPath, color: CCSkinLayer.RGBA, half: CGFloat, sigma: CGFloat, filled: Bool, pixel: CGFloat, in ctx: CGContext) {
        let s = max(sigma, 0.0001)
        let reach = half + 3 * s
        guard reach > 0, color.a > 0 else { return }
        let n = max(4, min(40, Int((reach / max(pixel * 0.75, 0.01)).rounded(.up))))
        let step = reach / CGFloat(n)
        func phi(_ x: CGFloat) -> CGFloat { 0.5 * erfc(-x / 2.squareRoot()) }
        let target = (0...n).map { j -> CGFloat in
            guard j < n else { return 0 }
            let d = (CGFloat(j) + 0.5) * step
            return min(0.999, color.a * (phi((half - d) / s) - (filled ? 0 : phi((-half - d) / s))))
        }
        for j in stride(from: n - 1, through: 0, by: -1) {
            let a = 1 - (1 - target[j]) / (1 - target[j + 1])
            guard a > 0.0005 else { continue }
            ctx.addPath(path)
            ctx.setLineWidth(CGFloat(j + 1) * step * 2)
            ctx.setStrokeColor(CGColor(srgbRed: color.r, green: color.g, blue: color.b, alpha: a))
            ctx.strokePath()
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 定向边缘高光 rim：光向 L = (cos a, −sin a)，x 朝尾巴那侧（随 outgoing 镜像）、y 向下
    // C = S ∖ (S − L·w)：点 p 留下，当且仅当 p + L·w 落在轮廓外——朝光的边上一弯月牙，宽 = w · max(0, n·L)。
    // 月牙按物理像素画进一张灰度遮罩，vImage 做可分离高斯卷积（σ = blur），再以遮罩填色；外侧由 draw 的轮廓裁形去掉
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private static func rim(_ path: CGPath, color: CCSkinLayer.RGBA, angle: CGFloat, width w: CGFloat, blur: CGFloat, outgoing: Bool, pixel: CGFloat, in ctx: CGContext) {
        guard color.a > 0, w > 0 else { return }
        let a = angle * .pi / 180
        let light = CGPoint(x: cos(a) * (outgoing ? 1 : -1), y: -sin(a))
        let scale = 1 / max(pixel, 0.01)
        let box = path.boundingBoxOfPath.insetBy(dx: -(blur * 3 + pixel), dy: -(blur * 3 + pixel))
        let wPx = Int((box.width * scale).rounded(.up)), hPx = Int((box.height * scale).rounded(.up))
        guard wPx > 0, hPx > 0, let mask = CGContext(
            data: nil, width: wPx, height: hPx, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return }
        // 不翻转：用户 minY 落在遮罩的末行，按用户空间贴回时与目标上下文同向
        mask.scaleBy(x: scale, y: scale)
        mask.translateBy(x: -box.minX, y: -box.minY)
        mask.setFillColor(gray: 1, alpha: 1)
        mask.addPath(path)
        mask.fillPath()
        mask.translateBy(x: -light.x * w, y: -light.y * w)
        mask.setFillColor(gray: 0, alpha: 1)
        mask.addPath(path)
        mask.fillPath()
        if blur > 0, let data = mask.data { gaussian(data, width: wPx, height: hPx, rowBytes: mask.bytesPerRow, sigma: blur * scale) }
        guard let image = mask.makeImage() else { return }
        let frame = CGRect(x: box.minX, y: box.minY, width: CGFloat(wPx) / scale, height: CGFloat(hPx) / scale)
        ctx.saveGState()
        ctx.clip(to: frame, mask: image)
        ctx.setFillColor(CGColor(srgbRed: color.r, green: color.g, blue: color.b, alpha: color.a))
        ctx.fill(frame)
        ctx.restoreGState()
    }

    /// 8 位灰度原地高斯模糊：横、竖两遍 1 × K 卷积，K = 2⌈3σ⌉ + 1，形外按 0 补
    private static func gaussian(_ data: UnsafeMutableRawPointer, width: Int, height: Int, rowBytes: Int, sigma: CGFloat) {
        let r = max(1, Int((sigma * 3).rounded(.up)))
        let weights = (-r...r).map { i in exp(-CGFloat(i * i) / (2 * sigma * sigma)) }
        let total = weights.reduce(0, +)
        let kernel = weights.map { Int16(($0 / total * 4096).rounded()) }
        let divisor = Int32(kernel.reduce(0) { $0 + Int($1) })
        guard let scratch = malloc(rowBytes * height) else { return }
        defer { free(scratch) }
        var src = vImage_Buffer(data: data, height: vImagePixelCount(height), width: vImagePixelCount(width), rowBytes: rowBytes)
        var tmp = vImage_Buffer(data: scratch, height: vImagePixelCount(height), width: vImagePixelCount(width), rowBytes: rowBytes)
        let size = UInt32(kernel.count)
        let flags = vImage_Flags(kvImageBackgroundColorFill)
        kernel.withUnsafeBufferPointer { k in
            _ = vImageConvolve_Planar8(&src, &tmp, nil, 0, 0, k.baseAddress!, 1, size, divisor, 0, flags)
            _ = vImageConvolve_Planar8(&tmp, &src, nil, 0, 0, k.baseAddress!, size, 1, divisor, 0, flags)
        }
    }

    private static let space = CGColorSpace(name: CGColorSpace.sRGB)!

    private static func gradient(_ stops: [(CGFloat, CCSkinLayer.RGBA)]) -> CGGradient {
        let colors = stops.map { CGColor(srgbRed: $0.1.r, green: $0.1.g, blue: $0.1.b, alpha: $0.1.a) }
        return CGGradient(colorsSpace: space, colors: colors as CFArray, locations: stops.map(\.0))!
    }
}
