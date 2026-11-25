/**
 * [INPUT]: 依赖 Studio 的 CCStudioText.t(_:table:)（按 CCLanguage 生效语言取 Bundle.module 的 lproj）与本目录 Components.xcstrings
 * [OUTPUT]: 包内提供 CCComponentText（internal）：t(_:) 取词，f(_:_:) 取格式串再填参数
 * [POS]: Core 的组件文案出口。组件自带的界面字（日历表头、演示面板）只从这里取；宿主可覆写的通用文案仍走 CCStrings
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import Foundation

nonisolated enum CCComponentText {
    /// 取 Components 表里的一条文案，语言跟 CCLanguage
    static func t(_ key: String) -> String {
        CCStudioText.t(key, table: "Components")
    }

    /// 取格式串并填参数（%lld 传 Int，%.1f 传 Double）
    static func f(_ key: String, _ args: CVarArg...) -> String {
        String(format: t(key), arguments: args)
    }
}
