/**
 * [INPUT]: 依赖 UIKit 的 UIGlassEffect（iOS 26）与 UIBlurEffect（18.6–25）、SoftGlassShape 的圆 / 胶囊 / 圆角矩形
 * [OUTPUT]: 提供 CCGlassView。UIKit 玻璃面：contentView 放内容，可换形、可着色、可整面退场
 * [POS]: Components 的 UIKit 玻璃。SwiftUI 一侧仍走 ccGlassEffect。按住说话的板与垫用这一件
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import UIKit

/// UIKit 玻璃面。iOS 26 是系统液态玻璃，更早系统是同形的超薄磨砂，着色叠在磨砂上
public final class CCGlassView: UIVisualEffectView {
    public var shape: SoftGlassShape {
        didSet { applyShape() }
    }

    /// nil 不着色
    public var tint: UIColor? {
        didSet {
            guard tint != oldValue, materialized else { return }
            applyEffect()
        }
    }

    /// 关掉后效果清空。iOS 26 在动画块里切换即系统的玻璃退场
    public var materialized = true {
        didSet {
            guard materialized != oldValue else { return }
            if materialized {
                applyEffect()
            } else {
                effect = nil
                contentView.backgroundColor = nil
            }
        }
    }

    public init(shape: SoftGlassShape, tint: UIColor? = nil) {
        self.shape = shape
        self.tint = tint
        super.init(effect: nil)
        isUserInteractionEnabled = false
        applyEffect()
        applyShape()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError() }

    public override func layoutSubviews() {
        super.layoutSubviews()
        if #unavailable(iOS 26) {
            layer.cornerRadius = radius(for: bounds.size)
        }
    }

    private func applyEffect() {
        if #available(iOS 26, *) {
            let glass = UIGlassEffect(style: .regular)
            glass.tintColor = tint
            effect = glass
        } else {
            effect = UIBlurEffect(style: .systemUltraThinMaterial)
            contentView.backgroundColor = tint
        }
    }

    private func applyShape() {
        if #available(iOS 26, *) {
            switch shape {
            case .circle, .capsule:
                cornerConfiguration = .capsule()
            case .roundedRectangle(let radius):
                cornerConfiguration = .corners(radius: .fixed(radius))
            case .unevenRoundedRectangle, .custom:
                cornerConfiguration = .corners(radius: .fixed(24))
            }
        } else {
            clipsToBounds = true
            layer.cornerCurve = .continuous
            layer.cornerRadius = radius(for: bounds.size)
        }
    }

    private func radius(for size: CGSize) -> CGFloat {
        let cap = min(size.width, size.height) / 2
        switch shape {
        case .circle, .capsule:
            return cap
        case .roundedRectangle(let radius):
            return min(radius, cap)
        case .unevenRoundedRectangle, .custom:
            return min(24, cap)
        }
    }
}
