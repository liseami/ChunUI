/**
 * [INPUT]: 依赖 SwiftUI 的 Font / Color、ChunUI 的 Color.adaptive / Color.hex（输入面三色）、Studio 的 CCStudioText.t（Studio 表取词，跟 CCLanguage）
 * [OUTPUT]: 对内提供 CCFBTokens（意见箱全部几何：页面 · 提出 · 解决 · 邀请 · 分段 · 角标 · 输入面 · 骨架 · 主钮）、CCFBFont（胃之书 Font.cc 同一张系统字号表）、CCFBText（意见箱文案）
 * [POS]: Studio/Feedback 的原始数值层；本目录其它文件不写魔法数字。数值逐字取自胃之书 FeedbackView / FeedbackResolvedView / FeedbackInviteView、
 *        DesignSystem 的 BellyRootTokens.Segment / Badge、BellyInputTokens、BellySkeletonTokens；字不走包内 Font.cc（梯度不同），一律走 CCFBFont 保证与胃之书逐像素一致
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI
import UIKit

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 字：系统字，常规 / 粗两档（胃之书 CCTypography 同表）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

enum CCFBFont {
    static func of(_ size: CGFloat, bold: Bool = false) -> Font { .system(size: size, weight: bold ? .bold : .regular) }
    static func ui(_ size: CGFloat, bold: Bool = false) -> UIFont { .systemFont(ofSize: size, weight: bold ? .bold : .regular) }

    static var title1Bold: Font { of(28, bold: true) }
    static var title2Bold: Font { of(24, bold: true) }
    static var body: Font { of(17) }
    static var bodyBold: Font { of(17, bold: true) }
    static var callout: Font { of(16) }
    static var subheadlineBold: Font { of(15, bold: true) }
    static var footnote: Font { of(13) }
    static var footnoteBold: Font { of(13, bold: true) }
    static var captionBold: Font { of(11, bold: true) }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 文案：Studio 表，语言跟 CCLanguage
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

enum CCFBText {
    nonisolated static func t(_ key: String) -> String { CCStudioText.t(key) }
    nonisolated static func f(_ key: String, _ args: CVarArg...) -> String { String(format: t(key), arguments: args) }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 数值
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

enum CCFBTokens {
    /// 页面左右边距、卡内文字起点（BellyInputTokens.pageInset / rowInset）
    static let pageInset: CGFloat = 16
    static let rowInset: CGFloat = 16

    /// 容器与「提出」（FeedbackTokens）
    enum Compose {
        static let sectionGap: CGFloat = 24
        static let titleGap: CGFloat = 8
        static let introGap: CGFloat = 6
        static let segmentTop: CGFloat = 8
        static let segmentBottom: CGFloat = 8
        static let pageTop: CGFloat = 16
        static let pageBottom: CGFloat = 24
        static let chipHeight: CGFloat = 36
        static let chipPad: CGFloat = 10
        static let chipGap: CGFloat = 8
        static let chipMinScale: CGFloat = 0.75
        static let tile: CGFloat = 88
        static let tileGap: CGFloat = 8
        static let addIcon: CGFloat = 24
        static let removeIcon: CGFloat = 12
        static let removePad: CGFloat = 5
        static let removeInset: CGFloat = 4
        static let removeBacking: Double = 0.55
    }

    /// 「解决」（ResolvedTokens）
    enum Resolved {
        static let rowGap: CGFloat = 12
        static let cardPad: CGFloat = 16
        static let blockGap: CGFloat = 10
        static let chipPadH: CGFloat = 8
        static let chipPadV: CGFloat = 3
        static let avatar: CGFloat = 22
        static let proposerGap: CGFloat = 8
        static let contentLines = 6
        static let listTop: CGFloat = 8
        static let listBottom: CGFloat = 24
        static let bones = 3
        static let check: CGFloat = 112
        static let checkBleed: CGFloat = 18
        static let checkOpacity: Double = 0.16
        static let emptyTop: CGFloat = 40
        /// 分页：每页条数、加载更多冷却秒数、触底位高与静置浓度（CCListDataViewModel / CCGenericLoadMoreFooter）
        static let pageSize = 10
        static let cooldown: TimeInterval = 2
        static let footerHeight: CGFloat = 60
        static let footerIdle: CGFloat = 0.6
        static let footerLines = 2
        /// 空态（CCDesigin.CCEmptyView）：图宽、块间距、字上提
        static let emptyArt: CGFloat = 240
        static let emptyGap: CGFloat = 12
        static let emptyLift: CGFloat = -24
    }

    /// 「邀请」（InviteTokens）
    enum Invite {
        static let pageTop: CGFloat = 32
        static let pageBottom: CGFloat = 32
        static let blockGap: CGFloat = 32
        static let textGap: CGFloat = 8
        static let artWidth: CGFloat = 264
        static let artHeight: CGFloat = 176
        static let statSize: CGFloat = 56
        static let drawDuration: Double = 1.1
        static let nodeStagger: Double = 0.22
    }

    /// 分段栏极简态（BellyRootTokens.Segment；不移植图标与跟手分页）
    enum Segment {
        static let height: CGFloat = 36
        static let thumbInset: CGFloat = 3
        static let fade: CGFloat = 0.5
        static let border: CGFloat = 0.67
        static let padLeading: CGFloat = 8
        static let padTrailing: CGFloat = 10
        static let fontSize: CGFloat = 16
        static let pickTint: CGFloat = 0.06
        static let badgeGap: CGFloat = 4
    }

    /// 计数角标（BellyRootTokens.Badge）
    enum Badge {
        static let height: CGFloat = 20
        static let padH: CGFloat = 6
        static let fontSize: CGFloat = 15
        /// 钮上摆法：角标左端半圆的圆心落在钮外接框右上角向内 inset 处
        static let inset: CGFloat = 9
    }

    /// 输入面（BellyInputTokens.Number / Seconds / Palette 中意见箱用到的部分）
    enum Field {
        static let rowHeight: CGFloat = 50
        static let icon: CGFloat = 22
        static let rowGap: CGFloat = 2
        static let radius: CGFloat = 12
        static let smoothing: CGFloat = 0.6
        static let border: CGFloat = 1
        static let edge: CGFloat = 1.5
        static let edgeAlpha: CGFloat = 0.06
        static let edgeAlphaDark: CGFloat = 0.3
        static let shadowY: CGFloat = 1
        static let shadowBlur: CGFloat = 3
        static let shadowAlpha: CGFloat = 0.06
        static let shadowAlphaDark: CGFloat = 0.45
        static let fillShade: CGFloat = 0.3
        static let wellInset: CGFloat = 2.5
        static let wellDrop: CGFloat = 5
        static let wellGrow: CGFloat = 0.96
        static let areaLines = 5
        static let areaMaxLines = 14
        static let motionLow: Double = 0.2
        static let field = Color.adaptive(light: .hex("FFFFFF"), dark: .hex("404040"))
        static let fieldBorder = Color.adaptive(light: .hex("D4D4D4"), dark: .hex("525252"))
        static let fieldWell = Color.adaptive(light: .hex("E5E5E5"), dark: .hex("262626"))
    }

    /// 骨架（BellySkeletonTokens.Number / Seconds / Ease）
    enum Bone {
        static let peakLight: CGFloat = 0.08
        static let peakDark: CGFloat = 0.05
        static let band: CGFloat = 1
        static let line: CGFloat = 10
        static let lineRadius: CGFloat = 4
        static let textGap: CGFloat = 8
        static let widthMin: CGFloat = 0.3
        static let widthMax: CGFloat = 1
        static let bodyMin: CGFloat = 0.7
        static let lastMin: CGFloat = 0.35
        static let lastMax: CGFloat = 0.65
        static let durationMin: Double = 1.3
        static let durationMax: Double = 1.7
        static let gate: Double = 0.3
        static let fade: Double = 0.2
        static let sweep: (Double, Double, Double, Double) = (0.42, 0, 0.58, 1)
        /// 加载更多段落位的左右内距（BellySkeletonTokens.List.inset）
        static let listInset: CGFloat = 16
    }

    /// 主钮（胃之书 CCDesigin.Button 的 large · primary）
    enum Button {
        static let height: CGFloat = 58
        static let spacing: CGFloat = 6
    }

    /// 原卡片（bellyAppleCard）
    enum Card {
        static let radius: CGFloat = 20
    }
}
