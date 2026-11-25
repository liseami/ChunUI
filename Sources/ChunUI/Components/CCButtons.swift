/**
 * ╔═══════════════════════════════════════════════════════════════════════════╗
 * ║                          CCButtons.swift                                  ║
 * ║                       统一按钮组件库                                        ║
 * ╚═══════════════════════════════════════════════════════════════════════════╝
 *
 * [INPUT]: 设计系统颜色、SwiftUI、AppHelper (震动反馈)、PikaIcon 模板图标、shimmer（TimelineView 扫光）
 * [OUTPUT]: Button (统一), CCTagButton, GlassIconButton/CircleButton 正圆液态玻璃按钮（regular 50·24 / small 34·16）, 返回按钮
 * [POS]: DesignSystem/Compents 按钮组件，被业务视图消费；loading 扫光走 shimmer 时钟取模，禁止 Pow repeat(.shine) 积压补播
 *
 * API:
 *   CCDesigin.Button("文字", icon: nil, size: .large/.medium/.small, variant: .primary/.secondary, enable: true) { }
 *
 * 设计规范:
 * 1. Primary / Secondary 一律转发 CCNeoButton / ccNeoChrome（圆角 height×0.38，禁胶囊）
 * 2. pinkGlassButtonStyle / softButtonStyle 是旧入口，内部已归一到 CCNeoSurface
 * 3. 交互: 按下 scale(0.97)
 *
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import Pow
import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 霓虹粉玻璃按钮样式 (Primary)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// 旧入口：有色强调钮。内部归一到 CCNeoButton.primary（圆角矩形，禁胶囊）。
public struct PinkGlassButtonStyle: ViewModifier {
    let enable: Bool

    public func body(content: Content) -> some View {
        content
            .background {
                GeometryReader { geo in
                    CCNeoSurface(
                        variant: .primary,
                        shape: RoundedRectangle.ccButton(height: max(geo.size.height, 1))
                    )
                }
            }
            .opacity(enable ? 1 : 0.5)
    }
}

extension View {
    /// 应用主色强调钮质感（转发 CCNeoSurface.primary）
    public func pinkGlassButtonStyle(enable: Bool = true) -> some View {
        modifier(PinkGlassButtonStyle(enable: enable))
    }
}

/// 旧入口：浅底凸面。内部归一到 CCNeoButton.secondary（圆角矩形，禁胶囊）。
public struct SoftButtonStyle: ViewModifier {
    let backgroundColor: Color

    public func body(content: Content) -> some View {
        content
            .background {
                GeometryReader { geo in
                    CCNeumorphRaised(
                        shape: RoundedRectangle.ccButton(height: max(geo.size.height, 1)),
                        fill: backgroundColor
                    )
                }
            }
    }
}

extension View {
    /// 应用浅底凸面质感（转发 CCNeumorphRaised）
    public func softButtonStyle(backgroundColor: Color) -> some View {
        modifier(SoftButtonStyle(backgroundColor: backgroundColor))
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 基础按钮包装器
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public extension CCDesigin {
    /// 基础按钮包装器 - label 接收 isLoading 状态
    struct CCButton<Content>: View where Content: View {
        var enable: Bool
        var action: () async -> Void
        var label: (Bool) -> Content  // 传入 isLoading
        @State var onTap: Bool = false
        @State var shake: Int = 0
        @State var isLoading: Bool = false

        public init(enable: Bool = true, action: @MainActor @escaping () async -> Void, @ViewBuilder label: @escaping (Bool) -> Content) {
            self.enable = enable
            self.action = action
            self.label = label
        }

        /// 兼容旧 API: 无参数 label
        public init(enable: Bool = true, action: @MainActor @escaping () async -> Void, @ViewBuilder label: @escaping () -> Content) {
            self.enable = enable
            self.action = action
            self.label = { _ in label() }
        }

        public var body: some View {
            label(isLoading)
                .opacity(isLoading ? 0.6 : 1)
                // ━━━ 按压缩放效果 ━━━
                .scaleEffect(onTap ? 0.97 : 1.0)
                .animation(.easeInOut(duration: 0.15), value: onTap)
                ._onButtonGesture {
                    guard isLoading == false else { return }
                    onTap = $0
                } perform: {
                    Task {
                        guard !isLoading else { return }
                        guard enable else {
                            shake += 1
                            AppHelper.shared.mada(.error)
                            return
                        }
                        AppHelper.shared.mada(.soft)
                        self.isLoading = true
                        await action()
                        self.isLoading = false
                    }
                }
                .shimmer(active: isLoading, duration: 0.8)
                .conditionalEffect(.repeat(.glow(color: Color.cc.background), every: 0.6), condition: self.isLoading)
                .changeEffect(.glow(color: Color.cc.background), value: self.onTap)
                .changeEffect(.shake(rate: .fast), value: shake)
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 按钮尺寸 & 变体
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public extension CCDesigin {
    /// 按钮尺寸
    enum ButtonSize {
        case large   // 大按钮 (height 58)
        case medium  // 中按钮 (height 46)
        case small   // 小按钮 (height 38)
    }

    /// 按钮变体
    enum ButtonVariant {
        case primary    // 主要: 粉色玻璃质感
        case secondary  // 次要: 柔和微拟物
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 统一按钮组件
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public extension CCDesigin {
    /// 统一按钮组件 - isLoading 自动管理
    ///
    /// ```swift
    /// // 大按钮 (主要) - 粉色玻璃、黑字
    /// CCDesigin.Button("开始体验") { await doSomething() }
    ///
    /// // 中按钮 (次要) - async action 执行时自动显示 loading
    /// CCDesigin.Button("取消", size: .medium, variant: .secondary) { await cancel() }
    ///
    /// // 禁用态
    /// CCDesigin.Button("处理中...", enable: false) { }
    /// ```
    struct Button: View {
        let text: String
        let icon: String?
        let size: ButtonSize
        let variant: ButtonVariant
        let enable: Bool
        let action: () async -> Void

        public init(
            _ text: String,
            icon: String? = nil,
            size: ButtonSize = .large,
            variant: ButtonVariant = .primary,
            enable: Bool = true,
            action: @escaping () async -> Void = {}
        ) {
            self.text = text
            self.icon = icon
            self.size = size
            self.variant = variant
            self.enable = enable
            self.action = action
        }

        public var body: some View {
            let neoSize: CCNeoSize = {
                switch size {
                case .small: return .small
                case .medium: return .medium
                case .large: return .large
                }
            }()
            let neoVariant: CCNeoVariant = variant == .primary ? .primary : .secondary

            if let icon {
                CCButton(enable: enable) {
                    CCTrack.onTap("btn:" + text)
                    await action()
                } label: {
                    labeledContent(icon: icon, neoSize: neoSize)
                        .ccNeoChrome(neoVariant, height: neoSize.height, disabled: !enable)
                }
            } else {
                CCNeoButton(
                    text,
                    variant: neoVariant,
                    size: neoSize,
                    fullWidth: size != .small,
                    disabled: !enable
                ) {
                    await action()
                }
            }
        }

        private func labeledContent(icon: String, neoSize: CCNeoSize) -> some View {
            HStack(alignment: .center, spacing: 6) {
                CCDesigin.ICON(
                    imageName: icon,
                    size: 24,
                    color: enable
                        ? (variant == .primary ? .cc.primaryForeground : .cc.foreground)
                        : .cc.mutedForeground
                )
                if !text.isEmpty {
                    Text(text)
                        .font(size == .small ? Font.cc.subheadlineBold : Font.cc.bodyBold)
                        .foregroundStyle(
                            enable
                                ? (variant == .primary ? Color.cc.primaryForeground : Color.cc.foreground)
                                : Color.cc.mutedForeground
                        )
                }
            }
            .padding(.horizontal, neoSize.hPadding)
            .frame(height: neoSize.height)
            .frame(maxWidth: size == .small ? nil : .infinity)
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 微拟物标签按钮
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public extension CCDesigin {
    struct CCTagButton: View {
        let icon: String
        let text: String
        var action: () async -> Void

        public init(icon: String, text: String, action: @escaping () async -> Void) {
            self.icon = icon
            self.text = text
            self.action = action
        }

        public var body: some View {
            CCDesigin.CCButton {
                await action()
            } label: {
                buttonContent
            }
        }

        @ViewBuilder
        private var buttonContent: some View {
            if #available(iOS 26, *) {
                // ━━━ iOS 26: Liquid Glass ━━━
                HStack(alignment: .center, spacing: 4) {
                    CCDesigin.ICON(imageName: self.icon, size: 16, color: .cc.mutedForeground)
                    Text(self.text)
                        .ccText(font: .cc.footnote, color: .cc.mutedForeground)
                }
                .padding(.all, 4)
                .padding(.leading, 4)
                .padding(.trailing, 6)
                .contentShape(RoundedRectangle(cornerRadius: 6))
                .containerShape(RoundedRectangle(cornerRadius: 6))
                .glassEffect()
            } else {
                // ━━━ iOS 25-: 微拟物效果 ━━━
                HStack(alignment: .center, spacing: 4) {
                    CCDesigin.ICON(imageName: self.icon, size: 16, color: .cc.mutedForeground)
                    Text(self.text)
                        .ccText(font: .cc.footnote, color: .cc.mutedForeground)
                }
                .padding(.all, 4)
                .padding(.leading, 4)
                .padding(.trailing, 6)
                // ━━━ 微拟物渐变背景 ━━━
                .background(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.cc.background, location: 0),
                            .init(color: Color.cc.background.mix(with: .black, amount: 0.05), location: 0.5),
                            .init(color: Color.cc.background.mix(with: .black, amount: 0.10), location: 1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 6))
                // ━━━ 内高光 + 暗边 ━━━
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.25),
                                    Color.clear,
                                    Color.black.opacity(0.08)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.5
                        )
                )
                // ━━━ 外阴影 ━━━
                .shadow(color: Color.cc.shadow.opacity(0.08), radius: 4, x: 0, y: 1)
            }
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 微拟物圆形按钮
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public extension CCDesigin {
    public enum GlassIconButtonMetrics {
        /// 2026-08-29 全局收 15%：50 → 42（icon 24 → 20），页头/舞台/返回钮/编辑 chrome 同步随之
        public static let size: CGFloat = 42
        public static let iconSize: CGFloat = 20
        static let cornerRadius: CGFloat = 21
    }

    enum GlassIconButtonSize {
        case regular
        case small

        var side: CGFloat {
            switch self {
            case .regular: return GlassIconButtonMetrics.size
            case .small: return 30
            }
        }

        var icon: CGFloat {
            switch self {
            case .regular: return GlassIconButtonMetrics.iconSize
            // 小钮按直径比例缩 icon（30/42 × 20 ≈ 14），避免一刀切撑满
            case .small: return 14
            }
        }
    }

    /// 全局液态玻璃图标按钮：正圆；regular 42 内 icon 20 / small 30 内 icon 14
    struct GlassIconButton: View {
        let icon: String
        var tint: Color = .cc.foreground
        var size: GlassIconButtonSize = .regular
        var action: () -> Void

        public init(icon: String, tint: Color = .cc.foreground, size: GlassIconButtonSize = .regular, action: @escaping () -> Void = {}) {
            self.icon = icon
            self.tint = tint
            self.size = size
            self.action = action
        }

        public var body: some View {
            CCButton {
                CCTrack.onTap("glass:" + icon)
                action()
            } label: {
                GlassIconButtonLabel(icon: icon, tint: tint, size: size)
            }
        }
    }

    struct GlassIconButtonLabel: View {
        let icon: String
        var tint: Color = .cc.foreground
        var size: GlassIconButtonSize = .regular

        public init(icon: String, tint: Color = .cc.foreground, size: GlassIconButtonSize = .regular) {
            self.icon = icon
            self.tint = tint
            self.size = size
        }

        public var body: some View {
            PikaIcon(icon, size: size.icon, color: tint)
                .frame(width: size.side, height: size.side)
                .contentShape(Circle())
                .softGlassStyle(.circle)
        }
    }

    /// CircleButton 的纯展示 Label (用于 Menu 等需要自定义触发的场景)
    struct CircleButtonLabel: View {
        let icon: String

        public var body: some View {
            GlassIconButtonLabel(icon: icon)
        }
    }

    struct CircleButton: View {
        let icon: String
        let action: () async -> Void

        public init(icon: String, action: @escaping () async -> Void = {}) {
            self.icon = icon
            self.action = action
        }

        public var body: some View {
            CCButton {
                CCTrack.onTap("circle:" + icon)
                await action()
            } label: {
                CircleButtonLabel(icon: icon)
            }
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 胶囊返回按钮
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public extension CCDesigin {
    struct CircularBackButton: View {
        var action: (() -> Void)?
        var autoLayout: Bool

        private let size = GlassIconButtonMetrics.size

        public init(autoLayout: Bool = true, action: (() -> Void)? = nil) {
            self.autoLayout = autoLayout
            self.action = action
        }

        public var body: some View {
            if autoLayout {
                VStack {
                    Spacer()
                    HStack {
                        button
                            .padding(.leading, 16)
                        Spacer()
                    }
                }
            } else {
                button
            }
        }

        private var button: some View {
            CCButton {
                if let action {
                    action()
                } else {
                    CCNav.pop()
                }
            } label: {
                buttonContent
            }
        }

        @ViewBuilder
        private var buttonContent: some View {
            if #available(iOS 26, *) {
                // ━━━ iOS 26: 原生 Liquid Glass ━━━
                Image("pika/arrow-left", bundle: .module)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: GlassIconButtonMetrics.iconSize, height: GlassIconButtonMetrics.iconSize)
                    .foregroundStyle(Color.cc.foreground)
                    .frame(width: size, height: size)
                    .contentShape(Circle())
                    .containerShape(Circle())
                    .glassEffect(.regular.interactive(), in: Circle())
            } else {
                // ━━━ iOS 25-: 微拟物效果 ━━━
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color.cc.background.opacity(0.95), location: 0),
                                .init(color: Color.cc.background.mix(with: .black, amount: 0.05).opacity(0.95), location: 0.5),
                                .init(color: Color.cc.background.mix(with: .black, amount: 0.12).opacity(0.95), location: 1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size, height: size)
                    // ━━━ 内高光 + 暗边 ━━━
                    .overlay {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.4),
                                        Color.clear,
                                        Color.black.opacity(0.08)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 0.5
                            )
                    }
                    .overlay {
                        CCDesigin.ICON(imageName: "arrow-left", size: GlassIconButtonMetrics.iconSize, color: .cc.foreground)
                    }
                    // ━━━ 外阴影 ━━━
                    .shadow(color: Color.cc.shadow.opacity(0.08), radius: 6, x: 0, y: 2)
                    .shadow(color: Color.cc.shadow.opacity(0.12), radius: 12, x: 0, y: 4)
            }
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - TabBar 风格返回按钮
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public extension CCDesigin {
    struct TabBarStyleBackButton: View {
        var action: (() -> Void)?
        var size: CGFloat

        public init(size: CGFloat = CCDesigin.GlassIconButtonMetrics.size, action: (() -> Void)? = nil) {
            self.size = size
            self.action = action
        }

        public var body: some View {
            CCButton {
                if let action {
                    action()
                } else {
                    CCNav.pop()
                }
            } label: {
                buttonContent
            }
        }

        @ViewBuilder
        private var buttonContent: some View {
            if #available(iOS 26, *) {
                // ━━━ iOS 26: Liquid Glass ━━━
                CCDesigin.ICON(imageName: "arrow-left", size: 16, color: .cc.foreground)
                    .frame(width: size, height: size)
                    .contentShape(Circle())
                    .containerShape(Circle())
                    .glassEffect(.regular.interactive(), in: Circle())
            } else {
                // ━━━ iOS 25-: 微拟物效果 ━━━
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color.cc.background.opacity(0.95), location: 0),
                                .init(color: Color.cc.background.mix(with: .black, amount: 0.05).opacity(0.95), location: 0.5),
                                .init(color: Color.cc.background.mix(with: .black, amount: 0.12).opacity(0.95), location: 1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size, height: size)
                    // ━━━ 内高光 + 暗边 ━━━
                    .overlay {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.35),
                                        Color.clear,
                                        Color.black.opacity(0.08)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 0.5
                            )
                    }
                    .overlay {
                        CCDesigin.ICON(imageName: "arrow-left", size: 16, color: .cc.foreground)
                    }
                    // ━━━ 外阴影 ━━━
                    .shadow(color: Color.cc.shadow.opacity(0.08), radius: 4, x: 0, y: 1)
                    .shadow(color: Color.cc.shadow.opacity(0.06), radius: 8, x: 0, y: 3)
            }
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 返回按钮 View Modifier
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extension View {
    /// 为视图添加左下角返回按钮；action 为 nil 时走默认 pop
    func withBackButton(action: (() -> Void)? = nil) -> some View {
        self.overlay(alignment: .bottomLeading) {
            CCDesigin.CircularBackButton(autoLayout: false, action: action)
                .padding(.leading, 16)
        }
    }
}
