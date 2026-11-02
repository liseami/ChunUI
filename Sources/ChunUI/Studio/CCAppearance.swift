/**
 * [INPUT]: 依赖 UIKit 的 UIWindowScene 窗口与 overrideUserInterfaceStyle、UserDefaults、Studio 的 CCStudioText
 * [OUTPUT]: 对外提供 CCAppearance（外观三选一：跟随系统 · 浅色 · 深色；存取、应用到全部窗口）
 * [POS]: Studio 层的外观唯一实现，四个 App 共用。窗口级覆写，不靠 SwiftUI preferredColorScheme，UIKit 壳与 sheet 一并生效
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI

public final class CCAppearance: ObservableObject {
    public enum Mode: String, CaseIterable, Identifiable {
        case system, light, dark

        public var id: String { rawValue }

        public var style: UIUserInterfaceStyle {
            switch self {
            case .system: .unspecified
            case .light: .light
            case .dark: .dark
            }
        }

        public var title: String {
            switch self {
            case .system: CCStudioText.appearanceSystem
            case .light: CCStudioText.appearanceLight
            case .dark: CCStudioText.appearanceDark
            }
        }

        /// 行前导图标（Pika）
        public var icon: String {
            switch self {
            case .system: "screen-check"
            case .light: "sun"
            case .dark: "moon"
            }
        }
    }

    public static let shared = CCAppearance()

    @Published public private(set) var mode: Mode
    private var storageKey = "cc.appearance"

    private init() {
        mode = .system
        load()
    }

    /// 宿主启动时调用一次：storageKey 沿用旧版本的键，老用户的选择不丢
    public func configure(storageKey: String) {
        self.storageKey = storageKey
        load()
    }

    public func select(_ mode: Mode) {
        self.mode = mode
        UserDefaults.standard.set(mode.rawValue, forKey: storageKey)
        applyToAllWindows()
    }

    /// 新建窗口时调用（SceneDelegate 建完窗口、浮层窗口起来时）
    public func apply(to window: UIWindow) {
        window.overrideUserInterfaceStyle = mode.style
    }

    public func applyToAllWindows() {
        for scene in UIApplication.shared.connectedScenes {
            guard let scene = scene as? UIWindowScene else { continue }
            scene.windows.forEach(apply(to:))
        }
    }

    private func load() {
        mode = UserDefaults.standard.string(forKey: storageKey).flatMap(Mode.init(rawValue:)) ?? .system
    }
}
