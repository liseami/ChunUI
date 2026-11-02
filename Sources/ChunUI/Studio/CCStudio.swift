/**
 * [INPUT]: 依赖 StoreKit 的 SKStoreProductViewController、UIKit 的 UIActivityViewController 与 UIApplication.open、
 *          Presentation 的 AppHelper.topMostViewController、Studio 的 CCLanguage（取词语言）与包内 Studio.xcstrings
 * [OUTPUT]: 对外提供 CCStudio（本 App 的工作室身份：App Store id、分享文案、作品目录地址、外链出口；评分与分享动作）、
 *           CCAppStore（应用内 App Store 页）、CCStudioText（工作室通用文案，二十种语言随包）
 * [POS]: Studio 层的门面。四个 App 启动时各 configure 一次，设置页的信息组、更多组、其他作品组、语言与外观页都只读这里；
 *        工作室外链（开发者、小红书、X）只在这里写一次；configure 拿到作品目录地址即预取一次（四端同一时机，宿主不再各自预取）
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import StoreKit
import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 工作室身份
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public enum CCStudio {
    /// 工作室外链：四个 App 的「更多」组同一份
    public static let developerURL = URL(string: "https://chunxiang.ai")!
    public static let xiaohongshuURL = URL(string: "https://xhslink.com/m/8E853wuYRZM")!
    public static let xURL = URL(string: "https://x.com/chunxiangai")!

    /// 本 App 的 App Store 数字 id（评分、分享兜底）
    public private(set) static var appStoreID = ""
    /// 分享面板里的一句话：分享时才求值，切语言后自然是新语言
    public private(set) static var shareText: () -> String = { "" }
    /// 分享的链接；缺省是本 App 的 App Store 页
    public private(set) static var shareURL: URL?
    /// 本 App 中台作品目录地址（不带 lang）：…/works
    public private(set) static var worksEndpoint: URL?
    /// 外链出口：缺省交系统打开；宿主可换成应用内浏览器
    public static var openURL: (URL) -> Void = { UIApplication.shared.open($0) }

    public static func configure(appStoreID: String, shareText: @autoclosure @escaping () -> String, shareURL: URL? = nil,
                                 worksEndpoint: URL?) {
        self.appStoreID = appStoreID
        self.shareText = shareText
        self.shareURL = shareURL
        self.worksEndpoint = worksEndpoint
        // 作品目录启动即预取：进设置页时已有当前语言的结果，不等组上屏
        Task { await CCStudioWorks.shared.refresh() }
    }

    public static var storeURL: URL {
        URL(string: "https://apps.apple.com/app/id\(appStoreID)")!
    }

    /// 评分：直达 App Store 写评价页（系统评分弹窗有频控，用户主动点时可能不出）
    public static func rate() {
        guard let url = URL(string: "itms-apps://apps.apple.com/app/id\(appStoreID)?action=write-review") else { return }
        UIApplication.shared.open(url)
    }

    /// 分享：从最上层控制器升起系统分享面板
    public static func share() {
        guard let presenter = AppHelper.shared.topMostViewController() else { return }
        let items: [Any] = [shareText(), shareURL ?? storeURL].filter { !(($0 as? String)?.isEmpty ?? false) }
        let sheet = UIActivityViewController(activityItems: items, applicationActivities: nil)
        sheet.popoverPresentationController?.sourceView = presenter.view
        presenter.present(sheet, animated: true)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 应用内 App Store 页：先升起再加载，加载失败收起并交系统打开商店网址
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public enum CCAppStore {
    /// 「完成」的代理：控制器只弱引用代理，这里常驻一份
    private static let closer = Closer()

    public static func present(appStoreID: String, fallback: URL?) {
        guard let id = Int(appStoreID), let presenter = AppHelper.shared.topMostViewController() else {
            if let fallback { CCStudio.openURL(fallback) }
            return
        }
        let store = SKStoreProductViewController()
        store.delegate = closer
        presenter.present(store, animated: true)
        store.loadProduct(withParameters: [SKStoreProductParameterITunesItemIdentifier: NSNumber(value: id)]) { loaded, _ in
            guard !loaded else { return }
            Task { @MainActor in
                store.dismiss(animated: true)
                if let fallback { CCStudio.openURL(fallback) }
            }
        }
    }

    private final class Closer: NSObject, SKStoreProductViewControllerDelegate {
        func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
            viewController.dismiss(animated: true)
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 工作室通用文案：包内 Studio.xcstrings，语言跟 CCLanguage
// 宿主自己的分组（账号、通用里的业务行）用自己的文案；这里只放四个 App 一字不差的那几行
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public enum CCStudioText {
    nonisolated static func t(_ key: String) -> String {
        let bundle = CCLanguage.lproj(CCLanguageSnapshot.code, in: .module)
            ?? CCLanguage.lproj("en", in: .module) ?? .module
        return bundle.localizedString(forKey: key, value: nil, table: "Studio")
    }

    // 分组名
    public static var sectionAccount: String { t("section.account") }
    public static var sectionGeneral: String { t("section.general") }
    public static var sectionInfo: String { t("section.info") }
    public static var sectionWorks: String { t("section.works") }
    public static var sectionMore: String { t("section.more") }
    // 通用组
    public static var language: String { t("language") }
    public static var languageSystem: String { t("language.system") }
    public static var appearance: String { t("appearance") }
    public static var appearanceSystem: String { t("appearance.system") }
    public static var appearanceLight: String { t("appearance.light") }
    public static var appearanceDark: String { t("appearance.dark") }
    // 信息组
    public static var about: String { t("about") }
    public static var feedback: String { t("feedback") }
    public static var settings: String { t("settings") }
    public static var rate: String { t("rate") }
    public static var share: String { t("share") }
    // 更多组
    public static var developer: String { t("developer") }
    public static var xiaohongshu: String { t("xiaohongshu") }
    public static var x: String { t("x") }
    // 会话
    public static var signOut: String { t("sign_out") }
}
