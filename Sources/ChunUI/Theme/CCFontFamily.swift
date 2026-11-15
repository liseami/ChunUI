/**
 * ╔═══════════════════════════════════════════════════════════════════════════╗
 * ║                         CCFontFamily.swift                                 ║
 * ║                      宿主字族注入口（1.4.0）                                ║
 * ╚═══════════════════════════════════════════════════════════════════════════╝
 *
 * [INPUT]: 依赖 SwiftUI 的 Font / Font.Weight / Font.Design、UIKit 的 UIFont 与 UIFontDescriptor、CoreText 的等宽数字特性常量
 * [OUTPUT]: 对外提供 CCFontFamily（宿主字族：字号 + 字重 → UIFont）、CCFontFamily.current（活体注入点，缺省 .system）、
 *           三道取字门 CCFontFamily.font(size:weight:design:) / uiFont(size:weight:) / digitsUIFont(size:weight:)
 * [POS]: Theme 的字族层，与 CCColors.current、CCFormStyle.current 同一种注入范式：宿主启动时写一次，组件每次取字时读。
 *        包内一切画文字的地方（Font.cc、意见箱 CCFBFont、角标、Markdown 代码字、翻牌字、粒子字、分段钮）都经这三道门；只画 SF Symbol / emoji 的地方保持系统字。
 *        缺省 .system 逐字回放原来的系统字调用（含 design 与等宽数字），不注入的宿主逐像素不变；
 *        注入后 design 被忽略（字族自定字形），字号固定、不随动态字体缩放（经 Font(UIFont)）
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import CoreText
import SwiftUI
import UIKit

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCFontFamily：宿主给一把「字号 + 字重 → UIFont」；nil 即系统字
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// 宿主字族。
///
/// ```swift
/// // App 启动时（ChunUI.configure 之后）
/// CCFontFamily.current = CCFontFamily { size, weight in
///     UIFont(name: weight >= .semibold ? "MyFont-SemiBold" : "MyFont-Regular", size: size)
///         ?? .systemFont(ofSize: size, weight: weight)
/// }
/// ```
///
/// 不写则是 `.system`：包内取字与 1.3 逐字相同。字族的字缺字时由系统级联兜底（CoreText 缺省行为）。
nonisolated public struct CCFontFamily: Sendable {
    /// 字号 + 字重 → 字；nil = 系统字
    let resolve: (@Sendable (CGFloat, UIFont.Weight) -> UIFont)?

    /// 宿主字族：闭包须线程安全（后台排字也会调），取不到字时自己退回系统字
    public init(_ resolve: @escaping @Sendable (CGFloat, UIFont.Weight) -> UIFont) {
        self.resolve = resolve
    }

    private init() {
        self.resolve = nil
    }

    /// 系统字（缺省）
    public static let system = CCFontFamily()

    /// 当前生效字族（宿主启动时写一次；组件经下面三道门只读）
    nonisolated(unsafe) public static var current: CCFontFamily = .system

    /// 是否注入了宿主字族
    public var isCustom: Bool { resolve != nil }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 三道取字门：系统分支逐字保留原调用，宿主分支一律固定字号
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

nonisolated public extension CCFontFamily {

    /// SwiftUI 字。系统字时 = `.system(size:weight:design:)`；宿主字族时 design 不生效
    static func font(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> Font {
        guard let resolve = current.resolve else { return .system(size: size, weight: weight, design: design) }
        return Font(resolve(size, weight.ccUIWeight))
    }

    /// UIKit / CoreText 字。系统字时 = `UIFont.systemFont(ofSize:weight:)`
    static func uiFont(size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        current.resolve?(size, weight) ?? .systemFont(ofSize: size, weight: weight)
    }

    /// 等宽数字的 UIKit 字。系统字时 = `monospacedDigitSystemFont`；宿主字族时加 tnum 特性（字族本身等宽则无变化）
    static func digitsUIFont(size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        guard let resolve = current.resolve else { return .monospacedDigitSystemFont(ofSize: size, weight: weight) }
        let base = resolve(size, weight)
        let tnum: [UIFontDescriptor.FeatureKey: Int] = [.type: kNumberSpacingType, .selector: kMonospacedNumbersSelector]
        return UIFont(descriptor: base.fontDescriptor.addingAttributes([.featureSettings: [tnum]]), size: size)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 字重换算：SwiftUI → UIKit（只在宿主字族分支用）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

nonisolated private extension Font.Weight {
    var ccUIWeight: UIFont.Weight {
        switch self {
        case .ultraLight: return .ultraLight
        case .thin: return .thin
        case .light: return .light
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        case .heavy: return .heavy
        case .black: return .black
        default: return .regular
        }
    }
}
