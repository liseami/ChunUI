//
//  CCNeoButton.swift
//  Chat0IM
//

/**
 * [INPUT]: 依赖 Color.cc/Font.cc 设计令牌、Theme 的 CCFontFamily（分段钮字）、Color.mix 拟物混色、PikaIcon、AppHelper.mada
 * [OUTPUT]: 对外提供 CCNeoButton（primary/secondary/ghost/outline/danger 五变体 × small/medium/large；primary 可 accent 覆色；async loading + 弹簧按压）、View.ccNeoChrome / ccNeoChromeCircle（自定义内容套同款质感；圆仅输入坞发送特例）、RoundedRectangle.ccButton、CCNeoIconButton、CCNeoPressStyle、CCListRowPressStyle、CCSegmentedControl
 * [POS]: DesignSystem/Compents 按钮族。主钮圆角 = height×0.38 连续圆（禁胶囊）。质感对齐 Laper-app EmphasisEffect：1px 深一线 ring + 上亮下实受光渐变 + 顶沿 1.5px 内高光（只蒙上半，禁整圈白描边）。segment 复刻 17005:772 凹槽+色洗拇指，高 56，槽与拇指同为圆角矩形。业务页禁自绘扁平胶囊，自定义内容走 ccNeoChrome；仅发送钮可走 ccNeoChromeCircle。
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Laper EmphasisEffect（顶沿高光只蒙上半，禁整圈白描边）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// 顶沿内高光：色带只在上缘显影，下半 mask 掉——不是绕一圈的白线
private struct CCTopLip<S: InsettableShape>: View {
    var shape: S
    var color: Color
    var lineWidth: CGFloat = 1.5

    var body: some View {
        shape
            .inset(by: lineWidth)
            .strokeBorder(color, lineWidth: lineWidth)
            .mask {
                LinearGradient(
                    stops: [
                        .init(color: .white, location: 0),
                        .init(color: .white.opacity(0.45), location: 0.22),
                        .init(color: .clear, location: 0.50),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .allowsHitTesting(false)
    }
}

/// Laper-app 有色强调钮：底 token+30% 白 · 受光 28%白→token · 顶沿 52%白 · ring token+18%黑 1px · shadow-xs
struct CCLaperEmphasis<S: InsettableShape>: View {
    var shape: S
    var token: Color

    var body: some View {
        let base = token.mix(with: .white, amount: 0.30)
        let from = token.mix(with: .white, amount: 0.28)
        let lip = token.mix(with: .white, amount: 0.52)
        let ring = token.mix(with: .black, amount: 0.18)

        ZStack {
            shape.fill(base)
            shape.fill(LinearGradient(colors: [from, token], startPoint: .top, endPoint: .bottom))
        }
        .overlay { CCTopLip(shape: shape, color: lip, lineWidth: 1.5) }
        .overlay { shape.strokeBorder(ring, lineWidth: 1) }
        .shadow(color: .black.opacity(0.10), radius: 1.5, y: 1)
    }
}

/// 白/浅底凸面（secondary / segment 拇指）：1px 发丝环 + 顶沿高光，禁整圈白描边
struct CCNeumorphRaised<S: InsettableShape>: View {
    var shape: S
    var fill: Color
    var tint: Color? = nil

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let isDark = colorScheme == .dark
        let ring: Color = tint?.mix(with: .white, amount: 0.38)
            ?? Color.black.opacity(isDark ? 0.40 : 0.18)
        let lip = Color.white.opacity(isDark ? 0.28 : 0.72)

        ZStack {
            shape.fill(fill.opacity(isDark ? 0.92 : 0.88))
            if let tint {
                shape.fill(tint.opacity(0.16))
            }
            shape.fill(
                LinearGradient(
                    colors: [Color.black.opacity(0), Color.black.opacity(0.06)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .overlay { CCTopLip(shape: shape, color: lip, lineWidth: 1.5) }
        .overlay { shape.strokeBorder(ring, lineWidth: 1) }
        .shadow(color: (tint ?? Color.black).opacity(tint == nil ? 0.06 : 0.10), radius: 1.5, y: 1)
    }
}

/// 772 凹槽：#f0f0f0 + 1px #c4c4c4 内环，无顶白线
struct CCNeumorphWell<S: InsettableShape>: View {
    var shape: S

    var body: some View {
        shape
            .fill(
                Color.adaptive(light: .hex("f0f0f0"), dark: Color.cc.sidebarAccent)
                    .shadow(.inner(color: .black.opacity(0.06), radius: 2, x: 0, y: 1.5))
            )
            .overlay {
                shape.strokeBorder(
                    Color.adaptive(light: .hex("c4c4c4"), dark: Color.cc.border),
                    lineWidth: 1
                )
            }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 变体 / 尺寸
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public enum CCNeoVariant {
    case primary    // 主题色实底 + 862 内沿
    case secondary  // 909 白钮
    case ghost      // 无底无边，按压显灰阶
    case outline    // 描边
    case danger     // 危险色实底 + 862 内沿
}

public enum CCNeoSize {
    case small      // h34 footnote
    case medium     // h44 body
    case large      // h52 bodyBold

    var height: CGFloat {
        switch self {
        case .small: return 34
        case .medium: return 44
        case .large: return 52
        }
    }

    var font: Font {
        switch self {
        case .small: return .cc.footnote
        case .medium: return .cc.callout
        case .large: return .cc.bodyBold
        }
    }

    var hPadding: CGFloat {
        switch self {
        case .small: return 14
        case .medium: return 18
        case .large: return 22
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .small: return 14
        case .medium: return 16
        case .large: return 18
        }
    }
}

extension RoundedRectangle {
    /// 主钮圆角 = height × 0.38 连续圆。禁胶囊。
    public static func ccButton(height: CGFloat) -> RoundedRectangle {
        RoundedRectangle(cornerRadius: height * 0.38, style: .continuous)
    }
}

/// CCNeoButton 五变体表面。自定义内容走 View.ccNeoChrome，禁业务页自绘扁平底。
struct CCNeoSurface<S: InsettableShape>: View {
    var variant: CCNeoVariant
    var shape: S
    var accent: Color? = nil

    var body: some View {
        switch variant {
        case .primary:
            CCLaperEmphasis(shape: shape, token: accent ?? Color.cc.primary)
        case .danger:
            CCLaperEmphasis(shape: shape, token: Color.cc.destructive)
        case .secondary:
            CCNeumorphRaised(shape: shape, fill: Color.cc.card)
        case .outline:
            shape.strokeBorder(Color.cc.border, lineWidth: 1)
        case .ghost:
            Color.clear
        }
    }
}

public struct CCNeoChromeModifier: ViewModifier {
    var variant: CCNeoVariant
    var height: CGFloat
    var disabled: Bool = false
    var accent: Color? = nil
    var circular: Bool = false

    public init(
        variant: CCNeoVariant,
        height: CGFloat,
        disabled: Bool = false,
        accent: Color? = nil,
        circular: Bool = false
    ) {
        self.variant = variant
        self.height = height
        self.disabled = disabled
        self.accent = accent
        self.circular = circular
    }

    public func body(content: Content) -> some View {
        Group {
            if circular {
                content
                    .background { CCNeoSurface(variant: variant, shape: Circle(), accent: accent) }
                    .contentShape(Circle())
            } else {
                let shape = RoundedRectangle.ccButton(height: height)
                content
                    .background { CCNeoSurface(variant: variant, shape: shape, accent: accent) }
                    .contentShape(shape)
            }
        }
        .opacity(disabled ? 0.45 : 1)
    }
}

public extension View {
    /// 自定义内容套 CCNeoButton 同款圆角矩形质感。Apple/Google 双行 CTA 等走这里，禁自绘扁平胶囊。
    func ccNeoChrome(
        _ variant: CCNeoVariant,
        height: CGFloat,
        disabled: Bool = false,
        accent: Color? = nil
    ) -> some View {
        modifier(CCNeoChromeModifier(variant: variant, height: height, disabled: disabled, accent: accent))
    }

    /// 输入坞发送钮特例：同款质感，外形正圆。别处禁用。
    func ccNeoChromeCircle(
        _ variant: CCNeoVariant,
        diameter: CGFloat,
        disabled: Bool = false,
        accent: Color? = nil
    ) -> some View {
        modifier(CCNeoChromeModifier(
            variant: variant,
            height: diameter,
            disabled: disabled,
            accent: accent,
            circular: true
        ))
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCNeoButton
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// 微拟物按钮：async action 返回前自动进入 loading（Laper Promise 托管移植）
public struct CCNeoButton: View {
    let title: String
    var variant: CCNeoVariant = .primary
    var size: CCNeoSize = .medium
    var icon: String? = nil
    var fullWidth: Bool = false
    var disabled: Bool = false
    var accent: Color? = nil
    var action: () async -> Void

    public init(
        _ title: String,
        variant: CCNeoVariant = .primary,
        size: CCNeoSize = .medium,
        icon: String? = nil,
        fullWidth: Bool = false,
        disabled: Bool = false,
        accent: Color? = nil,
        action: @escaping () async -> Void
    ) {
        self.title = title
        self.variant = variant
        self.size = size
        self.icon = icon
        self.fullWidth = fullWidth
        self.disabled = disabled
        self.accent = accent
        self.action = action
    }

    @State private var isLoading = false

    private var isDisabled: Bool { disabled || isLoading }
    private var shape: RoundedRectangle { .ccButton(height: size.height) }

    public var body: some View {
        Button {
            guard !isDisabled else { return }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            CCTrack.onTap("neo:" + title)
            Task {
                isLoading = true
                await action()
                isLoading = false
            }
        } label: {
            HStack(spacing: 7) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: foreground))
                        .scaleEffect(0.72)
                } else if let icon {
                    PikaIcon(icon, size: size.iconSize, color: foreground)
                }
                Text(title)
                    .font(size.font)
                    .fontWeight(variant == .primary || variant == .danger ? .semibold : .medium)
                    .foregroundStyle(foreground)
                    .lineLimit(1)
            }
            .padding(.horizontal, size.hPadding)
            .frame(height: size.height)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background { CCNeoSurface(variant: variant, shape: shape, accent: accent) }
            .contentShape(shape)
            .opacity(isDisabled && !isLoading ? 0.45 : 1)
        }
        .buttonStyle(CCNeoPressStyle())
        .disabled(isDisabled)
    }

    private var foreground: Color {
        switch variant {
        case .primary: return accent != nil ? .white : .cc.primaryForeground
        case .danger: return .white
        case .secondary, .ghost, .outline: return .cc.foreground
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCSegmentedControl（Figma 17005:772：凹槽圆角矩形 + 色洗拇指 + 格间 0.5px 分隔）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// 56pt 圆角矩形分段（772 形制 ×2 高）。行上禁再包 fieldCard。选中拇指 = 白底 16% primary 洗 + 顶沿高光。禁胶囊。
public struct CCSegmentedControl<Value: Hashable>: View {
    @Binding private var selection: Value
    private let items: [(Value, String)]

    public init(selection: Binding<Value>, items: [(Value, String)]) {
        self._selection = selection
        self.items = items
    }

    private let height: CGFloat = 56
    private var trackShape: RoundedRectangle { .ccButton(height: height) }
    private var selectedIndex: Int {
        items.firstIndex(where: { $0.0 == selection }) ?? 0
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.0) { item in
                let selected = selection == item.0
                Button {
                    AppHelper.shared.mada(.light)
                    selection = item.0
                } label: {
                    Text(item.1)
                        .font(CCFontFamily.font(size: 16, weight: .medium))
                        .foregroundStyle(selected ? Color.cc.primary : Color.cc.mutedForeground)
                        .frame(maxWidth: .infinity)
                        .frame(height: height)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? [.isSelected] : [])
            }
        }
        .background {
            GeometryReader { geo in
                let cell = geo.size.width / CGFloat(max(items.count, 1))
                CCNeumorphWell(shape: trackShape)
                CCNeumorphRaised(shape: trackShape, fill: Color.cc.card, tint: Color.cc.primary)
                    .frame(width: cell, height: height)
                    .offset(x: cell * CGFloat(selectedIndex))
            }
        }
        .overlay {
            GeometryReader { geo in
                let cell = geo.size.width / CGFloat(max(items.count, 1))
                ForEach(0..<max(items.count - 1, 0), id: \.self) { index in
                    let hide = selectedIndex == index || selectedIndex == index + 1
                    Rectangle()
                        .fill(Color(red: 114 / 255, green: 114 / 255, blue: 112 / 255).opacity(hide ? 0 : 0.4))
                        .frame(width: 0.5, height: 24)
                        .position(x: cell * CGFloat(index + 1), y: height / 2)
                }
            }
            .allowsHitTesting(false)
        }
        .frame(height: height)
        .animation(.spring(response: 0.32, dampingFraction: 0.78), value: selection)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCNeoIconButton（图标变体：方形按压区 + 可选 909 白底）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct CCNeoIconLabel: View {
    let icon: String
    var diameter: CGFloat = 40
    var iconSize: CGFloat = 18
    var tint: Color = .cc.mutedForeground
    var filled: Bool = false

    public var body: some View {
        let shape = RoundedRectangle.ccButton(height: diameter)
        PikaIcon(icon, size: iconSize, color: tint)
            .frame(width: diameter, height: diameter)
            .background {
                if filled {
                    CCNeumorphRaised(shape: shape, fill: Color.cc.card)
                }
            }
            .contentShape(shape)
    }
}

public struct CCNeoIconButton: View {
    let icon: String
    var diameter: CGFloat = 40
    var iconSize: CGFloat = 18
    var tint: Color = .cc.mutedForeground
    var filled: Bool = false
    var action: () -> Void

    public var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            CCNeoIconLabel(icon: icon, diameter: diameter, iconSize: iconSize, tint: tint, filled: filled)
        }
        .buttonStyle(CCNeoPressStyle())
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 按压弹簧
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct CCNeoPressStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.72), value: configuration.isPressed)
    }
}

public struct CCListRowPressStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                configuration.isPressed
                    ? Color.cc.muted.opacity(0.55)
                    : Color.clear
            )
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview {
    VStack(spacing: 18) {
        CCNeoButton("和顾问聊聊 ta", variant: .primary, size: .large, icon: "sparkle-ai01", fullWidth: true) {}
        CCNeoButton("查看档案", variant: .secondary, size: .medium, icon: "user-love-heart", fullWidth: true) {}
        CCNeoButton("幽灵按钮", variant: .ghost, size: .medium) {}
        CCNeoButton("描边按钮", variant: .outline, size: .small) {}
        CCNeoButton("删除", variant: .danger, size: .small, icon: "delete-dustbin01") {}
        PreviewSegment()
        HStack {
            CCNeoIconButton(icon: "grid-dashboard01") {}
            CCNeoIconButton(icon: "layer-two", filled: true) {}
        }
    }
    .padding(24)
    .background(Color.cc.background)
}

private struct PreviewSegment: View {
    @State private var gender = 1
    var body: some View {
        CCSegmentedControl(selection: $gender, items: [
            (1, "男"),
            (2, "女"),
            (0, "其他"),
        ])
    }
}
