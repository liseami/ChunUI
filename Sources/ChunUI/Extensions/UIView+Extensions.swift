/**
 * [INPUT]: 依赖 UIKit 的 UIView 与 QuartzCore 的 CAMediaTimingFunction
 * [OUTPUT]: 对外提供 UIView.frameInWindow（窗口坐标系下的 frame）；包内提供带自定义时间曲线的 UIView.animate 封装
 * [POS]: Extensions 的视图工具；转场动画按它取屏幕绝对位置
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

extension UIView {
    /// This computed property converts a view's frame to window coordinates.
    /// We do this because we need to know the exact position of a view in the
    /// window's coordinate space (i.e. the physical screen), not just its local superview.
    ///
    public var frameInWindow: CGRect? {
        superview?.convert(frame, to: nil)
    }

    /// UIView.animate 的便捷封装，支持自定义 CAMediaTimingFunction 时间曲线
    static func animate(
        duration: TimeInterval,
        curve: CAMediaTimingFunction? = nil,
        options: UIView.AnimationOptions = [],
        animations: @escaping () -> Void,
        completion: (() -> Void)? = nil
    ) {
        // Begin CATransaction to set timing curve
        CATransaction.begin()
        CATransaction.setAnimationTimingFunction(curve)
        
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: options,
            animations: animations,
            completion: { _ in completion?() }
        )
        
        // Commit the transaction
        CATransaction.commit()
    }
}
