/**
 * [INPUT]: 依赖 CCPresentationAnchor 的窗口发现（CCNativeSheet.swift）
 * [OUTPUT]: 对外提供 CCNav.pop —— 包内组件（返回钮等）的导航返回唯一出口；包内提供 CCNav.present(_:from:animated:completion:) —— 包内 UIKit 模态（相机、相册、视频、分享、商店页）的唯一呈现口
 * [POS]: Presentation 的导航薄门面；包不持有宿主导航栈，只经关键窗口就地发现。升起点由调用方给出，各组件原有的锚点规则不变
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */
import UIKit

public enum CCNav {
    /// 就地发现最顶层导航栈并 pop；无可弹页时降级 dismiss 最顶 modal
    public static func pop() {
        guard let top = CCPresentationAnchor.topmost() else { return }
        if let nav = top.navigationController ?? top as? UINavigationController,
           nav.viewControllers.count > 1 {
            nav.popViewController(animated: true)
        } else {
            top.dismiss(animated: true)
        }
    }

    /// 包内 UIKit 模态从 presenter 升起：组件不得自己调 present(_:animated:)
    static func present(_ controller: UIViewController, from presenter: UIViewController, animated: Bool = true, completion: (() -> Void)? = nil) {
        presenter.present(controller, animated: animated, completion: completion)
    }
}

/// 相册选图「最近创建时间」包内记忆（原宿主 MainViewModel 寄存字段的就地替身）
public enum CCPhotoSelectMemory {
    nonisolated(unsafe) public static var lastCreatedTime: Date?
}
