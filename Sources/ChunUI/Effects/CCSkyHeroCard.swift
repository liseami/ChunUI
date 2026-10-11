/**
 * [INPUT]: 依赖 Color.cc.foreground/border、SwiftUI TimelineView
 * [OUTPUT]: 对外提供 CCSkyHeroCard / CCSkyHeroBackdrop——Cromma 官网首屏卡：圆上角、点阵（步长 10pt / 原点 5pt / 圆 1.8pt，前景 0.28）+ 天蓝极光（blur 56 / multiply）；无体积云；侧栏跟手时暂停，不降效果
 * [POS]: Effects 的落地/首页英雄卡。色锁定 Cromma 蓝（#3B6CFF）与天色，不走宿主 primary（Zinner 粉会把极光染错）
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI

public struct CCSkyHeroCard<Content: View>: View {
    var height: CGFloat
    var content: () -> Content

    public init(height: CGFloat = 300, @ViewBuilder content: @escaping () -> Content) {
        self.height = height
        self.content = content
    }

    public var body: some View {
        let shape = UnevenRoundedRectangle(
            topLeadingRadius: 24,
            bottomLeadingRadius: 0,
            bottomTrailingRadius: 0,
            topTrailingRadius: 24,
            style: .continuous
        )
        ZStack {
            CCSkyHeroBackdrop()
            content()
            shape
                .strokeBorder(Color.cc.border, lineWidth: 1)
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .black, location: 0),
                            .init(color: .black, location: 0.12),
                            .init(color: .clear, location: 1),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipShape(shape)
    }
}

/// 点阵 + 极光。侧边栏跟手时由 ccAtmospherePaused 停 TimelineView；列表 Store 刷新不得拆氛围层。
public struct CCSkyHeroBackdrop: View {
    public init() {}

    public var body: some View {
        ZStack {
            SkyDotGrid()
                .mask(Self.fadeMask(dots: true))
            SkyAurora()
                .blendMode(.multiply)
                .mask(Self.fadeMask(dots: false))
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// 点阵 + 极光两层，无体积云。点阵 0%→45% 60%→85% 透；极光 0–34% 实、62% 70%、86% 22%、底透（与 Cromma .aurora-fade / .dot-grid 同构）
    static func fadeMask(dots: Bool) -> some View {
        LinearGradient(
            stops: dots
                ? [
                    .init(color: .black, location: 0),
                    .init(color: .black.opacity(0.6), location: 0.45),
                    .init(color: .clear, location: 0.85),
                ]
                : [
                    .init(color: .black, location: 0),
                    .init(color: .black, location: 0.34),
                    .init(color: .black.opacity(0.7), location: 0.62),
                    .init(color: .black.opacity(0.22), location: 0.86),
                    .init(color: .clear, location: 1),
                ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Cromma 蓝 / 天色（oklch 0.58 0.2 262 / 0.937 0.028 250）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

private enum SkyChrome {
    static let primary = Color(red: 0.231, green: 0.424, blue: 1.0)
    static let sky = Color(red: 0.894, green: 0.937, blue: 0.973)
}

private struct SkyDotGrid: View {
    var body: some View {
        Canvas { context, size in
            let color = Color.cc.foreground.opacity(0.28)
            var x: CGFloat = 5
            while x < size.width {
                var y: CGFloat = 5
                while y < size.height {
                    context.fill(Path(ellipseIn: CGRect(x: x - 0.9, y: y - 0.9, width: 1.8, height: 1.8)), with: .color(color))
                    y += 10
                }
                x += 10
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct SkyAurora: View {
    private let curtains: [(left: CGFloat, width: CGFloat, dur: Double, delay: Double)] = [
        (0.06, 0.15, 7, 0),
        (0.22, 0.11, 8.5, -3),
        (0.38, 0.20, 9.5, -1.5),
        (0.58, 0.13, 7.5, -5),
        (0.74, 0.17, 9, -4),
        (0.90, 0.10, 6.5, -6),
    ]

    @Environment(\.ccAtmospherePaused) private var atmospherePaused
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: atmospherePaused || reduceMotion)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                ZStack(alignment: .topLeading) {
                    wash(t: t)
                        .frame(width: w * 2, height: h * 2)
                        .position(x: w / 2, y: h / 2)
                    ForEach(Array(curtains.enumerated()), id: \.offset) { _, c in
                        beam(t: t, dur: c.dur, delay: c.delay)
                            .frame(width: w * c.width, height: h * 1.2)
                            .offset(x: w * c.left, y: -h * 0.10)
                    }
                    sheet(t: t)
                        .frame(width: w * 0.66, height: h)
                        .offset(x: -w * 0.33)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func wash(t: TimeInterval) -> some View {
        let spin = (t.truncatingRemainder(dividingBy: 12) / 12) * 360
        return AngularGradient(
            colors: [
                SkyChrome.primary.opacity(0.70),
                .clear,
                SkyChrome.primary.mix(with: SkyChrome.sky, amount: 0.25).opacity(0.75),
                .clear,
                SkyChrome.sky.mix(with: SkyChrome.primary, amount: 0.30).opacity(0.70),
                .clear,
                SkyChrome.primary.opacity(0.70),
            ],
            center: .center
        )
        .rotationEffect(.degrees(spin))
        .blur(radius: 56)
        .saturation(1.35)
    }

    private func beam(t: TimeInterval, dur: Double, delay: Double) -> some View {
        let phase = (t + delay).truncatingRemainder(dividingBy: dur * 2)
        let k = phase < dur ? phase / dur : 2 - phase / dur
        let x = CGFloat(k * 2 - 1) * 0.18
        return LinearGradient(
            colors: [
                SkyChrome.primary.mix(with: SkyChrome.sky, amount: 0.10).opacity(0.90),
                SkyChrome.primary.opacity(0.45),
                .clear,
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .blur(radius: 22)
        .rotationEffect(.degrees(-6), anchor: .top)
        .offset(x: x * 80)
    }

    private func sheet(t: TimeInterval) -> some View {
        let k = (sin(t * .pi / 2) + 1) / 2
        return LinearGradient(
            colors: [
                .clear,
                SkyChrome.sky.opacity(0.90),
                .clear,
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .opacity(0.7)
        .offset(x: CGFloat(k * 2 - 1) * 120)
    }
}

#Preview("极光卡") {
    ScrollView {
        CCSkyHeroCard {
            Text("金刚区")
                .font(.cc.title2Bold)
                .foregroundStyle(Color.cc.foreground)
        }
        .padding(.horizontal, 8)
        Color.cc.background.frame(height: 400)
    }
    .background(Color.cc.background)
}
