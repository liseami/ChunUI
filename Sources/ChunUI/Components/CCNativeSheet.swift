/**
 * [INPUT]: 依赖 HotReloadHosting、Color.cc、UIKit UISheetPresentationController、AppHelper.showBottomAlert（未保存三选一）
 * [OUTPUT]: 对外提供 CCSheetConfig（含 .profile 磨砂 / extendsToBottomEdge 吃穿底安全区；zoomSourceID + .zoom(from:) 锚点转场）/ CCEditSheetContext / CCPresentationAnchor / CCNativeSheetController
 * [POS]: DesignSystem 原生 pageSheet 真相源；frosted = 单层 UIBlurEffect.systemMaterial；出口 AppHelper.presentSheet（zoomSourceID 由其装配 CCZoom.transition）；脏态下拉确认走 CCBottomAlert，禁止 UIAlertController
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI
import UIKit
import ObjectiveC

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 配置
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

nonisolated public enum CCSheetDetent: Equatable {
    /// 近全屏
    case large
    /// 半屏（可上拉 large）
    case medium
    /// 半屏 + 全屏
    case mediumAndLarge
    /// 固定内容高度（矮表单）
    case compact(CGFloat)
}

/// 纯配置值类型，nonisolated 使 `.form` 等静态可作默认参数在任意上下文求值（模块默认 MainActor 隔离）
nonisolated public struct CCSheetConfig: Equatable {
    public var detent: CCSheetDetent = .large
    public var showGrabber: Bool = true
    /// true：有未保存改动时拦截下拉，弹原生三选一 Alert
    public var tracksEdits: Bool = true
    /// 磨砂玻璃底（他人主页等浏览 sheet）
    public var frostedGlass: Bool = false
    public var cornerRadius: CGFloat = 34
    public var haptic: Bool = true
    /// 滚到边缘是否自动扩张到更大 detent
    public var scrollingExpands: Bool = true
    /// 紧凑高度下贴边（iPhone 横屏等）
    public var edgeAttachedInCompactHeight: Bool = true
    /// 最大未遮罩 detent（nil = 全程有 dimming）
    public var largestUndimmed: CCSheetDetent? = nil
    /// Zoom 锚点起点 id（非 nil 即走英雄锚点转场；source 不在场自动降级默认转场）
    public var zoomSourceID: String? = nil
    /// true：宿主贴物理底边并吞底安全区（浏览器 / 关于 / 选图裁剪）；false：贴 keyboardLayoutGuide（表单给键盘与 Home 条让位）
    public var extendsToBottomEdge: Bool = false

    /// 任意配置追加锚点转场：`.profile.zoom(from: prospect.id)`
    public func zoom(from sourceID: String) -> CCSheetConfig {
        var config = self
        config.zoomSourceID = sourceID
        return config
    }

    public static let form = CCSheetConfig(detent: .large, showGrabber: true, tracksEdits: true)
    /// 次级浏览页（关于 / InAppBrowser / 地点等）：吃穿底安全区，杜绝底栏空白条
    public static let sheet = CCSheetConfig(
        detent: .large,
        showGrabber: true,
        tracksEdits: false,
        extendsToBottomEdge: true
    )
    /// 他人主页：近全屏定制磨砂 pageSheet（大圆角 / grabber / 可下滑）
    public static let profile = CCSheetConfig(
        detent: .large,
        showGrabber: true,
        tracksEdits: false,
        frostedGlass: true,
        cornerRadius: 40,
        scrollingExpands: true,
        edgeAttachedInCompactHeight: true,
        largestUndimmed: nil,
        extendsToBottomEdge: true
    )
    public static let half = CCSheetConfig(detent: .mediumAndLarge, showGrabber: true, tracksEdits: false)
    public static func compact(_ height: CGFloat = 280) -> CCSheetConfig {
        CCSheetConfig(detent: .compact(height), showGrabber: false, tracksEdits: true, scrollingExpands: false)
    }
    /// 系统选图 + 裁剪：满铺到底，禁止 Home 条上方留白
    public static let picker = CCSheetConfig(
        detent: .large,
        showGrabber: false,
        tracksEdits: false,
        extendsToBottomEdge: true
    )
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 编辑会话（脏态 / 保存 / 关闭）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

@MainActor
public final class CCEditSheetContext: ObservableObject {
    public init() {}

    @Published private(set) var isDirty = false
    /// 注册过保存闭包：脏态右上变 ✓、关前三选一；没注册的 sheet（如意见箱，主钮在页内）恒为 ✕、关前只问放弃
    @Published private(set) var canSave = false

    fileprivate weak var host: UIViewController?
    fileprivate var tracksEdits = true
    fileprivate var saveHandler: (() async -> Bool)?
    fileprivate var binder: CCSheetDismissBinder?

    func setDirty(_ dirty: Bool = true) {
        guard isDirty != dirty else { return }
        isDirty = dirty
        binder?.syncModalInPresentation()
    }

    /// 注册保存；返回 true 则关闭 sheet
    func registerSave(_ handler: @escaping () async -> Bool) {
        saveHandler = handler
        canSave = true
    }

    func requestClose() {
        if tracksEdits, isDirty {
            binder?.presentUnsavedAlert()
        } else {
            forceDismiss()
        }
    }

    func commitSave() async {
        if let saveHandler {
            if await saveHandler() {
                forceDismiss()
            }
        } else {
            forceDismiss()
        }
    }

    func discardAndDismiss() {
        forceDismiss()
    }

    func forceDismiss() {
        AppHelper.shared.dismissKeyboard()
        host?.dismiss(animated: true)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 下拉关闭拦截（UIAdaptivePresentationControllerDelegate）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

@MainActor
public final class CCSheetDismissBinder: NSObject, UIAdaptivePresentationControllerDelegate {
    let context: CCEditSheetContext
    let tracksEdits: Bool
    weak var hosted: UIViewController?

    public init(context: CCEditSheetContext, tracksEdits: Bool) {
        self.context = context
        self.tracksEdits = tracksEdits
        super.init()
        context.binder = self
        context.tracksEdits = tracksEdits
    }

    func syncModalInPresentation() {
        hosted?.isModalInPresentation = tracksEdits && context.isDirty
    }

    public func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        !(tracksEdits && context.isDirty)
    }

    public func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        presentUnsavedAlert()
    }

    func presentUnsavedAlert() {
        let save = CCAlertAction(title: CCStrings.current.save, role: .default) { [weak self] in
            Task { @MainActor in await self?.context.commitSave() }
        }
        AppHelper.shared.showBottomAlert(
            title: CCStrings.current.unsavedTitle,
            message: CCStrings.current.unsavedMessage,
            actions: (context.canSave ? [save] : []) + [
                CCAlertAction(
                    title: CCStrings.current.discard,
                    role: .destructive
                ) { [weak self] in
                    self?.context.discardAndDismiss()
                },
                CCAlertAction(
                    title: CCStrings.current.keepEditing,
                    role: .secondary
                ),
            ]
        )
    }
}

private var ccSheetBinderKey: UInt8 = 0

extension UIViewController {
    fileprivate var cc_sheetBinder: CCSheetDismissBinder? {
        get { objc_getAssociatedObject(self, &ccSheetBinderKey) as? CCSheetDismissBinder }
        set { objc_setAssociatedObject(self, &ccSheetBinderKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 原生 pageSheet 容器
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public final class CCNativeSheetController: UIViewController {
    let context: CCEditSheetContext
    private let config: CCSheetConfig
    private var onDismiss: (() -> Void)?
    private let hosting: UIViewController
    private var binder: CCSheetDismissBinder!

    init<Content: View>(
        config: CCSheetConfig,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        let ctx = CCEditSheetContext()
        self.context = ctx
        self.config = config
        self.onDismiss = onDismiss
        // 满铺底边时从 SwiftUI 侧一并吞底安全区（UIImagePicker / WebView 等 UIKit 子树才吃得到）
        let root = content()
            .environmentObject(ctx)
            .modifier(CCSheetBottomEdgeBleed(enabled: config.extendsToBottomEdge))
        self.hosting = UIHostingController(rootView: root)
        super.init(nibName: nil, bundle: nil)
        ctx.host = self
        let binder = CCSheetDismissBinder(context: ctx, tracksEdits: config.tracksEdits)
        binder.hosted = self
        self.binder = binder
        self.cc_sheetBinder = binder
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func viewDidLoad() {
        super.viewDidLoad()
        let opaque = UIColor(Color.cc.background)
        view.backgroundColor = config.frostedGlass ? .clear : opaque

        if config.frostedGlass {
            // 26.1+ 由 sheet.backgroundEffect 吃材质；更早系统只靠内容层 UIVisualEffectView
            // 禁止两层同时开——叠厚会直接渲成实心
            if !Self.sheetOwnsFrostedBackdrop {
                installFrostedBackdrop()
            }
        }

        addChild(hosting)
        hosting.view.backgroundColor = config.frostedGlass ? .clear : opaque
        hosting.view.isOpaque = !config.frostedGlass
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hosting.view)
        // 根因：keyboardLayoutGuide 在键盘收起时 = 底安全区顶沿 → 选图/浏览器底下出现「垃圾空白条」
        // extendsToBottomEdge：贴物理底边；表单仍贴 keyboardLayoutGuide 以避键盘
        let bottomAnchor = config.extendsToBottomEdge
            ? view.bottomAnchor
            : view.keyboardLayoutGuide.topAnchor
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        hosting.didMove(toParent: self)

        modalPresentationStyle = .pageSheet
        if let sheet = sheetPresentationController {
            applySheetChrome(sheet)
        }
        presentationController?.delegate = binder
        isModalInPresentation = false
    }

    private static var sheetOwnsFrostedBackdrop: Bool {
        if #available(iOS 26.1, *) { return true }
        return false
    }

    /// 磨砂底：单层 UIVisualEffectView
    private func installFrostedBackdrop() {
        let blur = UIVisualEffectView(effect: Self.frostedBlurEffect)
        blur.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(blur, at: 0)
        NSLayoutConstraint.activate([
            blur.topAnchor.constraint(equalTo: view.topAnchor),
            blur.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blur.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    /// 材质阶梯中间档：ultraThin < thin < **material** < thick < chrome
    private static var frostedBlurEffect: UIBlurEffect {
        UIBlurEffect(style: .systemMaterial)
    }

    /// UIKit 层深度调参：detents / grabber / 圆角 / 扩张 / 贴边 / dimming / 背景
    private func applySheetChrome(_ sheet: UISheetPresentationController) {
        sheet.prefersGrabberVisible = config.showGrabber
        sheet.preferredCornerRadius = config.cornerRadius
        sheet.prefersScrollingExpandsWhenScrolledToEdge = config.scrollingExpands
        sheet.prefersEdgeAttachedInCompactHeight = config.edgeAttachedInCompactHeight
        sheet.widthFollowsPreferredContentSizeWhenEdgeAttached = false

        if config.frostedGlass {
            applyFrostedSheetChrome(sheet)
            return
        }

        sheet.detents = Self.uiDetents(for: config.detent)
        sheet.selectedDetentIdentifier = Self.primaryDetentId(for: config.detent)
        if let undimmed = config.largestUndimmed {
            sheet.largestUndimmedDetentIdentifier = Self.primaryDetentId(for: undimmed)
        } else {
            sheet.largestUndimmedDetentIdentifier = nil
        }
    }

    /// iOS 26：禁 pageSizing + 近全高 detent；26.1+ 只在 sheet 上挂一层 systemMaterial
    private func applyFrostedSheetChrome(_ sheet: UISheetPresentationController) {
        let frostId = UISheetPresentationController.Detent.Identifier("cc.frosted.large")
        if #available(iOS 26.0, *) {
            sheet.prefersPageSizing = false
            let frosted = UISheetPresentationController.Detent.custom(identifier: frostId) { context in
                // 留顶缝：背后列表/页才能被材质采样模糊
                max(0, context.maximumDetentValue - 28)
            }
            if #available(iOS 26.1, *) {
                frosted.backgroundEffect = Self.frostedBlurEffect
                sheet.backgroundEffect = Self.frostedBlurEffect
            }
            sheet.detents = [frosted]
            sheet.selectedDetentIdentifier = frostId
            sheet.largestUndimmedDetentIdentifier = nil
            return
        }

        sheet.detents = Self.uiDetents(for: config.detent)
        sheet.selectedDetentIdentifier = Self.primaryDetentId(for: config.detent)
        sheet.largestUndimmedDetentIdentifier = nil
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isBeingDismissed || presentingViewController == nil {
            onDismiss?()
            onDismiss = nil
        }
    }

    private static func uiDetents(for detent: CCSheetDetent) -> [UISheetPresentationController.Detent] {
        switch detent {
        case .large:
            return [.large()]
        case .medium:
            return [.medium()]
        case .mediumAndLarge:
            return [.medium(), .large()]
        case .compact(let height):
            return [
                .custom(identifier: .init("cc.compact")) { _ in height },
            ]
        }
    }

    private static func primaryDetentId(for detent: CCSheetDetent) -> UISheetPresentationController.Detent.Identifier {
        switch detent {
        case .large: return .large
        case .medium, .mediumAndLarge: return .medium
        case .compact: return .init("cc.compact")
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Zoom / 任意 hosted VC 挂编辑拦截
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public enum CCSheetHosting {
    /// 把 SwiftUI 根视图包成可 present 的 hosting，并注入编辑会话
    @MainActor
    public static func make<Content: View>(
        tracksEdits: Bool,
        @ViewBuilder content: () -> Content
    ) -> (host: UIViewController, context: CCEditSheetContext) {
        let context = CCEditSheetContext()
        let host = UIHostingController(rootView: content().environmentObject(context))
        context.host = host
        let binder = CCSheetDismissBinder(context: context, tracksEdits: tracksEdits)
        binder.hosted = host
        host.cc_sheetBinder = binder
        host.presentationController?.delegate = binder
        // presentationController 在 present 后才就绪；调用方 present 后再绑一次
        return (host, context)
    }

    @MainActor
    public static func attachBinder(to host: UIViewController, context: CCEditSheetContext, tracksEdits: Bool) {
        let binder = CCSheetDismissBinder(context: context, tracksEdits: tracksEdits)
        binder.hosted = host
        host.cc_sheetBinder = binder
        host.presentationController?.delegate = binder
        context.host = host
        context.binder = binder
        context.tracksEdits = tracksEdits
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 呈现锚点（popover 收起竞态）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public enum CCPresentationAnchor {
    public static func topmost() -> UIViewController? {
        keyRoot()?.cc_topmostPresented()
    }

    public static func presentationHost() -> UIViewController? {
        guard let root = keyRoot(), root.view.window != nil else { return nil }
        return root.cc_stablePresentationHost()
    }

    public static func performWhenReady(
        retries: Int = 32,
        interval: TimeInterval = 0.05,
        _ work: @escaping (UIViewController) -> Void
    ) {
        let attempt = {
            if let host = presentationHost(), host.view.window != nil {
                work(host)
            } else if retries > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
                    performWhenReady(retries: retries - 1, interval: interval, work)
                }
            }
        }
        if Thread.isMainThread {
            attempt()
        } else {
            DispatchQueue.main.async(execute: attempt)
        }
    }

    private static func keyRoot() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController
    }
}

extension UIViewController {
    func cc_topmostPresented() -> UIViewController {
        if let presented = presentedViewController { return presented.cc_topmostPresented() }
        if let nav = self as? UINavigationController, let visible = nav.visibleViewController {
            return visible.cc_topmostPresented()
        }
        if let tab = self as? UITabBarController, let selected = tab.selectedViewController {
            return selected.cc_topmostPresented()
        }
        return self
    }

    fileprivate var cc_isTransientPresentationHost: Bool {
        if view.window == nil { return true }
        if modalPresentationStyle == .popover { return true }
        let name = String(describing: type(of: self))
        if name.contains("PresentationHostingController") { return true }
        return false
    }

    fileprivate func cc_stablePresentationHost() -> UIViewController? {
        if isBeingDismissed || isBeingPresented { return nil }
        if transitionCoordinator != nil { return nil }
        guard view.window != nil else { return nil }

        if let nav = self as? UINavigationController {
            if let presented = nav.presentedViewController {
                return nav.cc_resolvePresented(presented)
            }
            if let visible = nav.visibleViewController,
               let presented = visible.presentedViewController
            {
                return visible.cc_resolvePresented(presented)
            }
            return nav
        }

        if let presented = presentedViewController {
            return cc_resolvePresented(presented)
        }
        return self
    }

    private func cc_resolvePresented(_ presented: UIViewController) -> UIViewController? {
        if presented.isBeingDismissed
            || presented.isBeingPresented
            || presented.transitionCoordinator != nil
            || presented.view.window == nil
            || presented.cc_isTransientPresentationHost
        {
            return nil
        }
        if presented is CCNativeSheetController
            || presented.modalPresentationStyle == .custom
            || presented.modalPresentationStyle == .fullScreen
            || presented.modalPresentationStyle == .pageSheet
            || presented.modalPresentationStyle == .formSheet
            || presented.modalPresentationStyle == .overFullScreen
        {
            return presented.cc_stablePresentationHost() ?? presented
        }
        return nil
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 底边出血（SwiftUI 侧吞底安全区）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

private struct CCSheetBottomEdgeBleed: ViewModifier {
    let enabled: Bool

    func body(content: Content) -> some View {
        if enabled {
            content.ignoresSafeArea(edges: .bottom)
        } else {
            content
        }
    }
}
