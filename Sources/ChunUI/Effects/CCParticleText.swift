//
//  CCParticleText.swift
//  ChunUI
//

/**
 * [INPUT]: 依赖 UIKit 离屏灰度位图采样字形（字经 Theme 的 CCFontFamily.uiFont）、SwiftUI TimelineView + Canvas、Color.cc 主题轴与 Color.mix、Reduce Motion；形制移植 React Bits ParticleText（粒子散开→错拍聚合成字→呼吸漂浮→指针斥力）
 * [OUTPUT]: 对外提供 CCParticleText——粒子聚字特效（进场从四散聚合出文本，落定后微漂；拖动手指斥开粒子）
 * [POS]: Effects 的文字特效原语，宿主 Onboarding 收益页等消费；性能纲领 = 调色板 12 桶批量 Path 填充（禁逐粒 fill）+ 采样按尺寸缓存；Reduce Motion 直落静态
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI
import UIKit

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCParticleText（粒子聚字：散开进场 → easeOutCubic 错拍聚合 → 漂浮 + 斥力）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct CCParticleText: View {
    var text: String
    var fontSize: CGFloat
    var particleSize: CGFloat
    var density: Int
    var color: Color
    var highlightColor: Color
    var scatter: CGFloat
    var gatherDuration: Double
    var stagger: Double
    var idleDrift: CGFloat
    var pointerRepel: CGFloat
    var repelRadius: CGFloat
    var maxParticles: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var model = CCParticleTextModel()

    public init(
        _ text: String,
        fontSize: CGFloat = 72,
        particleSize: CGFloat = 2.2,
        density: Int = 4,
        color: Color = .cc.foreground,
        highlightColor: Color = .cc.primary,
        scatter: CGFloat = 170,
        gatherDuration: Double = 1.5,
        stagger: Double = 0.4,
        idleDrift: CGFloat = 0.7,
        pointerRepel: CGFloat = 42,
        repelRadius: CGFloat = 95,
        maxParticles: Int = 2400
    ) {
        self.text = text
        self.fontSize = fontSize
        self.particleSize = particleSize
        self.density = max(2, density)
        self.color = color
        self.highlightColor = highlightColor
        self.scatter = scatter
        self.gatherDuration = gatherDuration
        self.stagger = stagger
        self.idleDrift = idleDrift
        self.pointerRepel = pointerRepel
        self.repelRadius = repelRadius
        self.maxParticles = maxParticles
    }

    public var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            Canvas { context, size in
                model.rebuildIfNeeded(
                    size: size, text: text, fontSize: fontSize, density: density,
                    particleSize: particleSize, scatter: scatter, stagger: stagger,
                    color: color, highlight: highlightColor,
                    maxParticles: maxParticles, reduceMotion: reduceMotion
                )
                model.step(
                    now: timeline.date.timeIntervalSinceReferenceDate,
                    context: &context,
                    gatherDuration: gatherDuration, idleDrift: idleDrift,
                    pointerRepel: pointerRepel, repelRadius: repelRadius,
                    reduceMotion: reduceMotion
                )
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    model.pointer = value.location
                    model.pointerActive = true
                }
                .onEnded { _ in model.pointerActive = false }
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 模型（引用类型：Canvas 闭包内逐帧推进；采样按 尺寸+文案 缓存）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

@MainActor
final class CCParticleTextModel {
    private struct Particle {
        var x: CGFloat, y: CGFloat
        var startX: CGFloat, startY: CGFloat
        let targetX: CGFloat, targetY: CGFloat
        let size: CGFloat
        let seed: CGFloat
        let depth: CGFloat
        let delay: Double
        let bucket: Int
    }

    var pointer: CGPoint = .zero
    var pointerActive = false

    private var particles: [Particle] = []
    private var palette: [Color] = []
    private var smoothPointer: CGPoint = .zero
    private var gatherStart: TimeInterval = 0
    private var gathering = false
    private var cacheKey = ""

    private static let paletteCount = 12

    // ━━━ 采样重建（尺寸/文案/参数变化才跑；离屏灰度位图读字形覆盖）━━━

    func rebuildIfNeeded(
        size: CGSize, text: String, fontSize: CGFloat, density: Int,
        particleSize: CGFloat, scatter: CGFloat, stagger: Double,
        color: Color, highlight: Color, maxParticles: Int, reduceMotion: Bool
    ) {
        let key = "\(Int(size.width))x\(Int(size.height))|\(text)|\(fontSize)|\(density)|\(reduceMotion)"
        guard key != cacheKey, size.width > 4, size.height > 4 else { return }
        cacheKey = key

        palette = (0 ..< Self.paletteCount).map { index in
            color.mix(with: highlight, amount: Double(index) / Double(Self.paletteCount - 1))
        }

        let targets = Self.sampleTargets(text: text, fontSize: fontSize, density: density, in: size)
        let stride = max(1, Int((Double(targets.count) / Double(maxParticles)).rounded(.up)))
        let picked = targets.enumerated().filter { $0.offset % stride == 0 }.map(\.element)

        particles = picked.enumerated().map { index, target in
            // 确定性伪随机（React 版同构线性同余），渲染间稳定
            let seed = CGFloat((index * 9301 + 49297) % 233_280) / 233_280
            let depth = 0.45 + CGFloat((index * 233 + 97) % 1000) / 1000 * 0.9
            let blend = min(max(target.point.x / max(1, size.width) + (seed - 0.5) * 0.35, 0), 1)
            let bucket = min(Self.paletteCount - 1, Int(blend * CGFloat(Self.paletteCount)))
            let angle = seed * .pi * 2
            let distance = (reduceMotion ? 0 : scatter) * (0.35 + depth * 0.75)
            let startX = target.point.x + cos(angle) * distance + (seed - 0.5) * scatter * 0.45
            let startY = target.point.y + sin(angle) * distance + (depth - 0.9) * scatter * 0.45
            return Particle(
                x: reduceMotion ? target.point.x : startX,
                y: reduceMotion ? target.point.y : startY,
                startX: startX, startY: startY,
                targetX: target.point.x, targetY: target.point.y,
                size: max(0.6, particleSize * (0.75 + target.alpha * 0.45)),
                seed: seed, depth: depth,
                delay: Double(seed) * stagger,
                bucket: bucket
            )
        }

        pointer = CGPoint(x: size.width / 2, y: size.height / 2)
        smoothPointer = pointer
        gathering = !reduceMotion
        gatherStart = Date.timeIntervalSinceReferenceDate + 0.05
    }

    /// 字形采样：文本落进灰度离屏位图，按 density 步长取覆盖点（超宽自动收缩字号）
    private static func sampleTargets(
        text: String, fontSize: CGFloat, density: Int, in size: CGSize
    ) -> [(point: CGPoint, alpha: CGFloat)] {
        var resolvedSize = fontSize
        var font = CCFontFamily.uiFont(size: resolvedSize, weight: .heavy)
        var attrs: [NSAttributedString.Key: Any] = [.font: font]
        var textSize = (text as NSString).size(withAttributes: attrs)
        let maxWidth = size.width * 0.92
        if textSize.width > maxWidth {
            resolvedSize = max(16, resolvedSize * maxWidth / textSize.width)
            font = CCFontFamily.uiFont(size: resolvedSize, weight: .heavy)
            attrs = [.font: font]
            textSize = (text as NSString).size(withAttributes: attrs)
        }

        let pad: CGFloat = max(8, resolvedSize * 0.08)
        let w = Int(ceil(textSize.width + pad * 2))
        let h = Int(ceil(textSize.height + pad * 2))
        guard w > 0, h > 0,
              let ctx = CGContext(
                  data: nil, width: w, height: h,
                  bitsPerComponent: 8, bytesPerRow: w,
                  space: CGColorSpaceCreateDeviceGray(),
                  bitmapInfo: CGImageAlphaInfo.none.rawValue
              )
        else { return [] }

        // UIKit 文本进 CG 灰度位图：翻转坐标 + 白字黑底，亮度即覆盖
        ctx.translateBy(x: 0, y: CGFloat(h))
        ctx.scaleBy(x: 1, y: -1)
        UIGraphicsPushContext(ctx)
        attrs[.foregroundColor] = UIColor.white
        (text as NSString).draw(at: CGPoint(x: pad, y: pad), withAttributes: attrs)
        UIGraphicsPopContext()

        guard let data = ctx.data else { return [] }
        let bytes = data.bindMemory(to: UInt8.self, capacity: w * h)
        let originX = size.width / 2 - CGFloat(w) / 2
        let originY = size.height / 2 - CGFloat(h) / 2

        var targets: [(CGPoint, CGFloat)] = []
        var y = 0
        while y < h {
            var x = 0
            while x < w {
                let value = bytes[y * w + x]
                if value > 40 {
                    targets.append((
                        CGPoint(x: originX + CGFloat(x), y: originY + CGFloat(y)),
                        CGFloat(value) / 255
                    ))
                }
                x += density
            }
            y += density
        }
        return targets
    }

    // ━━━ 逐帧推进 + 绘制（调色板 12 桶批量填充，禁逐粒 fill）━━━

    func step(
        now: TimeInterval, context: inout GraphicsContext,
        gatherDuration: Double, idleDrift: CGFloat,
        pointerRepel: CGFloat, repelRadius: CGFloat, reduceMotion: Bool
    ) {
        guard !particles.isEmpty else { return }

        smoothPointer.x += (pointer.x - smoothPointer.x) * 0.18
        smoothPointer.y += (pointer.y - smoothPointer.y) * 0.18

        var paths = Array(repeating: Path(), count: Self.paletteCount)
        var complete = true
        var overallProgress: Double = 1

        for i in particles.indices {
            var p = particles[i]
            var baseX = p.targetX
            var baseY = p.targetY

            if gathering {
                let local = (now - gatherStart - p.delay) / max(0.01, gatherDuration)
                let progress = min(max(local, 0), 1)
                let eased = 1 - pow(1 - progress, 3)   // easeOutCubic
                baseX = p.startX + (p.targetX - p.startX) * eased
                baseY = p.startY + (p.targetY - p.startY) * eased
                if progress < 1 { complete = false }
                overallProgress = min(overallProgress, progress)
            } else if !reduceMotion, idleDrift > 0 {
                baseX += sin(now * 0.9 + p.seed * 10) * idleDrift * p.depth
                baseY += cos(now * 0.75 + p.depth * 10) * idleDrift * p.depth
            }

            if pointerActive, !reduceMotion, pointerRepel > 0, repelRadius > 0 {
                let dx = baseX - smoothPointer.x
                let dy = baseY - smoothPointer.y
                let distance = hypot(dx, dy)
                if distance > 0, distance < repelRadius {
                    let force = pow(1 - distance / repelRadius, 2) * pointerRepel
                    baseX += dx / distance * force
                    baseY += dy / distance * force
                }
            }

            let follow: CGFloat = reduceMotion ? 1 : 0.22
            p.x += (baseX - p.x) * follow
            p.y += (baseY - p.y) * follow
            particles[i] = p

            paths[p.bucket].addRect(
                CGRect(x: p.x - p.size / 2, y: p.y - p.size / 2, width: p.size, height: p.size)
            )
        }

        if gathering {
            // 聚合期整体透明度随进度抬升（React 逐粒 alpha 的批量近似）
            context.opacity = 0.45 + 0.55 * overallProgress
            if complete { gathering = false }
        }

        for (index, path) in paths.enumerated() where !path.isEmpty {
            context.fill(path, with: .color(palette[index]))
        }
    }
}

#Preview("粒子聚字") {
    CCParticleText("$200,000,000", fontSize: 64)
        .frame(height: 260)
        .background(Color.cc.background)
}
