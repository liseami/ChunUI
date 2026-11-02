/**
 * [INPUT]: 依赖 CoreGraphics 的 CGFloat、SwiftUI 的 Color；数值逐字取自 Cromma tokens.yaml 的四套私聊皮（CrommaChatTokens）
 * [OUTPUT]: 对外提供 CCSkinLayer（皮的一层：渐变 · 光斑 · 柔光带 · 定向高光 · 线 · 投影）与 CCSkin（正文色 + 层表；bubble(outgoing:dark:) 四副对话皮、card(dark:) 两副卡皮、unit 单位）
 * [POS]: Components 的 Cromma 质感数据真相，四端唯一一份。画法在同目录 CCSkinPaint，本文件只放数。
 *        消费方：CCFormCardSurface（设置卡，取 card）、胃之书 BellyBubbleImages 与阿奇 ChatCrommaBubble（对话气泡，取 bubble）。
 *        原胃之书 BellyChatTokens.Skin、阿奇 ChatCrommaPaint.layers、ChunUI CCFormSkin 三份抄本 2026-11-02 收归本文件
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import CoreGraphics
import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 皮的一层：x / y 以边加偏移定位，偏移以单位 unit 计
// tail 是尾巴那侧，far 是远侧：CCSkinPaint 按 outgoing 镜像——outgoing 尾巴在右，否则在左（卡按非 outgoing 画）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

nonisolated public enum CCSkinLayer: Sendable {
    public enum Edge: Sendable { case tail, far, center, top, bottom }
    /// 光斑衰减：linear 是锥形；gaussian 是 radius = 3σ 的截断高斯柔光
    public enum Falloff: Sendable { case linear, gaussian }
    /// sRGB 0–1 与不透明度
    public typealias RGBA = (r: Double, g: Double, b: Double, a: Double)

    case linear(stops: [(CGFloat, RGBA)])
    case radial(color: RGBA, x: (Edge, CGFloat), y: (Edge, CGFloat), radius: CGFloat, yScale: CGFloat, falloff: Falloff)
    case glow(color: RGBA, width: CGFloat, blur: CGFloat)
    /// 定向边缘高光：angle 是光向（度，0 朝尾巴那侧、90 朝上），width 与 blur 是 pt
    case rim(color: RGBA, angle: CGFloat, width: CGFloat, blur: CGFloat)
    case line(width: CGFloat, stops: [(CGFloat, RGBA)])
    /// 轮廓外的投影：blur 是 σ（pt），y 是下移
    case shadow(color: RGBA, blur: CGFloat, y: CGFloat)
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 一副皮：正文色 + 自下而上的层表
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

nonisolated public struct CCSkin: Sendable {
    public let text: CCSkinLayer.RGBA
    public let layers: [CCSkinLayer]

    public init(text: CCSkinLayer.RGBA, layers: [CCSkinLayer]) {
        self.text = text
        self.layers = layers
    }

    /// 光斑与偏移的单位：气泡单行胶囊高 = 2 × 圆角 20
    public static let unit: CGFloat = 40

    /// 皮上正文的颜色
    public var textColor: Color { Color(.sRGB, red: text.r, green: text.g, blue: text.b, opacity: text.a) }

    /// 对话气泡：outgoing 是青柠（自己），否则是白皮（对方）
    public static func bubble(outgoing: Bool, dark: Bool) -> CCSkin {
        switch (outgoing, dark) {
        case (true, false): outgoingLight
        case (true, true): outgoingDark
        case (false, false): incomingLight
        case (false, true): incomingDark
        }
    }

    /// 设置卡：对方气泡那副皮，两道线 × 0.45、中线暗斑 × 0.4
    public static func card(dark: Bool) -> CCSkin { dark ? cardDark : cardLight }

    // ━━━ 设置卡：由对方气泡派生，不另抄数 ━━━

    private static let cardLight = incomingLight.softened(line: 0.45, center: 0.4)
    private static let cardDark = incomingDark.softened(line: 0.45, center: 0.4)

    private func softened(line: Double, center: Double) -> CCSkin {
        func fade(_ c: CCSkinLayer.RGBA, _ k: Double) -> CCSkinLayer.RGBA { (c.r, c.g, c.b, c.a * k) }
        return CCSkin(text: text, layers: layers.map { layer in
            switch layer {
            case let .line(width, stops):
                .line(width: width, stops: stops.map { ($0.0, fade($0.1, line)) })
            case let .radial(color, x, y, radius, yScale, falloff) where x.0 == .center:
                .radial(color: fade(color, center), x: x, y: y, radius: radius, yScale: yScale, falloff: falloff)
            default:
                layer
            }
        })
    }

    // ━━━ 四副对话皮：九层自下而上——竖向渐变 · 中线暗斑 · 尾侧上柔光 · 远侧下柔光 · 内发光带 · 外描边 · 两道定向高光 · 内描边 ━━━

    private static let outgoingLight = CCSkin(text: (0.1922, 0.3098, 0.0745, 1), layers: [
        .linear(stops: [(0, (0.8078, 0.9333, 0.6118, 1)), (0.58, (0.702, 0.8706, 0.4627, 1)), (1, (0.702, 0.8549, 0.4941, 1))]),
        .radial(color: (0.6314, 0.8196, 0.3451, 0.72), x: (.center, 0.03), y: (.bottom, 0.2092), radius: 0.9642, yScale: 0.373, falloff: .linear),
        .radial(color: (0.949, 1, 0.8431, 0.22), x: (.tail, 0.45), y: (.top, 0), radius: 1, yScale: 0.36, falloff: .gaussian),
        .radial(color: (0.8745, 1, 0.6745, 0.195), x: (.far, 0.5), y: (.bottom, 0), radius: 0.9, yScale: 0.36, falloff: .gaussian),
        .glow(color: (0.8627, 0.9333, 0.7255, 0.5), width: 5.1179, blur: 1.2308),
        .line(width: 1.2923, stops: [(0, (0.8471, 0.949, 0.7059, 1)), (1, (0.8471, 0.949, 0.7059, 1))]),
        .rim(color: (0.949, 1, 0.8431, 0.53), angle: 50, width: 1.5, blur: 0.75),
        .rim(color: (0.8745, 1, 0.6745, 0.23), angle: 230, width: 1.2, blur: 0.75),
        .line(width: 0.6154, stops: [(0, (0.6314, 0.702, 0.4863, 1)), (1, (0.6314, 0.702, 0.4863, 1))]),
    ])

    private static let outgoingDark = CCSkin(text: (0.9569, 0.9804, 0.9176, 1), layers: [
        .linear(stops: [(0, (0.498, 0.7059, 0.302, 1)), (0.58, (0.3529, 0.5647, 0.1882, 1)), (1, (0.3725, 0.5843, 0.2078, 1))]),
        .radial(color: (0.2784, 0.4784, 0.1333, 0.7), x: (.center, 0.03), y: (.bottom, 0.2092), radius: 0.9642, yScale: 0.373, falloff: .linear),
        .radial(color: (0.8941, 1, 0.7529, 0.081), x: (.tail, 0.45), y: (.top, 0), radius: 1, yScale: 0.36, falloff: .gaussian),
        .radial(color: (0.7255, 0.9098, 0.5098, 0.057), x: (.far, 0.5), y: (.bottom, 0), radius: 0.9, yScale: 0.36, falloff: .gaussian),
        .glow(color: (0.6627, 0.8588, 0.4706, 0.35), width: 5.1179, blur: 1.2308),
        .line(width: 1.2923, stops: [(0, (0.5608, 0.7608, 0.3686, 1)), (1, (0.5608, 0.7608, 0.3686, 1))]),
        .rim(color: (0.8941, 1, 0.7529, 0.092), angle: 50, width: 1.5, blur: 0.75),
        .rim(color: (0.7255, 0.9098, 0.5098, 0.064), angle: 230, width: 1.2, blur: 0.75),
        .line(width: 0.6154, stops: [(0, (0.1843, 0.2902, 0.1098, 1)), (1, (0.1843, 0.2902, 0.1098, 1))]),
    ])

    private static let incomingLight = CCSkin(text: (0.1098, 0.1098, 0.1176, 1), layers: [
        .linear(stops: [(0, (1, 1, 1, 1)), (0.58, (0.9451, 0.949, 0.9569, 1)), (1, (0.9569, 0.9608, 0.9686, 1))]),
        .radial(color: (0.8549, 0.8667, 0.8863, 0.6), x: (.center, 0.03), y: (.bottom, 0.2092), radius: 0.9642, yScale: 0.373, falloff: .linear),
        .radial(color: (1, 1, 1, 0.7), x: (.tail, 0.45), y: (.top, 0), radius: 1, yScale: 0.36, falloff: .gaussian),
        .radial(color: (1, 1, 1, 0.218), x: (.far, 0.5), y: (.bottom, 0), radius: 0.9, yScale: 0.36, falloff: .gaussian),
        .glow(color: (1, 1, 1, 0.6), width: 5.1179, blur: 1.2308),
        .line(width: 1.2923, stops: [(0, (1, 1, 1, 1)), (1, (1, 1, 1, 1))]),
        .rim(color: (1, 1, 1, 1), angle: 50, width: 1.5, blur: 0.75),
        .rim(color: (1, 1, 1, 0.9), angle: 230, width: 1.2, blur: 0.75),
        .line(width: 0.6154, stops: [(0, (0.7059, 0.7255, 0.7569, 1)), (1, (0.7059, 0.7255, 0.7569, 1))]),
    ])

    private static let incomingDark = CCSkin(text: (0.949, 0.949, 0.949, 1), layers: [
        .linear(stops: [(0, (0.2275, 0.2275, 0.2392, 1)), (0.58, (0.1725, 0.1725, 0.1843, 1)), (1, (0.1882, 0.1882, 0.2, 1))]),
        .radial(color: (0.1176, 0.1176, 0.1294, 0.6), x: (.center, 0.03), y: (.bottom, 0.2092), radius: 0.9642, yScale: 0.373, falloff: .linear),
        .radial(color: (1, 0.9529, 0.8863, 0.037), x: (.tail, 0.45), y: (.top, 0), radius: 1, yScale: 0.36, falloff: .gaussian),
        .radial(color: (1, 0.9529, 0.8863, 0.015), x: (.far, 0.5), y: (.bottom, 0), radius: 0.9, yScale: 0.36, falloff: .gaussian),
        .glow(color: (1, 1, 1, 0.08), width: 5.1179, blur: 1.2308),
        .line(width: 1.2923, stops: [(0, (0.2902, 0.2902, 0.3098, 1)), (1, (0.2902, 0.2902, 0.3098, 1))]),
        .rim(color: (1, 0.9529, 0.8863, 0.041), angle: 50, width: 1.5, blur: 0.75),
        .rim(color: (1, 0.9529, 0.8863, 0.027), angle: 230, width: 1.2, blur: 0.75),
        .line(width: 0.6154, stops: [(0, (0.0667, 0.0667, 0.0745, 1)), (1, (0.0667, 0.0667, 0.0745, 1))]),
    ])
}
