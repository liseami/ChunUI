/**
 * [INPUT]: 依赖 CoreText 排字、Components 的 CCGlassView（玻璃胶囊轨道）、本目录 CCFBTokens.Segment / CCFBFont、CCFeedbackBadge 的 CCFBCountBadge / CCFBCountBadgeView、Color.cc（foreground · mutedForeground）
 * [OUTPUT]: 对内提供 CCFBSegmentItem（标题与计数角标）、CCFBSegmentLayout（量字、注水分宽、横滑居中与两端渐隐）、CCFBSegmentPalette / CCFBSegmentPainter（唯一画法）、
 *           CCFBSegmentView（UIKit 分段栏：按下即换、字后计数角标）与 CCFBSegmentBar（SwiftUI 外壳，Binding 选中）
 * [POS]: Studio/Feedback 的分段控件，逐值移植胃之书 DesignSystem/Root 的 BellySegmented + BellySegmentedPainter（Cromma CCSegmented 极简态 plain）：玻璃胶囊轨道钉在原位，
 *        画布在轨道里的滚动视图上横滑、裁成同一条胶囊、还藏着内容的一端渐隐；选中项垫 foreground × pickTint 的平胶囊，字色在 mutedForeground → foreground 之间。
 *        意见箱不用图标与跟手分页，这两支不移植；其余像素与胃之书一致
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import CoreText
import SwiftUI
import UIKit

struct CCFBSegmentItem: Hashable {
    let id: String
    let title: String
    /// 字后的计数角标；0 即无
    var badge = 0
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 排版：项宽 = 两端内距 + 字宽 + 角标占宽；项从轨道内边（发丝边之内）起紧挨着排
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

final class CCFBSegmentLayout {
    private typealias S = CCFBTokens.Segment

    struct Entry {
        let item: CCFBSegmentItem
        let line: CTLine?
        let textWidth: CGFloat
        let badgeWidth: CGFloat
        let width: CGFloat
    }

    let items: [CCFBSegmentItem]
    let entries: [Entry]
    let height: CGFloat = S.height
    /// 发丝边的实际宽：名义宽按设备像素取整（至少一像素）
    let border: CGFloat
    /// 字的基线（自轨道上沿）：行高 = 字号，上下居中
    let baseline: CGFloat

    init(items: [CCFBSegmentItem], scale: CGFloat) {
        self.items = items
        let px = max(1, scale)
        let bw = max(1, (S.border * px).rounded(.down)) / px
        border = bw
        let font = CCFBFont.ui(S.fontSize, bold: true)
        // 字取上下文填色：画的时候按选中度设色
        let fromContext = NSAttributedString.Key(kCTForegroundColorFromContextAttributeName as String)
        entries = items.map { item in
            let line = item.title.isEmpty ? nil : CTLineCreateWithAttributedString(NSAttributedString(
                string: item.title, attributes: [.font: font, fromContext: true]))
            let tw = line.map { CGFloat(CTLineGetTypographicBounds($0, nil, nil, nil)) } ?? 0
            let bw = item.badge > 0 ? CCFBCountBadge.width(CCFBCountBadge.format(item.badge)) : 0
            let badgeAdvance = bw > 0 ? S.badgeGap + bw : 0
            return Entry(item: item, line: line, textWidth: tw, badgeWidth: bw, width: S.padLeading + tw + badgeAdvance + S.padTrailing)
        }
        let inner = S.height - bw * 2
        let halfLeading = (S.fontSize - (font.ascender - font.descender)) / 2
        baseline = bw + (inner - S.fontSize) / 2 + halfLeading + font.ascender
    }

    /// 文 · 角标共占一组居中
    func textX(_ i: Int, in frame: CGRect) -> CGFloat {
        let e = entries[i]
        let badgeAdvance = e.badgeWidth > 0 ? S.badgeGap + e.badgeWidth : 0
        return frame.midX - e.textWidth / 2 - badgeAdvance / 2
    }

    /// 计数角标的框（画布坐标）：紧跟字后 badgeGap，竖向居中；无角标为 nil
    func badgeRect(_ i: Int, in frame: CGRect) -> CGRect? {
        let e = entries[i]
        guard e.badgeWidth > 0 else { return nil }
        let h = CCFBCountBadge.height
        return CGRect(x: textX(i, in: frame) + e.textWidth + S.badgeGap, y: frame.midY - h / 2, width: e.badgeWidth, height: h)
    }

    /// 摆在 width 宽的轨道里：各项分这条宽（注水法），放不下就按自然宽、由外壳横滑
    func frames(fillingWidth width: CGFloat?) -> [CGRect] {
        let ws = Self.widths(natural: entries.map(\.width), available: width.map { $0 - border * 2 })
        var x = border
        let inner = height - border * 2
        return ws.map { w in
            defer { x += w }
            return CGRect(x: x, y: border, width: w, height: inner)
        }
    }

    /// 内容宽：填满时不窄于给的宽，否则是自然宽
    func contentWidth(fillingWidth width: CGFloat?) -> CGFloat {
        max(entries.map(\.width).reduce(border * 2, +), width ?? 0)
    }

    /// 分宽（注水法）：自然宽之和放不下就原样；放得下先均分，比均分份宽的项保住自然宽、余下的在其余项里再均分
    static func widths(natural: [CGFloat], available: CGFloat?) -> [CGFloat] {
        guard let available, !natural.isEmpty, natural.reduce(0, +) < available else { return natural }
        var fixed = Set<Int>()
        while true {
            let rest = available - fixed.reduce(0) { $0 + natural[$1] }
            let share = rest / CGFloat(natural.count - fixed.count)
            let wider = natural.indices.filter { !fixed.contains($0) && natural[$0] > share }
            guard !wider.isEmpty else {
                return natural.indices.map { fixed.contains($0) ? natural[$0] : share }
            }
            fixed.formUnion(wider)
        }
    }

    /// 选中项滚进视野：滑块居中，夹在内容两端之间
    static func focusOffset(thumbMidX: CGFloat, viewport: CGFloat, content: CGFloat) -> CGFloat {
        max(0, min(content - viewport, (thumbMidX - viewport / 2).rounded(.down)))
    }

    /// 两端渐隐的浓度 0–1：那一端还藏着多少内容，在渐隐宽 fade 之内线性长出
    static func fades(offset: CGFloat, viewport: CGFloat, content: CGFloat, fade: CGFloat) -> (leading: CGFloat, trailing: CGFloat) {
        guard fade > 0 else { return (0, 0) }
        let rest = max(0, content - viewport - offset)
        return (max(0, min(1, offset / fade)), max(0, min(1, rest / fade)))
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 调色与画法：裁到轨道内边 → 滑块（平胶囊）→ 字
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct CCFBSegmentPalette {
    typealias RGBA = (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat)

    var foreground: RGBA
    var muted: RGBA

    static func resolved(_ traits: UITraitCollection) -> CCFBSegmentPalette {
        func rgba(_ color: Color) -> RGBA {
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            UIColor(color).resolvedColor(with: traits).getRed(&r, green: &g, blue: &b, alpha: &a)
            return (r, g, b, a)
        }
        return CCFBSegmentPalette(foreground: rgba(Color.cc.foreground), muted: rgba(Color.cc.mutedForeground))
    }

    static func mix(_ a: RGBA, _ b: RGBA, _ t: CGFloat) -> RGBA {
        (a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, a.a + (b.a - a.a) * t)
    }

    static func cg(_ c: RGBA, alpha: CGFloat = 1) -> CGColor {
        let space = CGColorSpace(name: CGColorSpace.extendedSRGB) ?? CGColorSpaceCreateDeviceRGB()
        return CGColor(colorSpace: space, components: [c.r, c.g, c.b, c.a * alpha]) ?? UIColor.clear.cgColor
    }
}

enum CCFBSegmentPainter {
    private typealias S = CCFBTokens.Segment

    /// 滑块框：项框四周缩到离轨道外沿 thumbInset，胶囊与轨道同心
    static func thumbRect(_ frame: CGRect) -> CGRect {
        let extra = S.thumbInset - frame.minY
        return frame.insetBy(dx: extra, dy: extra)
    }

    static func capsule(_ rect: CGRect) -> CGPath {
        let r = min(rect.width, rect.height) / 2
        return CGPath(roundedRect: rect, cornerWidth: r, cornerHeight: r, transform: nil)
    }

    /// ctx 是 UIKit 的上下翻转坐标，原点在轨道左上；trackWidth 是整排内容宽
    static func draw(in ctx: CGContext, layout: CCFBSegmentLayout, frames: [CGRect], trackWidth: CGFloat, thumb: CGRect, selected: Int, palette p: CCFBSegmentPalette) {
        let bw = layout.border
        let inner = CGRect(x: 0, y: 0, width: trackWidth, height: layout.height).insetBy(dx: bw, dy: bw)
        ctx.saveGState()
        ctx.addPath(capsule(inner))
        ctx.clip()

        if thumb.width > 0 {
            ctx.addPath(capsule(thumb))
            ctx.setFillColor(CCFBSegmentPalette.cg(p.foreground, alpha: S.pickTint))
            ctx.fillPath()
        }

        for (i, e) in layout.entries.enumerated() where i < frames.count {
            guard let line = e.line else { continue }
            let t: CGFloat = i == selected ? 1 : 0
            ctx.saveGState()
            ctx.textMatrix = CGAffineTransform(scaleX: 1, y: -1)
            ctx.setFillColor(CCFBSegmentPalette.cg(CCFBSegmentPalette.mix(p.muted, p.foreground, t)))
            ctx.textPosition = CGPoint(x: layout.textX(i, in: frames[i]), y: layout.baseline)
            CTLineDraw(line, ctx)
            ctx.restoreGState()
        }
        ctx.restoreGState()
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - UIKit 外壳：玻璃轨道钉在原位；画布在其内的滚动视图里横滑，裁成轨道那条胶囊、两端渐隐
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

final class CCFBSegmentView: UIView, UIScrollViewDelegate {
    private typealias S = CCFBTokens.Segment

    /// 按下了第几项
    var onSelect: ((Int) -> Void)?
    private(set) var selectedIndex = 0
    private(set) var layout: CCFBSegmentLayout?

    private let glass = CCGlassView(shape: .capsule)
    private let clip = UIView()
    private let clipShape = CAShapeLayer()
    private let fader = UIView()
    private let fadeMask = CAGradientLayer()
    private let scroller = UIScrollView()
    private let canvas = Canvas()
    private var badges: [CCFBCountBadgeView] = []
    /// 这一次按下已换项并报过 onSelect：随后的轻点不再报
    private var pressSwitched = false
    private var frames: [CGRect] = []
    private var trackWidth: CGFloat = 0
    private var contentWidth: CGFloat = 0
    private var thumb: CGRect = .zero
    private var palette: CCFBSegmentPalette?
    /// 视野跟着滑块走；用户自己拖开内容就不再跟，直到下一次选中
    private var follows = true

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(glass)
        clip.layer.mask = clipShape
        addSubview(clip)
        fadeMask.startPoint = CGPoint(x: 0, y: 0.5)
        fadeMask.endPoint = CGPoint(x: 1, y: 0.5)
        fader.layer.mask = fadeMask
        clip.addSubview(fader)
        scroller.showsHorizontalScrollIndicator = false
        scroller.showsVerticalScrollIndicator = false
        scroller.alwaysBounceHorizontal = false
        scroller.scrollsToTop = false
        scroller.contentInsetAdjustmentBehavior = .never
        // 按下即换：画布要在按下那一刻收到触摸
        scroller.delaysContentTouches = false
        scroller.delegate = self
        fader.addSubview(scroller)
        canvas.isOpaque = false
        canvas.contentMode = .redraw
        canvas.owner = self
        scroller.addSubview(canvas)
        canvas.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped(_:))))
        isAccessibilityElement = false
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: CCFBSegmentView, _: UITraitCollection) in
            view.palette = nil
            view.canvas.setNeedsDisplay()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        CGSize(width: size.width, height: S.height)
    }

    /// 换一排项；selected 越界时落到 0，视野回到跟着选中项
    func setItems(_ items: [CCFBSegmentItem], selected: Int) {
        layout = CCFBSegmentLayout(items: items, scale: max(1, traitCollection.displayScale))
        selectedIndex = items.indices.contains(selected) ? selected : 0
        follows = true
        relayout()
        settle()
    }

    /// 换项：滑块、字色与视野当帧落定（极简态不做动画）
    func select(_ index: Int) {
        guard let layout, layout.items.indices.contains(index) else { return }
        selectedIndex = index
        follows = true
        relayout()
        settle()
    }

    private func settle() {
        thumb = frames.indices.contains(selectedIndex) ? CCFBSegmentPainter.thumbRect(frames[selectedIndex]) : .zero
        focus(on: thumb)
        canvas.setNeedsDisplay()
        updateAccessibility()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        relayout()
        if frames.indices.contains(selectedIndex) {
            thumb = CCFBSegmentPainter.thumbRect(frames[selectedIndex])
            focus(on: thumb)
        }
    }

    /// 轨道恒占本视图整宽，各项按注水法分宽；放不下即横滑
    private func relayout() {
        guard let layout else { return }
        let oldFrames = frames
        trackWidth = bounds.width
        contentWidth = layout.contentWidth(fillingWidth: bounds.width)
        frames = layout.frames(fillingWidth: bounds.width)
        let track = CGRect(x: 0, y: (bounds.height - layout.height) / 2, width: trackWidth, height: layout.height)
        glass.frame = track
        clip.frame = track
        fader.frame = clip.bounds
        scroller.frame = fader.bounds
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        clipShape.frame = clip.bounds
        clipShape.path = CCFBSegmentPainter.capsule(clip.bounds)
        fadeMask.frame = fader.bounds
        CATransaction.commit()
        canvas.frame = CGRect(x: 0, y: 0, width: contentWidth, height: layout.height)
        scroller.contentSize = canvas.frame.size
        let maxX = max(0, contentWidth - trackWidth)
        if scroller.contentOffset.x > maxX { scroller.contentOffset.x = maxX }
        updateFades()
        placeBadges()
        canvas.setNeedsDisplay()
        if frames != oldFrames { updateAccessibility() }
    }

    /// 角标框取 badgeRect（画布在滚动视图原点，画布坐标即滚动内容坐标）；没有角标的项收起
    private func placeBadges() {
        guard let layout else { return }
        while badges.count < layout.items.count {
            let badge = CCFBCountBadgeView()
            scroller.addSubview(badge)
            badges.append(badge)
        }
        for (i, badge) in badges.enumerated() {
            guard frames.indices.contains(i), let r = layout.badgeRect(i, in: frames[i]) else {
                badge.set(0)
                continue
            }
            badge.set(layout.items[i].badge)
            badge.frame = r
        }
    }

    private func focus(on rect: CGRect) {
        guard follows else { return }
        scroller.contentOffset.x = CCFBSegmentLayout.focusOffset(thumbMidX: rect.midX, viewport: trackWidth, content: contentWidth)
    }

    /// 两端渐隐：渐隐宽 = 轨道高 × fade，浓度随那一端藏着的内容长出
    private func updateFades() {
        let width = S.height * S.fade
        let f = CCFBSegmentLayout.fades(offset: scroller.contentOffset.x, viewport: trackWidth, content: contentWidth, fade: width)
        let edge = trackWidth > 0 ? min(0.5, width / trackWidth) : 0
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        fadeMask.colors = [1 - f.leading, 1, 1, 1 - f.trailing].map { UIColor.black.withAlphaComponent($0).cgColor }
        fadeMask.locations = [0, edge, 1 - edge, 1].map { NSNumber(value: Double($0)) }
        CATransaction.commit()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateFades()
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        follows = false
    }

    // ━━━ 触摸：按下别的项即换（不等抬起）；按下当前项等抬手的轻点报 ━━━

    @objc private func tapped(_ g: UITapGestureRecognizer) {
        if pressSwitched { return }
        guard let i = index(at: g.location(in: canvas).x) else { return }
        if i != selectedIndex { select(i) }
        onSelect?(i)
    }

    fileprivate func pressed(_ touches: Set<UITouch>) {
        guard let touch = touches.first else { return }
        pressSwitched = false
        guard let i = index(at: touch.location(in: canvas).x), i != selectedIndex else { return }
        pressSwitched = true
        select(i)
        onSelect?(i)
    }

    private func index(at x: CGFloat) -> Int? {
        frames.firstIndex { x >= $0.minX && x < $0.maxX }
    }

    fileprivate func paint(_ ctx: CGContext) {
        guard let layout else { return }
        let p = palette ?? CCFBSegmentPalette.resolved(traitCollection)
        palette = p
        CCFBSegmentPainter.draw(in: ctx, layout: layout, frames: frames, trackWidth: contentWidth, thumb: thumb, selected: selectedIndex, palette: p)
    }

    private func updateAccessibility() {
        guard let layout else { return }
        canvas.accessibilityElements = layout.items.enumerated().map { i, item in
            let el = UIAccessibilityElement(accessibilityContainer: canvas)
            el.accessibilityLabel = item.badge > 0 ? "\(item.title), \(item.badge)" : item.title
            el.accessibilityTraits = i == selectedIndex ? [.button, .selected] : .button
            if frames.indices.contains(i) { el.accessibilityFrameInContainerSpace = frames[i] }
            return el
        }
    }

    /// 画布：宽 = 内容宽、高 = 轨道高
    private final class Canvas: UIView {
        weak var owner: CCFBSegmentView?

        override func draw(_ rect: CGRect) {
            guard let ctx = UIGraphicsGetCurrentContext() else { return }
            owner?.paint(ctx)
        }

        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            super.touchesBegan(touches, with: event)
            owner?.pressed(touches)
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - SwiftUI 外壳：项变了整排重排（角标数变也是），选中经 Binding 双向
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct CCFBSegmentBar: UIViewRepresentable {
    let items: [CCFBSegmentItem]
    @Binding var selection: Int

    func makeUIView(context: Context) -> CCFBSegmentView {
        let view = CCFBSegmentView()
        view.setItems(items, selected: selection)
        return view
    }

    func updateUIView(_ view: CCFBSegmentView, context: Context) {
        view.onSelect = { i in if selection != i { selection = i } }
        if view.layout?.items != items {
            view.setItems(items, selected: selection)
        } else if view.selectedIndex != selection {
            view.select(selection)
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: CCFBSegmentView, context: Context) -> CGSize? {
        CGSize(width: proposal.width ?? 0, height: CCFBTokens.Segment.height)
    }
}
