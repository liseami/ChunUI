/**
 * [INPUT]: 依赖 Components 的 CCSmoothCornerShape（平滑圆角）、CCSkin 与 CCSkinPaint（卡面质感）、PikaIcon、ThinLine 同款细线色 Color.cc.border；Theme 的 Color.cc.*、Font.cc.* 三梯度
 * [OUTPUT]: 对外提供 CCFormTokens（分组几何令牌）、CCFormStyle（宿主皮肤：行字号、小字号）、CCFormCardShape（卡轮廓）、CCFormCardSurface（卡面，四端唯一）、CCFormSection（组名 · 卡 · 脚注）、
 *           CCFormRow（前导 · 名字[+副标题] · 红点 · 灰色现值 · 附件 · ›）、CCFormNote（卡内说明段）、CCFormIcon（单色图标前导）、CCFormCheck（单选勾）、CCFormRowPressStyle（行按下高亮）
 * [POS]: Components 的分组表单范式，几何逐值同构胃之书 BellyFormSection（源自 Cromma CCGroupList）：设置主页与全部设置子页共用一副卡。
 *        与旧 CCSettingRow + ccGroupCard 并存：旧件仍服务对象详情等非设置页，设置类页面一律用本件。颜色走宿主调色板；字号走 CCFormStyle（缺省行字 base、小字 sm），四端各注入自己的字号；卡面只有本文件 CCFormCardSurface 一副（同目录 CCSkin.card 九层皮经 CCSkinPaint 画），四端逐像素一致
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 令牌：数值逐字对齐胃之书 BellyFormTokens（Cromma group* / settings* / rowPress*）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public enum CCFormTokens {
    /// 卡离屏幕两侧
    public static let inset: CGFloat = 16
    /// 卡的平滑圆角与平滑度
    public static let radius: CGFloat = 24
    public static let smoothing: CGFloat = 0.6
    /// 组与组之间
    public static let gap: CGFloat = 24
    /// 组名、卡、脚注之间
    public static let headerGap: CGFloat = 8
    /// 一行的最小高、左右内边距
    public static let rowHeight: CGFloat = 50
    public static let rowInset: CGFloat = 16
    /// 前导位宽（单色字形边长）与它到文字的距离
    public static let icon: CGFloat = 22
    public static let iconGap: CGFloat = 14
    /// 名字与现值之间至少留白
    public static let valueGap: CGFloat = 8
    /// 行间细线
    public static let hairline: CGFloat = 0.5
    /// 现值前的提醒红点直径
    public static let badge: CGFloat = 8
    /// › 在灰色上再淡一档
    public static let chevronOpacity: Double = 0.6
    /// 末组下留白；顶由页头让出
    public static let pageBottom: CGFloat = 48
    /// 行的按下高亮：前景色透明度、最短亮起、淡出
    public static let pressOpacity: Double = 0.08
    public static let pressHold: Double = 0.12
    public static let pressFade: Double = 0.26
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 宿主皮肤：骨架与卡面四端统一，品牌只留字号——几何走令牌不可改，卡面只有 CCFormCardSurface 一副，字号由宿主启动时注入一次
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct CCFormStyle {
    /// 行名字、现值、说明段标题
    public var rowFont: Font
    /// 组名、脚注、行副标题、说明段正文
    public var captionFont: Font

    public init(rowFont: Font = .cc.base, captionFont: Font = .cc.sm) {
        self.rowFont = rowFont
        self.captionFont = captionFont
    }

    /// 旧入口：卡面已收归 CCFormCardSurface（四端唯一），宿主卡面被忽略；下一个主版本删除
    @available(*, deprecated, message: "卡面四端唯一（CCFormCardSurface），不再接受宿主卡面；去掉 surface 参数")
    public init(rowFont: Font = .cc.base, captionFont: Font = .cc.sm, surface: @escaping () -> AnyView) {
        self.init(rowFont: rowFont, captionFont: captionFont)
    }

    public static var current = CCFormStyle()
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 卡轮廓与卡面：平滑圆角 24 · 0.6；卡面是 CCSkin.card 那副九层皮（对方气泡派生），四端唯一
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct CCFormCardShape: Shape {
    public init() {}

    public func path(in rect: CGRect) -> Path {
        CCSmoothCornerShape(radius: CCFormTokens.radius, smoothing: CCFormTokens.smoothing).path(in: rect)
    }
}

/// 设置卡唯一卡面：Canvas 里按 CCSkinPaint 画一次，不采样背景、不进 Material。中线暗斑横向拉成跑道：两半各贴一端，中段是纵剖面
public struct CCFormCardSurface: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.displayScale) private var displayScale

    public init() {}

    public var body: some View {
        let skin = CCSkin.card(dark: scheme == .dark)
        Canvas { ctx, size in
            let rect = CGRect(origin: .zero, size: size)
            let path = CCFormCardShape().path(in: rect).cgPath
            let pixel = 1 / max(1, displayScale)
            let plateau = Self.plateau(skin, width: size.width)
            ctx.withCGContext { cg in CCSkinPaint.draw(skin.layers, path: path, body: rect, plateau: plateau, pixel: pixel, in: cg) }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// 跑道半宽：卡宽一半减去中线光斑半径再留 4pt，光斑两端整只落在两侧圆角里
    private static func plateau(_ skin: CCSkin, width: CGFloat) -> CGFloat {
        for case let .radial(_, x, _, radius, _, _) in skin.layers where x.0 == .center {
            return max(0, width / 2 - (radius * CCSkin.unit + 4))
        }
        return 0
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 一组：组名在卡上方、脚注在卡下方，都与行文字同一起点；卡是唯一的面，行透明
// 卡侧距 inset 与组间 gap 由页面给
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct CCFormSection<Content: View>: View {
    private typealias T = CCFormTokens

    private var surface: some View { CCFormCardSurface() }

    let title: String?
    let footer: String?
    let content: Content

    public init(_ title: String? = nil, footer: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.footer = footer
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: T.headerGap) {
            if let title {
                Text(title)
                    .font(CCFormStyle.current.captionFont)
                    .foregroundStyle(Color.cc.mutedForeground)
                    .padding(.leading, T.rowInset)
            }
            VStack(spacing: 0) { content }
                .clipShape(CCFormCardShape())
                .background { surface }
            if let footer, !footer.isEmpty {
                Text(footer)
                    .font(CCFormStyle.current.captionFont)
                    .foregroundStyle(Color.cc.mutedForeground)
                    .padding(.horizontal, T.rowInset)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 单色图标前导：便捷构造用；没有图标即不占位
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct CCFormIcon: View {
    let name: String?
    let tint: Color

    public init(_ name: String?, tint: Color = .cc.foreground) {
        self.name = name
        self.tint = tint
    }

    public var body: some View {
        if let name {
            PikaIcon(name, size: CCFormTokens.icon, color: tint)
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 一行：[前导] 名字 …… 现值 [附件] ›；细线从文字起始处开始，末行传 divider: false
// 有 action 才是按钮；开关等控件放进 accessory，行本身不可点。前导是任意视图（单色图标、App 图标），宽度由 leadingWidth 声明，细线据此对齐
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct CCFormRow<Leading: View, Accessory: View>: View {
    private typealias T = CCFormTokens

    let title: String
    let subtitle: String?
    let value: String?
    /// 现值前的提醒红点（如意见箱有新修复）
    let badge: Bool
    let chevron: Bool
    let destructive: Bool
    let divider: Bool
    /// 前导位宽；nil 即没有前导
    let leadingWidth: CGFloat?
    let action: (() -> Void)?
    let leading: Leading
    let accessory: Accessory

    public init(_ title: String, subtitle: String? = nil, value: String? = nil, badge: Bool = false,
                chevron: Bool = true, destructive: Bool = false,
                divider: Bool = true, leadingWidth: CGFloat? = CCFormTokens.icon, action: (() -> Void)? = nil,
                @ViewBuilder leading: () -> Leading, @ViewBuilder accessory: () -> Accessory) {
        self.title = title
        self.subtitle = subtitle
        self.value = value
        self.badge = badge
        self.chevron = chevron
        self.destructive = destructive
        self.divider = divider
        self.leadingWidth = leadingWidth
        self.action = action
        self.leading = leading()
        self.accessory = accessory()
    }

    /// 文字起始处（细线从这里开始）
    private var textX: CGFloat {
        guard let leadingWidth else { return T.rowInset }
        return T.rowInset + leadingWidth + T.iconGap
    }

    /// 名字与图标同色：危险操作整行转危险色
    private var tint: Color { destructive ? .cc.destructive : .cc.foreground }

    public var body: some View {
        if let action {
            Button(action: action) { content }
                .buttonStyle(CCFormRowPressStyle())
        } else {
            content
        }
    }

    private var content: some View {
        HStack(spacing: T.iconGap) {
            if let leadingWidth {
                leading.frame(width: leadingWidth, height: leadingWidth)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(CCFormStyle.current.rowFont)
                    .foregroundStyle(tint)
                    .lineLimit(1)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(CCFormStyle.current.captionFont)
                        .foregroundStyle(Color.cc.mutedForeground)
                        .lineLimit(2)
                }
            }
            // 名字优先：现值先缩到 0.8 再截断，不挤名字
            .layoutPriority(1)
            Spacer(minLength: T.valueGap)
            if badge {
                Circle()
                    .fill(Color.cc.destructive)
                    .frame(width: T.badge, height: T.badge)
            }
            if let value {
                Text(value)
                    .font(CCFormStyle.current.rowFont)
                    .foregroundStyle(Color.cc.mutedForeground)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            accessory
            if chevron {
                PikaIcon("chevron-right", size: T.icon, color: .cc.mutedForeground.opacity(T.chevronOpacity))
            }
        }
        .padding(.horizontal, T.rowInset)
        .padding(.vertical, subtitle == nil ? 0 : 10)
        .frame(minHeight: T.rowHeight)
        .contentShape(Rectangle())
        .overlay(alignment: .bottom) {
            if divider {
                Rectangle()
                    .fill(Color.cc.border)
                    .frame(height: T.hairline)
                    .padding(.leading, textX)
            }
        }
    }
}

// ━━━ 便捷构造：单色图标前导（icon 为 nil 即无前导） ━━━

public extension CCFormRow where Leading == CCFormIcon {
    init(_ title: String, icon: String?, subtitle: String? = nil, value: String? = nil, badge: Bool = false,
         chevron: Bool = true, destructive: Bool = false,
         divider: Bool = true, action: (() -> Void)? = nil, @ViewBuilder accessory: () -> Accessory) {
        self.init(title, subtitle: subtitle, value: value, badge: badge, chevron: chevron, destructive: destructive, divider: divider,
                  leadingWidth: icon == nil ? nil : CCFormTokens.icon, action: action,
                  leading: { CCFormIcon(icon, tint: destructive ? .cc.destructive : .cc.foreground) }, accessory: accessory)
    }
}

public extension CCFormRow where Leading == CCFormIcon, Accessory == EmptyView {
    init(_ title: String, icon: String?, subtitle: String? = nil, value: String? = nil, badge: Bool = false,
         chevron: Bool = true, destructive: Bool = false,
         divider: Bool = true, action: (() -> Void)? = nil) {
        self.init(title, icon: icon, subtitle: subtitle, value: value, badge: badge, chevron: chevron, destructive: destructive, divider: divider,
                  action: action, accessory: { EmptyView() })
    }
}

public extension CCFormRow where Accessory == EmptyView {
    init(_ title: String, value: String? = nil, chevron: Bool = true, divider: Bool = true,
         leadingWidth: CGFloat, action: (() -> Void)? = nil, @ViewBuilder leading: () -> Leading) {
        self.init(title, value: value, chevron: chevron, destructive: false, divider: divider,
                  leadingWidth: leadingWidth, action: action, leading: leading, accessory: { EmptyView() })
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 卡内说明段：只读的粗体标题 + 多行灰字（须知、常见问题）；末段传 divider: false
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct CCFormNote: View {
    private typealias T = CCFormTokens

    let title: String
    let detail: String
    let divider: Bool

    public init(_ title: String, detail: String, divider: Bool = true) {
        self.title = title
        self.detail = detail
        self.divider = divider
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(CCFormStyle.current.rowFont.weight(.semibold))
                .foregroundStyle(Color.cc.foreground)
            Text(detail)
                .font(CCFormStyle.current.captionFont)
                .foregroundStyle(Color.cc.mutedForeground)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, T.rowInset)
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            if divider {
                Rectangle()
                    .fill(Color.cc.border)
                    .frame(height: T.hairline)
                    .padding(.leading, T.rowInset)
            }
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 单选勾：选项列表（外观、语言）的行尾附件，未选中留同宽空位，名字与现值不跳
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct CCFormCheck: View {
    let isOn: Bool

    public init(isOn: Bool) { self.isOn = isOn }

    public var body: some View {
        PikaIcon("check-tick-single", size: CCFormTokens.icon, color: .cc.primary)
            .opacity(isOn ? 1 : 0)
            .accessibilityHidden(!isOn)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 按下高亮：前景色一层（亮底压暗、暗底提亮），卡形在外层裁住
// 滚动容器把按下推迟到抬手才送达，轻点只闪一帧：亮起至少停 pressHold 秒，抬起再按 pressFade 淡去
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct CCFormRowPressStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label.background(CCFormPressHighlight(pressed: configuration.isPressed))
    }
}

private struct CCFormPressHighlight: View {
    private typealias T = CCFormTokens

    let pressed: Bool
    @State private var lit = false
    @State private var litAt = Date.distantPast
    /// 每按一次加一：迟到的熄灭只认自己那一次
    @State private var press = 0

    var body: some View {
        Rectangle()
            .fill(Color.cc.foreground)
            .opacity(lit ? T.pressOpacity : 0)
            .animation(lit ? nil : .easeOut(duration: T.pressFade), value: lit)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .onChange(of: pressed) { _, on in
                if on {
                    press += 1
                    litAt = .now
                    lit = true
                    return
                }
                let mine = press
                let wait = max(0, T.pressHold - Date.now.timeIntervalSince(litAt))
                DispatchQueue.main.asyncAfter(deadline: .now() + wait) {
                    if press == mine { lit = false }
                }
            }
    }
}
