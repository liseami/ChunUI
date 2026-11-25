//
//  Apphelper.swift
//  YUI
//
//  Created by 赵翔宇 on 2025/2/19.
//

/**
 * [INPUT]: 依赖 UIKit/SwiftUI 系统服务、StoreKit、ChunUI.hapticsEnabled 开关、CCToastCenter / CCAlertCenter、CCNativeSheet、CCZoom 锚点转场工厂
 * [OUTPUT]: 对外提供 AppHelper 单例——触觉 mada、键盘、presentSheet/dismissSheet（原生 pageSheet）、沉底 Alert、toast（路由经可注入 toastRouteResolver）、AppStore.requestReview
 * [POS]: Presentation 的应用级工具门面；宿主的 sheet/alert/toast 命令式唯一出口，禁止 UIAlertController / SwiftUI .alert/.sheet 另起炉灶
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import Foundation
import StoreKit
import SwiftUI
 
/// AppHelper: 应用程序全局工具类
/// 该类采用单例模式，确保在整个应用程序中统一使用
public final class AppHelper {
    // MARK: - 单例

    /// AppHelper 的共享实例
    public static let shared = AppHelper()

    /// 私有初始化方法，确保单例模式的实现
    private init() {}

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 应用评分系统
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    /// 评分请求场景
    public enum ReviewScenario: String, CaseIterable {
        /// 首次建档成功（手动添加对象）
        case firstProspectAdd = "review_requested_first_prospect"
        /// 订阅成功
        case subscription = "review_requested_subscription"
        /// 首次分析完毕且有数据
        case firstAnalysis = "review_requested_first_analysis"
    }

    /// 检查指定场景是否已请求过评分
    private func hasRequestedReview(for scenario: ReviewScenario) -> Bool {
        UserDefaults.standard.bool(forKey: scenario.rawValue)
    }

    /// 标记指定场景已请求评分
    private func markReviewRequested(for scenario: ReviewScenario) {
        UserDefaults.standard.set(true, forKey: scenario.rawValue)
    }

    /// 按场景请求应用评分，每个场景只触发一次
    @MainActor
    public func requestReviewIfNeeded(for scenario: ReviewScenario) {
        guard !hasRequestedReview(for: scenario) else { return }

        markReviewRequested(for: scenario)

        // 延迟 1 秒，让用户看到成功状态后再弹出（iOS 18+ AppStore.requestReview）
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            if let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                AppStore.requestReview(in: scene)
            }
        }
    }

    /// 重置所有评分请求状态（仅用于调试）
    #if DEBUG
    public func resetAllReviewStates() {
        ReviewScenario.allCases.forEach { scenario in
            UserDefaults.standard.removeObject(forKey: scenario.rawValue)
        }
    }
    #endif
    
    // MARK: - 触觉反馈类型
    
    /// HapticFeedbackStyle: 定义不同级别的触觉反馈强度
    ///
    /// 使用示例:
    /// ```swift
    /// AppHelper.shared.generateHapticFeedback(.light) // 用于轻微的反馈
    /// AppHelper.shared.generateHapticFeedback(.medium) // 用于适中的反馈
    /// AppHelper.shared.generateHapticFeedback(.heavy) // 用于强烈的反馈
    /// ```
    public enum HapticFeedbackStyle {
        case soft
        /// 轻度触感 - 适用于轻微的交互（例如：滑动切换项目）
        case light
        
        /// 中度触感 - 适用于确认操作（例如：按钮点击）
        case medium
        
        /// 重度触感 - 适用于重要事件（例如：完成重要操作）
        case heavy
        
        /// 成功触感 - 表示任务成功完成
        case success
        
        /// 警告触感 - 表示警告或重要提示
        case warning
        
        /// 错误触感 - 表示错误或失败
        case error
        
        /// 选择触感 - 表示选择状态发生变化
        case selection
    }
    
    // MARK: - 触觉反馈方法
    
    /// 按样式生成触觉反馈，内部按类型选用不同的反馈生成器
    public func mada(_ style: HapticFeedbackStyle) {
        guard ChunUI.hapticsEnabled else { return }

        switch style {
        case .soft:
            let generator = UIImpactFeedbackGenerator(style: .soft)
            generator.prepare()
            generator.impactOccurred()
        case .light:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred()
            
        case .medium:
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred()
            
        case .heavy:
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
            
        case .success:
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.success)
            
        case .warning:
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.warning)
            
        case .error:
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.error)
            
        case .selection:
            let generator = UISelectionFeedbackGenerator()
            generator.prepare()
            generator.selectionChanged()
        }
    }
    
    // MARK: - 键盘管理
    
    /// 关闭当前键盘
    /// 该方法会遍历当前窗口中的所有视图，找到第一响应者并关闭键盘@
    
    public func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // MARK: - 警告框管理
    
    /// AlertAction: 定义警告框按钮的行为
    public struct AlertAction {
        let title: String
        let style: UIAlertAction.Style
        let handler: (() -> Void)?
        
        public init(title: String, style: UIAlertAction.Style = .default, handler: (() -> Void)? = nil) {
            self.title = title
            self.style = style
            self.handler = handler
        }
    }
    
    /// 显示沉底自定义 Alert（全应用唯一出口 → CCAlertCenter）；actions 从左到右排布，sourceView / sourceRect 是旧 UIAlert 兼容参数，已忽略
    @MainActor
    public func showAlert(
        title: String,
        message: String,
        actions: [AlertAction],
        sourceView: UIView? = nil,
        sourceRect: CGRect? = nil
    ) {
        let mapped: [CCAlertAction] = actions.map { action in
            let role: CCAlertAction.Role = switch action.style {
            case .destructive: .destructive
            case .cancel: .secondary
            default: .default
            }
            return CCAlertAction(title: action.title, role: role, handler: action.handler)
        }
        CCAlertCenter.shared.present(
            title: title,
            message: message.isEmpty ? nil : message,
            actions: Self.normalizedAlertActions(mapped)
        )
    }

    /// 沉底 Alert 便捷入口（与 showAlert 同路径；内部 API，参数用模块内 CCAlertAction）
    @MainActor
    public func showBottomAlert(
        title: String,
        message: String? = nil,
        actions: [CCAlertAction]
    ) {
        CCAlertCenter.shared.present(
            title: title,
            message: message,
            actions: Self.normalizedAlertActions(actions)
        )
    }

    /// 仅「单独 destructive」时右侧补取消，凑齐 Twitter 双胶囊；信息确认单钮保持通栏
    private static func normalizedAlertActions(_ actions: [CCAlertAction]) -> [CCAlertAction] {
        guard actions.count == 1, actions[0].role == .destructive else { return actions }
        return actions + [
            CCAlertAction(
                title: CCStrings.current.cancel,
                role: .secondary
            ),
        ]
    }
    
    public enum NotificationType {
        case success(message: String)
        case info(message: String)
        case warning(message: String)
        case error(message: String)
        case loading(message: String)
    }
    
    /// 全应用消息 toast 唯一出口：路由到自研 CCToastCenter（CCToastWindow 置顶窗口），一级页（tabbar 在场）走阿奇头像气泡，其余走顶部胶囊
    @MainActor
    public func pushNotification(type: NotificationType) {
        let route = toastRoute()
        switch type {
        case let .info(message):
            CCToastCenter.shared.show(.info, message, route: route)
        case let .success(message):
            mada(.success)
            CCToastCenter.shared.show(.success, message, route: route)
        case let .warning(message):
            mada(.warning)
            CCToastCenter.shared.show(.warning, message, route: route)
        case let .error(message):
            mada(.error)
            CCToastCenter.shared.show(.error, message, route: route)
        case let .loading(message):
            CCToastCenter.shared.show(.loading, message, route: route)
        }
    }

    /// 气泡路由策略注入座：宿主可按自身导航态决定 toast 走顶部胶囊还是头像气泡；
    /// 未注入时恒为顶部胶囊（包内不感知宿主导航结构）
    public static var toastRouteResolver: (() -> CCToastCenter.Route)?

    @MainActor
    private func toastRoute() -> CCToastCenter.Route {
        Self.toastRouteResolver?() ?? .capsule
    }

    // MARK: - 卡片展示方法

    /// 在独立窗口中央展示 SwiftUI 卡片（转交 TopCardPresenter）；tapToClose 为 true 时点背景即关
    @MainActor
    public func showCenterCard<Content: View>(
        view: Content,
        animated: Bool = true,
        backgroundColor: UIColor = UIColor.black.withAlphaComponent(0.5),
        tapToClose: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        TopCardPresenter.shared.presentCard(
            view: view,
            animated: animated,
            backgroundColor: backgroundColor,
            isUserInteractionEnabled: tapToClose,
            completion: completion
        )
    }
    
    public func topMostViewController() -> UIViewController? {
        let vc = UIApplication.shared.connectedScenes.filter {
            $0.activationState == .foregroundActive
        }.first(where: { $0 is UIWindowScene })
            .flatMap { $0 as? UIWindowScene }?.windows
            .first(where: \.isKeyWindow)?
            .rootViewController?
            .topMostViewController()

        return vc
    }

    /// 关闭最顶层的中央卡片（转交 TopCardPresenter）
    @MainActor
    public func dismissCenterCard(animated: Bool = true, completion: (() -> Void)? = nil) {
        TopCardPresenter.shared.dismissCard(animated: animated, completion: completion)
    }

    @MainActor
    public func dissMissNotification() {
        CCToastCenter.shared.dismiss()
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 原生 UIKit pageSheet（函数式唯一出口）
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    /// 弹出原生 pageSheet（UISheetPresentationController）：presentSheet(.form) { … }，另有 .compact(280)、.picker
    @MainActor
    public func presentSheet<Content: View>(
        _ config: CCSheetConfig = .form,
        onDismiss: (() -> Void)? = nil,
        onPresent: ((UIViewController) -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        let root = content()
        CCPresentationAnchor.performWhenReady { presenter in
            if config.haptic { self.mada(.soft) }
            let host = CCNativeSheetController(config: config, onDismiss: onDismiss) { root }
            // 埋点钩子：宿主可借此拿到 host 与内容页名（如自动页面注册）
            ChunUI.sheetPresentHook?(host, String(describing: Content.self))
            if let sourceID = config.zoomSourceID {
                host.preferredTransition = CCZoom.transition(sourceID: sourceID)
            }
            presenter.present(host, animated: true)
            onPresent?(host)
        }
    }

    /// 关闭最顶层 modal（sheet / fullScreen）
    @MainActor
    public func dismissSheet(animated: Bool = true, completion: (() -> Void)? = nil) {
        dismissKeyboard()
        CCPresentationAnchor.topmost()?.dismiss(animated: animated, completion: completion)
    }
}

#if DEBUG

public struct CardDemoView: View {
    var onClose: () -> Void
    
    public var body: some View {
        VStack(spacing: 20) {
            Text("通过AppHelper展示的卡片")
                .ccText(font: .cc.body , color: .cc.foreground)
                .padding(.top)
            
            Text("这个卡片使用AppHelper的方法在顶级窗口上展示")
                .multilineTextAlignment(.center)
                .ccText(font: .cc.callout , color: .cc.mutedForeground)
                .padding(.horizontal)
            
            CCDesigin.CCButton {
                onClose()
            } label: {
                Text("关闭卡片")
            }
            .padding(.bottom)
        }
        .frame(width: 300)
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 10)
    }
}

public struct AppHelperCardDemoView: View {
    public var body: some View {
        VStack(spacing: 20) {
            Text("AppHelper卡片演示")
                .font(.title)
                .padding(.top)
            
            CCDesigin.CCButton {
                Task { @MainActor in
                    AppHelper.shared.showCenterCard(
                        view: CardDemoView(onClose: {
                            Task { @MainActor in
                                AppHelper.shared.dismissCenterCard()
                            }
                        })
                    )
                }
            } label: {
                Text("显示卡片")
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview {
    AppHelperCardDemoView()
}

public struct NotificationPreview: View {
    public var body: some View {
        VStack(spacing: 20) {
            Text("通知预览")
                .font(.title)
                .padding(.top)
            
            VStack(spacing: 15) {
                Button("成功通知") {
                    AppHelper.shared.pushNotification(type: .success(message: "success"))
                }
                .buttonStyle(.borderedProminent)
                
                Button("信息通知") {
                    AppHelper.shared.pushNotification(type: .info(message: "info"))
                }
                .buttonStyle(.borderedProminent)
                
                Button("警告通知") {
                    AppHelper.shared.pushNotification(type: .warning(message: "warning"))
                }
                .buttonStyle(.borderedProminent)
                
                Button("错误通知") {
                    AppHelper.shared.pushNotification(type: .error(message: "error"))
                }
                .buttonStyle(.borderedProminent)
                
                Button("加载通知") {
                    AppHelper.shared.pushNotification(type: .loading(message: "loading"))
                }
                .buttonStyle(.borderedProminent)
            }
            .ccText(font: .cc.body , color: .cc.foreground)
            .padding()
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview("通知预览") {
    NotificationPreview()
}

#endif

extension UIViewController {
    public func topMostViewController() -> UIViewController {
        if self.presentedViewController == nil {
            return self
        }
        
        if let navigation = self.presentedViewController as? UINavigationController {
            return navigation.visibleViewController!.topMostViewController()
        }
        
        if let tab = self.presentedViewController as? UITabBarController {
            if let selectedTab = tab.selectedViewController {
                return selectedTab.topMostViewController()
            }
            return tab.topMostViewController()
        }
        
        return self.presentedViewController!.topMostViewController()
    }
}
