/**
 * [INPUT]: 依赖 Foundation 的 Bundle / UserDefaults（AppleLanguages）/ Locale、SwiftUI 的 environment(\.locale)
 * [OUTPUT]: 对外提供 CCLanguage（应用内语言：可选语言、所选、生效语言码、取词包、语言名、切换；currentCode 任何线程可读）、Bundle.appLanguage（任何线程可读的取词包）、View.ccLanguageRoot()
 * [POS]: Studio 层的运行时语言唯一实现，四个 App 共用。切换即时生效：取词改走所选语言的 lproj 包，根视图按 epoch 重挂；
 *        同时写 AppleLanguages，冷启动时系统弹窗、权限说明与 Bundle.main 也对齐。宿主的文案入口（String(localized:bundle:)、.local()、生成的 L.*）都只读这里
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 跨线程只读快照：取词可能发生在任意线程，写只在主线程
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

enum CCLanguageSnapshot {
    nonisolated(unsafe) static var bundle: Bundle = .main
    nonisolated(unsafe) static var code: String = Bundle.main.developmentLocalization ?? "en"
}

public extension Bundle {
    /// 界面文案的唯一取词包：所选语言的 lproj；跟随系统时按系统偏好在本 App 的语言里挑
    nonisolated static var appLanguage: Bundle { CCLanguageSnapshot.bundle }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCLanguage
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public final class CCLanguage: ObservableObject {
    /// 「跟随系统」的存储值
    public static let system = "system"

    public static let shared = CCLanguage()

    /// 所选：system 或某个 lproj 语言码（zh-Hans、en、pt-BR…）
    @Published public private(set) var selection: String
    /// 每切一次加一：根视图以它作 id 整棵重挂
    @Published public private(set) var epoch = 0
    /// 生效的语言码（跟随系统时已解析成本 App 支持的那一种）；请求头 X-Language 取它
    public private(set) var code: String

    /// 本 App 可选的语言（lproj 语言码），顺序即列表顺序
    public private(set) var available: [String]
    private var storageKey = "cc.language"

    private init() {
        available = Self.bundleLanguages()
        selection = Self.system
        code = CCLanguageSnapshot.code
        load()
    }

    /// 宿主启动时调用一次（在任何界面出现之前）：
    /// - storageKey：沿用旧版本存所选语言的键，老用户的选择不丢
    /// - supported：可选语言；缺省取 App 包里的 lproj（不含 Base）。文案不在 lproj 里的宿主（如生成的 L.*）显式传
    public func configure(storageKey: String? = nil, supported: [String]? = nil) {
        if let storageKey { self.storageKey = storageKey }
        if let supported, !supported.isEmpty { available = supported }
        load()
    }

    /// 切换语言：存所选、写 AppleLanguages、换取词包，并让根视图重挂
    public func select(_ selection: String) {
        let value = selection == Self.system || available.contains(selection) ? selection : Self.system
        UserDefaults.standard.set(value, forKey: storageKey)
        if value == Self.system {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.set([value], forKey: "AppleLanguages")
        }
        apply(value)
        epoch += 1
    }

    /// 生效的语言码，任何线程可读（请求头 X-Language、后台取词）
    public nonisolated static var currentCode: String { CCLanguageSnapshot.code }

    /// 排版用的 Locale：跟随系统时就是系统的 Locale（保留地区格式、随系统更新）；手选时取所选语言
    public var locale: Locale { selection == Self.system ? .autoupdatingCurrent : Locale(identifier: code) }

    /// 语言名一律用该语言自己的写法（简体中文、English、日本語）；system 显示「跟随系统」的当前语言写法
    public func displayName(_ selection: String) -> String {
        if selection == Self.system { return CCStudioText.languageSystem }
        let own = Locale(identifier: selection)
        let name = own.localizedString(forIdentifier: selection) ?? selection
        return name.prefix(1).uppercased(with: own) + name.dropFirst()
    }

    // ━━━ 内部 ━━━

    private func load() {
        let saved = UserDefaults.standard.string(forKey: storageKey) ?? Self.system
        apply(saved == Self.system || available.contains(saved) ? saved : Self.system)
    }

    private func apply(_ value: String) {
        selection = value
        code = Self.resolve(value, among: available)
        CCLanguageSnapshot.code = code
        CCLanguageSnapshot.bundle = Self.lproj(code, in: .main) ?? .main
    }

    /// 跟随系统：AppleLanguages 已被移除时读到的是系统全局偏好
    private static func resolve(_ value: String, among available: [String]) -> String {
        let preferences = value == system
            ? (UserDefaults.standard.stringArray(forKey: "AppleLanguages") ?? Locale.preferredLanguages)
            : [value]
        let candidates = available.isEmpty ? bundleLanguages() : available
        return Bundle.preferredLocalizations(from: candidates, forPreferences: preferences).first
            ?? Bundle.main.developmentLocalization ?? "en"
    }

    private static func bundleLanguages() -> [String] {
        let all = Bundle.main.localizations.filter { $0 != "Base" }
        let source = Bundle.main.developmentLocalization
        return all.sorted { lhs, rhs in
            if lhs == source { return true }
            if rhs == source { return false }
            return lhs < rhs
        }
    }

    /// 某个包里某种语言的 lproj；找不到退到同语种（pt-BR → pt）
    nonisolated static func lproj(_ code: String, in bundle: Bundle) -> Bundle? {
        for candidate in [code, String(code.split(separator: "-").first ?? "")] where !candidate.isEmpty {
            if let path = bundle.path(forResource: candidate, ofType: "lproj"), let lproj = Bundle(path: path) {
                return lproj
            }
        }
        return nil
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 语言根：注入生效语言的 locale，切换时整棵重挂
// 挂在每棵 SwiftUI 树的根（UIKit 壳里每个 Hosting 各是一棵树）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct CCLanguageRoot: ViewModifier {
    @ObservedObject private var language = CCLanguage.shared

    func body(content: Content) -> some View {
        content
            .environment(\.locale, language.locale)
            .id(language.epoch)
    }
}

public extension View {
    func ccLanguageRoot() -> some View { modifier(CCLanguageRoot()) }
}
