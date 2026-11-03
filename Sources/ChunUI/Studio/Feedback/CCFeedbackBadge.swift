/**
 * [INPUT]: 依赖 Components 的 CCGlassView（危险色着色的系统玻璃胶囊）、本目录 CCFBTokens.Badge、CoreText 量字、Color.cc 的 destructive / destructiveForeground
 * [OUTPUT]: 对内提供 CCFBCountBadge（格式化、量宽，纯函数）与 CCFBCountBadgeView（UIKit：玻璃胶囊 + 等宽数字，不接触摸）；对外提供 CCCountBadge（SwiftUI 角标，0 即不出）与 View.ccCountBadge(_:)（入口钮右上的胃之书摆法）
 * [POS]: Studio/Feedback 的数字角标，逐值移植胃之书 DesignSystem/Root 的 BellyCountBadge（Cromma CCCountBadge 未静音态）：着危险色的系统玻璃胶囊、白色等宽粗体数字、至少正圆、千起写 k。
 *        意见箱「解决」分段与宿主的反馈入口钮共用这一枚；宿主只摆位置
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import CoreText
import SwiftUI
import UIKit

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 纯函数：格式化、量宽
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

enum CCFBCountBadge {
    private typealias B = CCFBTokens.Badge

    static var height: CGFloat { B.height }

    /// 等宽数字、粗体
    static var font: UIFont { UIFont.monospacedDigitSystemFont(ofSize: B.fontSize, weight: .bold) }

    /// 1–999 原样；千起写 k、百万起写 m，不足 10 个单位留一位小数、一律截断不进位；0 与负数是空串
    static func format(_ n: Int) -> String {
        guard n > 0 else { return "" }
        guard n >= 1000 else { return "\(n)" }
        let (base, unit) = n < 1_000_000 ? (1000, "k") : (1_000_000, "m")
        let v = min(n, 999 * 1_000_000 + 999_999)
        guard v < base * 10 else { return "\(min(999, v / base))\(unit)" }
        let tenths = v / (base / 10)
        return tenths % 10 == 0 ? "\(tenths / 10)\(unit)" : "\(tenths / 10).\(tenths % 10)\(unit)"
    }

    /// 一枚角标的宽：字宽 + 两侧 padH，至少是正圆
    static func width(_ text: String) -> CGFloat {
        guard !text.isEmpty else { return B.height }
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: [.font: font]))
        return max(B.height, ceil(CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))) + B.padH * 2)
    }

    static func size(_ text: String) -> CGSize { CGSize(width: width(text), height: B.height) }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - UIKit：一块着危险色的系统玻璃胶囊 + 居中的等宽数字；不接触摸，0 即藏起
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

final class CCFBCountBadgeView: UIView {
    private let glass = CCGlassView(shape: .capsule, tint: UIColor(Color.cc.destructive))
    private let label = UILabel()
    private(set) var count = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        isHidden = true
        label.font = CCFBCountBadge.font
        label.textAlignment = .center
        label.textColor = UIColor(Color.cc.destructiveForeground)
        addSubview(glass)
        glass.contentView.addSubview(label)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    /// 换数只改字；尺寸由摆放方按 CCFBCountBadge.size 给
    func set(_ count: Int) {
        guard count != self.count else { return }
        self.count = max(0, count)
        isHidden = self.count == 0
        label.text = CCFBCountBadge.format(self.count)
        accessibilityLabel = isHidden ? nil : "\(self.count)"
        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }

    var text: String { CCFBCountBadge.format(count) }

    override var intrinsicContentSize: CGSize { count > 0 ? CCFBCountBadge.size(text) : .zero }
    override func sizeThatFits(_ size: CGSize) -> CGSize { intrinsicContentSize }

    override func layoutSubviews() {
        super.layoutSubviews()
        glass.frame = bounds
        label.frame = glass.contentView.bounds
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - SwiftUI：宿主入口钮上的角标（同一块 UIKit 玻璃），0 即不出、不占位
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct CCCountBadge: View {
    private let count: Int

    public init(_ count: Int) {
        self.count = count
    }

    public var body: some View {
        if count > 0 {
            CCFBCountBadgeRepresentable(count: count)
                .frame(width: CCFBCountBadge.width(CCFBCountBadge.format(count)), height: CCFBCountBadge.height)
                .accessibilityLabel("\(count)")
        }
    }
}

public extension View {
    /// 入口钮右上的计数角标（胃之书坞上反馈钮的摆法）：角标左端半圆的圆心落在钮右上角向内 9 处，约一半压出钮外沿，数字多了向右长；0 即不出
    func ccCountBadge(_ count: Int) -> some View {
        overlay(alignment: .topTrailing) {
            CCCountBadge(count)
                .alignmentGuide(.trailing) { _ in CCFBCountBadge.height / 2 + CCFBTokens.Badge.inset }
                .alignmentGuide(.top) { _ in CCFBCountBadge.height / 2 - CCFBTokens.Badge.inset }
                .allowsHitTesting(false)
        }
    }
}

private struct CCFBCountBadgeRepresentable: UIViewRepresentable {
    let count: Int

    func makeUIView(context: Context) -> CCFBCountBadgeView {
        let view = CCFBCountBadgeView()
        view.set(count)
        return view
    }

    func updateUIView(_ view: CCFBCountBadgeView, context: Context) { view.set(count) }
}
