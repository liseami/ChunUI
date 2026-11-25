/**
 * [INPUT]: 依赖 Theme/CCColors 调色板与 L10n/CCStrings 文案表
 * [OUTPUT]: 对外提供 ChunUI.configure —— 宿主应用唯一初始化入口（配色即换肤）
 * [POS]: Core 的包门面；所有全局可变配置（调色板/文案/钩子）从这里进，组件只读
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI

public enum ChunUI {

    /// 一行换肤：App 启动时传入语义调色板，全组件族即刻生效；不调用即 .default（Zinner 黑白粉）
    public static func configure(
        colors: CCColors = .default,
        strings: CCStrings = .init()
    ) {
        CCColors.current = colors
        CCStrings.current = strings
    }

    /// 宿主的缺省头像 CDN URL（与之相同的头像 URL 视作无头像，走本地缺省图）
    public static var defaultAvatarURL: String = ""

    /// 触觉实时读取器：宿主可接到用户设置（如 @AppStorage），每次触发都取现值
    nonisolated(unsafe) public static var hapticsResolver: (() -> Bool)?

    /// 触觉反馈总开关（读走 resolver，写即固定为常量 resolver）
    public static var hapticsEnabled: Bool {
        get { hapticsResolver?() ?? true }
        set { hapticsResolver = { newValue } }
    }

    /// sheet 呈现钩子：宿主埋点系统可借此拿到 host controller 与内容页名（如自动页面注册）
    public static var sheetPresentHook: ((UIViewController, String) -> Void)? = nil
}
