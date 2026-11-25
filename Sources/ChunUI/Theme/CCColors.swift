/**
 * ╔═══════════════════════════════════════════════════════════════════════════╗
 * ║                          CCColors.swift                                    ║
 * ║                    可配置语义化颜色系统                                     ║
 * ╚═══════════════════════════════════════════════════════════════════════════╝
 *
 * [INPUT]: Hex 颜色字符串 或 Color 实例
 * [OUTPUT]: 支持 Light/Dark 自适应的语义颜色（全体 nonisolated 纯值：shader/visualEffect 非隔离闭包可直取，新增成员保持 nonisolated）
 * [POS]: DesignSystem/Theme - 颜色配置核心
 *
 * 设计风格: Monochrome Neon Pink (极致黑白粉 · Laper 黑白灰阶移植)
 * - Primary: #ff00c8 (霓虹粉/品红)
 * - 灰阶：画布近白 #F7F7F9（f2f2f7↔fcfcfc 折中）、卡片纯白抬升；sidebar(#EBEBF0) < panel(#F7F7FA) < card(#fff)
 * - Dark 取 Laper zinc 系: #18181b / #27272a / #3f3f46 / #a1a1aa
 * - 功能色走品红同轴的冷调潘通：destructive = Raspberry Wine / Very Berry；success = Biscay Green 碧玺绿（禁交通灯红绿）
 *
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCColors 颜色配置
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// 语义化颜色配置
nonisolated public struct CCColors: Sendable {

    // ──────────────────────────────────────────────────────────────────
    // 基础语义色
    // ──────────────────────────────────────────────────────────────────

    /// 主背景色 - 页面底层
    public var background: Color

    /// 主前景色 - 主要文字、图标
    public var foreground: Color

    /// 卡片背景
    public var card: Color

    /// 卡片前景
    public var cardForeground: Color

    /// 面板底 - background 与 sidebar 的中点，给卡片留出可见级差（Laper --panel）
    public var panel: Color

    /// 侧边栏底 - 三级灰阶最深一档：sidebar < panel < card（Laper --sidebar）
    public var sidebarBg: Color

    /// 侧边栏选中底 - 安静实色灰块（Laper --sidebar-accent）
    public var sidebarAccent: Color

    // ──────────────────────────────────────────────────────────────────
    // 主题色
    // ──────────────────────────────────────────────────────────────────

    /// 主色调 - 品牌色、主要交互元素
    public var primary: Color

    /// 主色调前景 - 主色调上的文字
    public var primaryForeground: Color

    /// 次要色 - 次要交互元素
    public var secondary: Color

    /// 次要色前景
    public var secondaryForeground: Color

    // ──────────────────────────────────────────────────────────────────
    // 静音色（低对比度）
    // ──────────────────────────────────────────────────────────────────

    /// 静音背景 - 次要区域
    public var muted: Color

    /// 静音前景 - 次要文字、占位符
    public var mutedForeground: Color

    // ──────────────────────────────────────────────────────────────────
    // 强调与功能色
    // ──────────────────────────────────────────────────────────────────

    /// 强调背景 - hover、选中状态
    public var accent: Color

    /// 强调前景
    public var accentForeground: Color

    /// 危险色 - 删除、错误
    public var destructive: Color

    /// 危险色前景
    public var destructiveForeground: Color

    /// 成功色
    public var success: Color

    /// 警告色
    public var warning: Color

    /// 信息色
    public var info: Color

    // ──────────────────────────────────────────────────────────────────
    // 边界与输入
    // ──────────────────────────────────────────────────────────────────

    /// 边框色
    public var border: Color

    /// 输入框边框
    public var input: Color

    /// 焦点环
    public var ring: Color

    // ──────────────────────────────────────────────────────────────────
    // 阴影与遮罩
    // ──────────────────────────────────────────────────────────────────

    /// 阴影色
    public var shadow: Color

    /// 遮罩色
    public var overlay: Color

    // ──────────────────────────────────────────────────────────────────
    // 特殊卡片色
    // ──────────────────────────────────────────────────────────────────

    /// 深色卡片背景
    public var darkCard: Color

    /// 深色卡片前景
    public var darkCardForeground: Color

    /// 骨架图颜色
    public var skeleton: Color

    // ──────────────────────────────────────────────────────────────────
    // 图表色
    // ──────────────────────────────────────────────────────────────────

    /// 图表调色板
    public var chart: ChartColors

    /// 图表颜色配置
    public struct ChartColors: Sendable {
        public var color1: Color
        public var color2: Color
        public var color3: Color
        public var color4: Color
        public var color5: Color

        public init(
            color1: Color = .hex("ff00c8"),
            color2: Color = .hex("9000ff"),
            color3: Color = .hex("00e5ff"),
            color4: Color = .hex("00ffcc"),
            color5: Color = .hex("ffe600")
        ) {
            self.color1 = color1
            self.color2 = color2
            self.color3 = color3
            self.color4 = color4
            self.color5 = color5
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 预设颜色配置
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

nonisolated public extension CCColors {

    /// 当前生效调色板（ChunUI.configure 写入；组件经 Color.cc 只读）
    nonisolated(unsafe) static var current: CCColors = .default

    /// 默认配置 - Chat0IM Monochrome Neon Pink 极致黑白粉
    /// 灰阶取自 shadcn OKLCH 系统换算 (chroma=0 → 纯灰)，主色霓虹粉不变
    static let `default` = CCColors(
        // ══════════════════════════════════════════════════════════════
        // 基础语义色 (oklch 0.9551/0.3211 ↔ 0.2178/0.8853)
        // ══════════════════════════════════════════════════════════════
        // 画布近白 #F7F7F9（f2f2f7 与 fcfcfc 折中），卡片纯白抬升才显优雅
        background: .adaptive(light: .hex("f7f7f9"), dark: .hex("18181b")),
        foreground: .adaptive(light: .hex("171717"), dark: .hex("fafafa")),
        card: .adaptive(light: .hex("ffffff"), dark: .hex("27272a")),
        cardForeground: .adaptive(light: .hex("171717"), dark: .hex("fafafa")),
        panel: .adaptive(light: .hex("f7f7fa"), dark: .hex("1f1f22")),
        sidebarBg: .adaptive(light: .hex("ebebf0"), dark: .hex("141416")),
        sidebarAccent: .adaptive(light: .hex("e0e0e6"), dark: .hex("2e2e33")),

        // ══════════════════════════════════════════════════════════════
        // 主题色 - 霓虹粉 #ff00c8 (唯一彩色，保留不动)
        // ══════════════════════════════════════════════════════════════
        primary: .hex("ff00c8"),
        primaryForeground: .hex("ffffff"),

        // 次要色：比画布略深一档，表单块/chip 底
        secondary: .adaptive(light: .hex("e8e8ed"), dark: .hex("27272a")),
        secondaryForeground: .adaptive(light: .hex("171717"), dark: .hex("fafafa")),

        // ══════════════════════════════════════════════════════════════
        // 静音色
        // ══════════════════════════════════════════════════════════════
        muted: .adaptive(light: .hex("e8e8ed"), dark: .hex("27272a")),
        mutedForeground: .adaptive(light: .hex("6b6b6b"), dark: .hex("a1a1aa")),

        // ══════════════════════════════════════════════════════════════
        // 强调色 - 灰阶 hover/选中
        // ══════════════════════════════════════════════════════════════
        accent: .adaptive(light: .hex("dedee5"), dark: .hex("3f3f46")),
        accentForeground: .adaptive(light: .hex("171717"), dark: .hex("fafafa")),

        // 功能色：与品红 #ff00c8 同轴冷调，禁交通灯砖红/草绿
        // destructive = Pantone 18-1950 Raspberry Wine / 18-2043 Very Berry
        destructive: .adaptive(light: .hex("c13b5f"), dark: .hex("e07a94")),
        destructiveForeground: .hex("ffffff"),
        // success = Pantone 17-5641 Biscay Green（品红的时尚互补：碧玺青绿）
        success: .adaptive(light: .hex("2f9e8f"), dark: .hex("5ec4b4")),
        warning: .adaptive(light: .hex("666666"), dark: .hex("a0a0a0")),
        info: .adaptive(light: .hex("909090"), dark: .hex("808080")),

        // ══════════════════════════════════════════════════════════════
        // 边界与输入
        // ══════════════════════════════════════════════════════════════
        border: .adaptive(light: .hex("dcdce3"), dark: .hex("3f3f46")),
        input: .adaptive(light: .hex("e8e8ed"), dark: .hex("34343a")),
        ring: .hex("ff00c8"),

        // ══════════════════════════════════════════════════════════════
        // 阴影
        // ══════════════════════════════════════════════════════════════
        shadow: .black,
        overlay: .black.opacity(0.5),

        // ══════════════════════════════════════════════════════════════
        // 特殊卡片
        // ══════════════════════════════════════════════════════════════
        darkCard: .hex("1a1a1a"),
        darkCardForeground: .hex("d9d9d9"),
        skeleton: .adaptive(light: .hex("e0e0e6"), dark: .hex("2e2e33")),

        // ══════════════════════════════════════════════════════════════
        // 图表色 - 粉 + 灰阶阶梯 (chart-1..5)
        // ══════════════════════════════════════════════════════════════
        chart: .init(
            color1: .hex("ff00c8"),                                        // 霓虹粉
            color2: .adaptive(light: .hex("606060"), dark: .hex("a0a0a0")), // 深灰
            color3: .adaptive(light: .hex("909090"), dark: .hex("707070")), // 中灰
            color4: .adaptive(light: .hex("a8a8a8"), dark: .hex("585858")), // 次浅灰
            color5: .adaptive(light: .hex("c0c0c0"), dark: .hex("404040"))  // 浅灰
        )
    )
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Color 扩展
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

nonisolated public extension Color {

    /// 从 Hex 字符串创建颜色
    static func hex(_ string: String) -> Color {
        Color(hex: string)
    }

    /// 从 Hex 字符串初始化
    public init(hex string: String) {
        var hexString = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexString.hasPrefix("#") {
            hexString.remove(at: hexString.startIndex)
        }

        var rgb: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgb)

        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0

        self.init(red: r, green: g, blue: b)
    }

    /// Light/Dark 自适应颜色
    static func adaptive(light: Color, dark: Color) -> Color {
        #if canImport(UIKit)
        Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(dark)
                : UIColor(light)
        })
        #else
        light
        #endif
    }

    /// 纯值换算成 RGB SIMD（喂 Metal 着色器）；nonisolated 供 visualEffect / shader 的非隔离闭包直取（模块默认 MainActor）
    nonisolated func toRGB() -> SIMD3<Float> {
        #if canImport(UIKit)
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return SIMD3<Float>(Float(red), Float(green), Float(blue))
        #else
        return SIMD3<Float>(0, 0, 0)
        #endif
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 便捷访问 (Color.cc.xxx)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

nonisolated public extension Color {
    /// 设计系统颜色命名空间
    static var cc: CCColorAccessor { CCColorAccessor() }
}

/// 颜色便捷访问器（使用默认主题）
nonisolated public struct CCColorAccessor {
    private var colors: CCColors { CCColors.current }

    // 基础色
    public var background: Color { colors.background }
    public var foreground: Color { colors.foreground }
    public var card: Color { colors.card }
    public var cardForeground: Color { colors.cardForeground }
    public var panel: Color { colors.panel }
    public var sidebarBg: Color { colors.sidebarBg }
    public var sidebarAccent: Color { colors.sidebarAccent }

    // 主题色
    public var primary: Color { colors.primary }
    public var primaryForeground: Color { colors.primaryForeground }
    public var secondary: Color { colors.secondary }
    public var secondaryForeground: Color { colors.secondaryForeground }

    // 静音色
    public var muted: Color { colors.muted }
    public var mutedForeground: Color { colors.mutedForeground }

    // 强调与功能色
    public var accent: Color { colors.accent }
    public var accentForeground: Color { colors.accentForeground }
    public var destructive: Color { colors.destructive }
    public var destructiveForeground: Color { colors.destructiveForeground }
    public var success: Color { colors.success }
    public var warning: Color { colors.warning }
    public var info: Color { colors.info }

    // 边界
    public var border: Color { colors.border }
    public var input: Color { colors.input }
    public var ring: Color { colors.ring }

    // 阴影
    public var shadow: Color { colors.shadow }
    public var overlay: Color { colors.overlay }

    // 特殊
    public var darkCard: Color { colors.darkCard }
    public var darkCardForeground: Color { colors.darkCardForeground }
    public var skeleton: Color { colors.skeleton }

    // 图表
    public var chart1: Color { colors.chart.color1 }
    public var chart2: Color { colors.chart.color2 }
    public var chart3: Color { colors.chart.color3 }
    public var chart4: Color { colors.chart.color4 }
    public var chart5: Color { colors.chart.color5 }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Neon 色板 (角色卡片专用，黑白粉化：灰阶阶梯 + 品牌粉)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 语义名保留以兼容后端 cardColor 契约，色值归入黑白粉系统

    /// 深灰一档 (原赛博棕)
    public var neonBrown: Color { .hex("4a4a4a") }

    /// 深灰二档 (原赛博草绿)
    public var neonGreen: Color { .hex("5a5a5a") }

    /// 深灰三档 (原迷幻紫)
    public var neonPurple: Color { .hex("3a3a3a") }

    /// 深灰四档 (原宝蓝)
    public var neonBlue: Color { .hex("2a2a2a") }

    /// 霓虹粉 - 品牌主色 (唯一彩色)
    public var neonPink: Color { .hex("ff00c8") }

    /// 近黑 (原黑灰)
    public var neonGray: Color { .hex("1f1f1f") }
}
