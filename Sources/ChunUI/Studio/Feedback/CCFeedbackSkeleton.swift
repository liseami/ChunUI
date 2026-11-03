/**
 * [INPUT]: 依赖 Core Animation（CAGradientLayer 带层 + transform.translation.x 平移）、本目录 CCFBTokens.Bone、Color.cc 的 skeleton 底与 foreground 高光
 * [OUTPUT]: 对内提供 CCFBBoneView（一块 UIKit 骨架）、CCFBBone（条 · 块 · 圆）、CCFBBoneText（多行段落）与 CCFBBoneGated（门槛与淡换：等待 → 骨架 → 内容）
 * [POS]: Studio/Feedback 的骨架，逐值移植胃之书 DesignSystem/Skeleton（BellySkeletonView / BellyBone / BellyBoneText / BellySkeletonGated + BellyShimmer 的带与平移）：
 *        只动 transform（渲染服务里跑、主线程零帧），每块随机时长 1.3–1.7 s 与负延迟，离窗即摘、进窗再挂，Reduce Motion 静止；数据 0.3 s 内到不出骨架，出过才 0.2 s 淡换。
 *        包里的 CCBone 是 TimelineView 逐帧画的另一套，像素不同，意见箱不用它
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI
import UIKit

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 一块骨架（UIKit）：底色 + 一条高光带的图层平移
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

final class CCFBBoneView: UIView {
    private typealias M = CCFBTokens.Bone
    private static let key = "ccfb.skeleton.sweep"

    enum Shape: Equatable {
        case block(radius: CGFloat)
        case circle
    }

    var shape: Shape {
        didSet { if shape != oldValue { setNeedsLayout() } }
    }

    /// 扫一趟的秒数与负延迟：挂载时抽一次，同屏不同步闪
    private let duration: Double
    private let delay: Double
    private let band = CAGradientLayer()
    private var sweptWidth: CGFloat = -1

    init(shape: Shape) {
        self.shape = shape
        let d = M.durationMin + (M.durationMax - M.durationMin) * Double.random(in: 0 ..< 1)
        duration = d
        delay = -Double.random(in: 0 ..< 1) * d
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        accessibilityElementsHidden = true
        layer.masksToBounds = true
        layer.cornerCurve = .continuous
        band.startPoint = CGPoint(x: 0, y: 0.5)
        band.endPoint = CGPoint(x: 1, y: 0.5)
        band.locations = [0, 0.5, 1]
        layer.addSublayer(band)
        resolveColors()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (v: CCFBBoneView, _: UITraitCollection) in v.resolveColors() }
        NotificationCenter.default.addObserver(self, selector: #selector(motionChanged), name: UIAccessibility.reduceMotionStatusDidChangeNotification, object: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    /// 底是 Color.cc.skeleton；高光是 foreground 在带中央的不透明度，暗色更收敛
    private func resolveColors() {
        let t = traitCollection
        let peak = t.userInterfaceStyle == .dark ? M.peakDark : M.peakLight
        backgroundColor = UIColor(Color.cc.skeleton).resolvedColor(with: t)
        let fg = UIColor(Color.cc.foreground).resolvedColor(with: t)
        band.colors = [fg.withAlphaComponent(0).cgColor, fg.withAlphaComponent(peak).cgColor, fg.withAlphaComponent(0).cgColor]
    }

    /// 高光带的平移：带宽 = 元素宽 × band，带心从元素中心左移 (元素宽 + 带宽) ÷ 2 走到右移同样多
    private static func travel(width: CGFloat) -> (band: CGFloat, from: CGFloat, to: CGFloat) {
        let b = max(0, width * M.band)
        let t = (max(0, width) + b) / 2
        return (b, -t, t)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let b = bounds
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        switch shape {
        case .block(let r): layer.cornerRadius = min(r, min(b.width, b.height) / 2)
        case .circle: layer.cornerRadius = min(b.width, b.height) / 2
        }
        let travel = Self.travel(width: b.width)
        band.bounds = CGRect(x: 0, y: 0, width: travel.band, height: b.height)
        band.position = CGPoint(x: b.midX, y: b.midY)
        CATransaction.commit()
        if b.width != sweptWidth { sweep() }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        // 离窗即摘，进窗再挂
        if window == nil {
            band.removeAnimation(forKey: Self.key)
            sweptWidth = -1
        } else if band.animation(forKey: Self.key) == nil {
            sweep()
        }
    }

    @objc private func motionChanged() { sweep() }

    /// 挂扫光：渲染服务里的图层平移；Reduce Motion 下不扫也不留高光
    private func sweep() {
        band.removeAnimation(forKey: Self.key)
        sweptWidth = bounds.width
        let still = window == nil || UIAccessibility.isReduceMotionEnabled || bounds.width <= 0
        band.isHidden = still
        guard !still else { return }
        let t = Self.travel(width: bounds.width)
        let e = M.sweep
        let a = CABasicAnimation(keyPath: "transform.translation.x")
        a.fromValue = t.from
        a.toValue = t.to
        a.duration = duration
        a.timingFunction = CAMediaTimingFunction(controlPoints: Float(e.0), Float(e.1), Float(e.2), Float(e.3))
        a.repeatCount = .infinity
        a.isRemovedOnCompletion = false
        // 负延迟：从相位处起跑，挂上即在扫光中途
        a.beginTime = band.convertTime(CACurrentMediaTime() + delay, from: nil)
        band.add(a, forKey: Self.key)
    }
}

private struct CCFBBoneRepresentable: UIViewRepresentable {
    let shape: CCFBBoneView.Shape

    func makeUIView(context: Context) -> CCFBBoneView { CCFBBoneView(shape: shape) }
    func updateUIView(_ view: CCFBBoneView, context: Context) { view.shape = shape }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - SwiftUI 外壳
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// 一块骨架：width 为 nil 即吃满可用宽；circle 时边长取 height
struct CCFBBone: View {
    private let width: CGFloat?
    private let height: CGFloat
    private let shape: CCFBBoneView.Shape

    init(width: CGFloat? = nil, height: CGFloat = CCFBTokens.Bone.line, radius: CGFloat = CCFBTokens.Bone.lineRadius, circle: Bool = false) {
        self.width = circle ? height : width
        self.height = height
        self.shape = circle ? .circle : .block(radius: radius)
    }

    var body: some View {
        CCFBBoneRepresentable(shape: shape)
            .frame(width: width, height: height)
            .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)
    }
}

/// 多行段落骨架：一行走 [widthMin, widthMax]；多行时非末行 [bodyMin, 1]、末行 [lastMin, lastMax]；每实例挂载抽一次
struct CCFBBoneText: View {
    private typealias M = CCFBTokens.Bone
    private let ratios: [CGFloat]

    init(lines: Int) {
        let n = max(1, lines)
        func lerp(_ lo: CGFloat, _ hi: CGFloat) -> CGFloat { lo + (hi - lo) * CGFloat(Double.random(in: 0 ..< 1)) }
        ratios = n == 1 ? [lerp(M.widthMin, M.widthMax)] : (0 ..< n).map { $0 == n - 1 ? lerp(M.lastMin, M.lastMax) : lerp(M.bodyMin, 1) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: M.textGap) {
            ForEach(ratios.indices, id: \.self) { i in
                GeometryReader { geo in
                    CCFBBone(width: geo.size.width * ratios[i], height: M.line)
                }
                .frame(height: M.line)
            }
        }
    }
}

/// 门槛与淡换：loading 时先等 gate，过了才出骨架；loading 落下时骨架出过才淡换（fade），门槛内到的直接换上
struct CCFBBoneGated<Content: View, Bones: View>: View {
    private let loading: Bool
    private let content: () -> Content
    private let bones: () -> Bones
    @State private var armed = false

    init(loading: Bool, @ViewBuilder content: @escaping () -> Content, @ViewBuilder bones: @escaping () -> Bones) {
        self.loading = loading
        self.content = content
        self.bones = bones
    }

    var body: some View {
        ZStack(alignment: .top) {
            if !loading {
                content().transition(.opacity)
            } else if armed {
                bones()
                    .accessibilityHidden(true)
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: armed ? CCFBTokens.Bone.fade : 0), value: loading)
        .task(id: loading) {
            guard loading else { return }
            armed = false
            try? await Task.sleep(for: .seconds(CCFBTokens.Bone.gate))
            if !Task.isCancelled { armed = true }
        }
    }
}
