/**
 * ╔═══════════════════════════════════════════════════════════════════════════╗
 * ║                        CCTypography.swift                                  ║
 * ║                      字体排版系统                                          ║
 * ╚═══════════════════════════════════════════════════════════════════════════╝
 *
 * [INPUT]: 字号配置；本目录 CCFontFamily（字族注入口，缺省系统字）
 * [OUTPUT]: CCTypography 字号表与 Font.cc 访问器（字经 CCFontFamily.font 取）
 * [POS]: Theme 的字号层：只管字号与粗细，字族归 CCFontFamily；宿主不注入字族时与系统字逐像素一致
 *
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCTypography 字体配置
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// 字体排版配置
public struct CCTypography: Sendable {

    // ──────────────────────────────────────────────────────────────────
    // 字号配置
    // ──────────────────────────────────────────────────────────────────

    /// 字号配置
    public var sizes: FontSizes

    /// ━━━ 三梯度字号铁律 ━━━
    /// 全应用只存在三个字号：sm 13 / base 17 / lg 24（base=设置项正文锚点，lg=页面 title）。
    /// 九个历史令牌全部折叠映射到三梯度上，禁止第四个字号；
    /// 唯一法定例外：tabbar 专用 16pt 恒粗体（比 base 小一档，选中只变色不变字）。
    /// 豁免域：SF Symbol/Pika 图标字形尺寸、订阅卡艺术数字（graphics 非 typography）。
    public struct FontSizes: Sendable {
        public var hero: CGFloat       // 34：登录页 hero display 法定例外（非正文梯度）
        public var title1: CGFloat     // → lg 24
        public var title2: CGFloat     // → lg 24（页面 title 锚点）
        public var title3: CGFloat     // → base 17
        public var body: CGFloat       // → base 17（设置项正文锚点）
        public var callout: CGFloat    // → base 17
        public var subheadline: CGFloat // → base 17
        public var footnote: CGFloat   // → sm 13
        public var caption: CGFloat    // → sm 13

        public init(
            hero: CGFloat = 34,
            title1: CGFloat = 24,
            title2: CGFloat = 24,
            title3: CGFloat = 17,
            body: CGFloat = 17,
            callout: CGFloat = 17,
            subheadline: CGFloat = 17,
            footnote: CGFloat = 13,
            caption: CGFloat = 13
        ) {
            self.hero = hero
            self.title1 = title1
            self.title2 = title2
            self.title3 = title3
            self.body = body
            self.callout = callout
            self.subheadline = subheadline
            self.footnote = footnote
            self.caption = caption
        }
    }

    // ──────────────────────────────────────────────────────────────────
    // 初始化
    // ──────────────────────────────────────────────────────────────────

    public init(sizes: FontSizes = .init()) {
        self.sizes = sizes
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 预设配置
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public extension CCTypography {

    /// 默认配置
    public static let `default` = CCTypography()

    /// 缺省字号表（历史名；字族由 CCFontFamily.current 决定）
    public static let system = CCTypography()
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 字体工厂方法
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public extension CCTypography {

    /// 创建字体（字族经 CCFontFamily：缺省系统字）
    public func font(size: CGFloat, bold: Bool = false) -> Font {
        CCFontFamily.font(size: size, weight: bold ? .semibold : .regular)
    }

    /// 创建等宽字体（系统字时取等宽设计；宿主字族时用字族本身）
    public func monoFont(size: CGFloat) -> Font {
        CCFontFamily.font(size: size, design: .monospaced)
    }

    // 预设字体快捷方法
    public var hero: Font { font(size: sizes.hero) }
    public var heroBold: Font { font(size: sizes.hero, bold: true) }
    public var title1: Font { font(size: sizes.title1) }
    public var title1Bold: Font { font(size: sizes.title1, bold: true) }
    public var title2: Font { font(size: sizes.title2) }
    public var title2Bold: Font { font(size: sizes.title2, bold: true) }
    public var title3: Font { font(size: sizes.title3) }
    public var title3Bold: Font { font(size: sizes.title3, bold: true) }
    public var body: Font { font(size: sizes.body) }
    public var bodyBold: Font { font(size: sizes.body, bold: true) }
    public var callout: Font { font(size: sizes.callout) }
    public var calloutBold: Font { font(size: sizes.callout, bold: true) }
    public var subheadline: Font { font(size: sizes.subheadline) }
    public var subheadlineBold: Font { font(size: sizes.subheadline, bold: true) }
    public var footnote: Font { font(size: sizes.footnote) }
    public var footnoteBold: Font { font(size: sizes.footnote, bold: true) }
    public var caption: Font { font(size: sizes.caption) }
    public var captionBold: Font { font(size: sizes.caption, bold: true) }

    // ━━━ 三梯度语义名（新代码优先使用）━━━
    public var sm: Font { font(size: sizes.footnote) }
    public var smBold: Font { font(size: sizes.footnote, bold: true) }
    public var base: Font { font(size: sizes.body) }
    public var baseBold: Font { font(size: sizes.body, bold: true) }
    public var lg: Font { font(size: sizes.title2) }
    public var lgBold: Font { font(size: sizes.title2, bold: true) }
    /// tabbar 专用：16pt 恒粗体（唯一法定例外，比 base 小一档）
    public var tabbar: Font { font(size: 16, bold: true) }
    /// tabbar 非中文紧凑档：12pt 恒粗体（西文/长词语言防截断，与 16pt 同属 tabbar 法定例外）
    public var tabbarCompact: Font { font(size: 12, bold: true) }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Font 扩展
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// MARK: - 便捷访问 (Font.cc.xxx)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public extension Font {
    /// 设计系统字体命名空间
    public static var cc: CCFontAccessor { CCFontAccessor() }
}

/// 字体便捷访问器
public struct CCFontAccessor {
    private var typography: CCTypography { .system }

    // 标题字体
    public var hero: Font { typography.hero }
    public var heroBold: Font { typography.heroBold }
    public var title1: Font { typography.title1 }
    public var title1Bold: Font { typography.title1Bold }
    public var title2: Font { typography.title2 }
    public var title2Bold: Font { typography.title2Bold }
    public var title3: Font { typography.title3 }
    public var title3Bold: Font { typography.title3Bold }

    // 正文字体
    public var body: Font { typography.body }
    public var bodyBold: Font { typography.bodyBold }
    public var callout: Font { typography.callout }
    public var calloutBold: Font { typography.calloutBold }
    public var subheadline: Font { typography.subheadline }
    public var subheadlineBold: Font { typography.subheadlineBold }
    public var footnote: Font { typography.footnote }
    public var footnoteBold: Font { typography.footnoteBold }
    public var caption: Font { typography.caption }
    public var captionBold: Font { typography.captionBold }

    // 三梯度语义名（sm 13 / base 16 / lg 24，新代码优先使用）
    public var sm: Font { typography.sm }
    public var smBold: Font { typography.smBold }
    public var base: Font { typography.base }
    public var baseBold: Font { typography.baseBold }
    public var lg: Font { typography.lg }
    public var lgBold: Font { typography.lgBold }
    /// tabbar 专用 16pt 恒粗体
    public var tabbar: Font { typography.tabbar }
    /// tabbar 非中文紧凑档 12pt 恒粗体
    public var tabbarCompact: Font { typography.tabbarCompact }

    // 数字字体
    public func mono(_ size: CGFloat) -> Font { typography.monoFont(size: size) }
    public var monoLarge: Font { typography.monoFont(size: 28) }
    public var monoMedium: Font { typography.monoFont(size: 20) }
    public var monoSmall: Font { typography.monoFont(size: 14) }

    // 自定义尺寸
    public func custom(_ size: CGFloat, bold: Bool = false) -> Font {
        typography.font(size: size, bold: bold)
    }
}
