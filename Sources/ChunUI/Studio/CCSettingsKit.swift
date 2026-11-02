/**
 * [INPUT]: 依赖 Components 的 CCFormSection / CCFormRow / CCFormIcon / CCFormCheck / CCFormTokens、Studio 的 CCStudio / CCStudioText /
 *          CCStudioWorks / CCAppStore / CCLanguage / CCAppearance、Theme 的 Color.cc
 * [OUTPUT]: 对外提供 CCSettingsItem（一行的数据）、CCSettingsGroup（一组卡）、CCSettingsStack（页内分组栈）、
 *           CCStudioGroups（信息组 · 更多组 · 退出登录 · 通用组里的语言与外观两行）、CCWorksGroup（其他作品）、
 *           CCLanguageGroup / CCAppearanceGroup（语言页与外观页的单选卡，选中轻触感 + 可选 onPick）、CCSettingsSignature（两行落款）
 * [POS]: Studio 层的设置页骨架，单仓根「设置页范式」的唯一实现。四个 App 的设置主页与子页只拼这些件：
 *        页序 资料头 → 账号 · 通用 · 信息 · 其他作品 · 更多 → 退出登录 → 落款；几何走 CCFormTokens，颜色字号走宿主注入的 Color.cc / Font.cc，
 *        图标一律 Pika。页面外壳（导航、页头、资料头）留在宿主
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 一行的数据：名字 · Pika 图标 · 灰色现值；危险行标红不带 ›
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct CCSettingsItem: Identifiable {
    public let id: String
    public let title: String
    public let icon: String?
    public let subtitle: String?
    public let value: String?
    /// 现值前的提醒红点
    public let badge: Bool
    public let destructive: Bool
    public let action: () -> Void

    public init(_ title: String, icon: String?, subtitle: String? = nil, value: String? = nil, badge: Bool = false,
                destructive: Bool = false, id: String? = nil, action: @escaping () -> Void) {
        self.id = id ?? title
        self.title = title
        self.icon = icon
        self.subtitle = subtitle
        self.value = value
        self.badge = badge
        self.destructive = destructive
        self.action = action
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 一组卡：空表整组不出；末行不画细线
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct CCSettingsGroup: View {
    let title: String?
    let items: [CCSettingsItem]

    public init(_ title: String?, items: [CCSettingsItem]) {
        self.title = title
        self.items = items
    }

    public var body: some View {
        if !items.isEmpty {
            CCFormSection(title) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    CCFormRow(item.title, subtitle: item.subtitle, value: item.value, badge: item.badge,
                              chevron: !item.destructive, destructive: item.destructive,
                              divider: index < items.count - 1, action: item.action) {
                        CCFormIcon(item.icon, tint: item.destructive ? .cc.destructive : .cc.foreground)
                    } accessory: { EmptyView() }
                }
            }
        }
    }
}

/// 页内分组栈：组间 24、离屏 16、末组下 48；顶由宿主页头让出
public struct CCSettingsStack<Content: View>: View {
    let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: CCFormTokens.gap) { content }
            .padding(.horizontal, CCFormTokens.inset)
            .padding(.bottom, CCFormTokens.pageBottom)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 四端一字不差的行：宿主只给自己的去向（关于页、意见箱、语言页…）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public enum CCStudioGroups {
    /// 通用组里的「语言」行：现值是所选语言的名字
    public static func languageItem(action: @escaping () -> Void) -> CCSettingsItem {
        let language = CCLanguage.shared
        return CCSettingsItem(CCStudioText.language, icon: "translate",
                              value: language.displayName(language.selection), id: "language", action: action)
    }

    /// 通用组里的「外观」行
    public static func appearanceItem(action: @escaping () -> Void) -> CCSettingsItem {
        CCSettingsItem(CCStudioText.appearance, icon: "color-palette",
                       value: CCAppearance.shared.mode.title, id: "appearance", action: action)
    }

    /// 信息组固定四行：关于（现值 = 版本）· 意见反馈（现值 = 新修复数等）· 评分 · 分享
    public static func info(feedbackValue: String? = nil, feedbackBadge: Bool = false, onAbout: @escaping () -> Void,
                            onFeedback: @escaping () -> Void) -> [CCSettingsItem] {
        [
            CCSettingsItem(CCStudioText.about, icon: "information-circle", value: version, id: "about", action: onAbout),
            CCSettingsItem(CCStudioText.feedback, icon: "message-default", value: feedbackValue, badge: feedbackBadge,
                           id: "feedback", action: onFeedback),
            CCSettingsItem(CCStudioText.rate, icon: "star", id: "rate", action: CCStudio.rate),
            CCSettingsItem(CCStudioText.share, icon: "share01", id: "share", action: CCStudio.share),
        ]
    }

    /// 更多组：开发者 · 小红书 · X · 本应用自己的一行
    public static func more(own: CCSettingsItem? = nil) -> [CCSettingsItem] {
        [
            CCSettingsItem(CCStudioText.developer, icon: "code", id: "developer") { CCStudio.openURL(CCStudio.developerURL) },
            CCSettingsItem(CCStudioText.xiaohongshu, icon: "heart", id: "xiaohongshu") { CCStudio.openURL(CCStudio.xiaohongshuURL) },
            CCSettingsItem(CCStudioText.x, icon: "x-com", id: "x") { CCStudio.openURL(CCStudio.xURL) },
        ] + [own].compactMap { $0 }
    }

    /// 退出登录：无组名、独占一组、标红
    public static func signOut(action: @escaping () -> Void) -> [CCSettingsItem] {
        [CCSettingsItem(CCStudioText.signOut, icon: "log-out-right", destructive: true, id: "sign-out", action: action)]
    }

    /// 本 App 版本：1.2.0 (62)
    public static var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? ""
        let build = info?["CFBundleVersion"] as? String ?? ""
        return build.isEmpty ? short : "\(short) (\(build))"
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 其他作品：前导是 App 图标，副标题作现值，点按升起应用内商店页；空表整组不出
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct CCWorksGroup: View {
    @ObservedObject private var studio = CCStudioWorks.shared

    /// App 图标边长与圆角（系统图标比例 22.4%）
    private let side: CGFloat = 28
    private var radius: CGFloat { side * 0.224 }

    public init() {}

    /// 容器恒在：空表时 Group 没有子视图，挂在它上面的 .task 永不触发（冷启动无缓存即永远取不到）；VStack 本身是视图，task 照常起
    public var body: some View {
        VStack(spacing: 0) {
            if !studio.works.isEmpty {
                CCFormSection(CCStudioText.sectionWorks) {
                    ForEach(Array(studio.works.enumerated()), id: \.element.id) { index, work in
                        CCFormRow(work.name, value: work.tagline, divider: index < studio.works.count - 1,
                                  leadingWidth: side, action: { open(work) }) {
                            artwork(work)
                        } accessory: { EmptyView() }
                    }
                }
            }
        }
        .task { await studio.refresh() }
    }

    private func artwork(_ work: CCWork) -> some View {
        AsyncImage(url: URL(string: work.iconURL)) { image in
            image.resizable().scaledToFill()
        } placeholder: {
            Color.cc.muted
        }
        .frame(width: side, height: side)
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .stroke(Color.cc.border.opacity(0.6), lineWidth: CCFormTokens.hairline)
        }
    }

    private func open(_ work: CCWork) {
        CCAppStore.present(appStoreID: work.appStoreID, fallback: URL(string: work.storeURL))
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 子页的单选卡：语言、外观。选中即生效，不需要重启
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct CCLanguageGroup: View {
    @ObservedObject private var language = CCLanguage.shared
    private let onPick: ((String) -> Void)?

    /// onPick：选中后的宿主动作（如收起 sheet）；切换本身已即时生效
    public init(onPick: ((String) -> Void)? = nil) {
        self.onPick = onPick
    }

    private var options: [String] { [CCLanguage.system] + language.available }

    public var body: some View {
        CCFormSection {
            ForEach(Array(options.enumerated()), id: \.element) { index, option in
                CCFormRow(language.displayName(option), chevron: false, divider: index < options.count - 1,
                          leadingWidth: option == CCLanguage.system ? CCFormTokens.icon : nil,
                          action: { select(option) }) {
                    CCFormIcon(option == CCLanguage.system ? "screen-check" : nil)
                } accessory: {
                    CCFormCheck(isOn: language.selection == option)
                }
            }
        }
    }

    private func select(_ option: String) {
        CCStudioHaptic.pick()
        if option != language.selection { language.select(option) }
        onPick?(option)
    }
}

public struct CCAppearanceGroup: View {
    @ObservedObject private var appearance = CCAppearance.shared
    private let onPick: ((CCAppearance.Mode) -> Void)?

    public init(onPick: ((CCAppearance.Mode) -> Void)? = nil) {
        self.onPick = onPick
    }

    public var body: some View {
        CCFormSection {
            ForEach(Array(CCAppearance.Mode.allCases.enumerated()), id: \.element) { index, mode in
                CCFormRow(mode.title, chevron: false, divider: index < CCAppearance.Mode.allCases.count - 1,
                          action: { pick(mode) }) {
                    CCFormIcon(mode.icon)
                } accessory: {
                    CCFormCheck(isOn: appearance.mode == mode)
                }
            }
        }
    }

    private func pick(_ mode: CCAppearance.Mode) {
        CCStudioHaptic.pick()
        if mode != appearance.mode { appearance.select(mode) }
        onPick?(mode)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 单选的轻触感：尊重宿主的触感开关（ChunUI.hapticsEnabled）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

enum CCStudioHaptic {
    static func pick() {
        guard ChunUI.hapticsEnabled else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 两行落款：居中、淡字；文案由宿主给（品牌名 · 版权）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct CCSettingsSignature: View {
    let lines: [String]

    public init(_ lines: String...) {
        self.lines = lines
    }

    public var body: some View {
        VStack(spacing: 4) {
            ForEach(lines, id: \.self) { line in
                Text(line)
                    .font(.cc.caption)
                    .foregroundStyle(Color.cc.mutedForeground.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
    }
}
