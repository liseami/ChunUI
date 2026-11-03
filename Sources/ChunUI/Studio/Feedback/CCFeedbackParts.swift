/**
 * [INPUT]: 依赖 Components 的 CCSmoothCorner（平滑圆角，与胃之书 BellySmoothCorner 同算法）与 CCDesigin.CCButton（按压缩放 · 发光 · 禁用横抖 · async 转圈的按压壳）、
 *          Theme 的 Color.mix(with:amount:)、本目录 CCFBTokens / CCFBFont、Color.cc
 * [OUTPUT]: 对内提供 View.ccfbFieldSurface(focused:) 与 CCFBFieldShape（近白键帽输入面）、CCFBTextArea（长文输入：剩余字数、聚焦托）、
 *           CCFBPrimaryButton（大号主钮：深色玻璃胶囊 + 浅字，async 自带转圈）、View.ccfbCard()（原卡片）与 CCFBEmptyView（插图 + 两行字的空态）
 * [POS]: Studio/Feedback 的视觉原子，逐值移植胃之书 DesignSystem 的 BellyFieldSurface / BellyTextInput（长文一支）/ CCButtons 的 large · primary / bellyAppleCard / CCEmptyView。
 *        包里同名能力（CCDesigin.Button、CCNeoButton、CCEmptyState）外观不同，意见箱一律用这里的件，保证与胃之书逐像素一致
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 输入面：近白键帽（聚焦托 + 投影 + 竖向渐变底在下，描边 + 下沿唇在上，内容按轮廓裁）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extension View {
    func ccfbFieldSurface(focused: Bool = false) -> some View {
        modifier(CCFBFieldSurface(focused: focused))
    }
}

/// 输入面的轮廓：平滑圆角
struct CCFBFieldShape: Shape {
    var radius: CGFloat = CCFBTokens.Field.radius

    func path(in rect: CGRect) -> Path {
        Path(CCSmoothCorner.path(in: rect, radius: radius, smoothing: CCFBTokens.Field.smoothing))
    }
}

private struct CCFBFieldSurface: ViewModifier {
    private typealias M = CCFBTokens.Field

    let focused: Bool
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        let shape = CCFBFieldShape()
        let dark = scheme == .dark
        content
            .clipShape(shape)
            .background {
                shape
                    .fill(LinearGradient(colors: [M.field, M.field.mix(with: .cc.muted, by: M.fillShade)], startPoint: .top, endPoint: .bottom))
                    .shadow(color: .black.opacity(dark ? M.shadowAlphaDark : M.shadowAlpha), radius: M.shadowBlur / 2, y: M.shadowY)
            }
            // 后挂的 background 垫在前一层之下：托在投影与填色之后
            .background { well }
            .overlay {
                ZStack {
                    // 平滑圆角不是 InsettableShape：描两倍宽、按轮廓裁掉外半，只留里侧 border
                    shape.stroke(M.fieldBorder, lineWidth: M.border * 2).clipShape(shape)
                    CCFBFieldLip().fill(Color.black.opacity(dark ? M.edgeAlphaDark : M.edgeAlpha))
                }
                .allowsHitTesting(false)
            }
            .contentShape(shape)
    }

    /// 聚焦托：同心圆角的灰托，左右上外扩 wellInset、下沿外扩 wellDrop；以面心为锚自 wellGrow 长到原大并淡入
    private var well: some View {
        CCFBFieldShape(radius: M.radius + M.wellInset)
            .fill(M.fieldWell)
            .padding(.horizontal, -M.wellInset)
            .padding(.top, -M.wellInset)
            .padding(.bottom, -M.wellDrop)
            .scaleEffect(focused ? 1 : M.wellGrow)
            .opacity(focused ? 1 : 0)
            .animation(.spring(duration: M.motionLow, bounce: 0), value: focused)
            .allowsHitTesting(false)
    }
}

/// 下沿唇：轮廓减去上移 edge 的自身
private struct CCFBFieldLip: Shape {
    func path(in rect: CGRect) -> Path {
        let full = CCFBFieldShape().path(in: rect)
        return full.subtracting(full.offsetBy(dx: 0, dy: -CCFBTokens.Field.edge))
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 长文输入：字段 …… 剩余字数；areaLines 行起、至多 areaMaxLines 行；点卡上任何一处都落进字段
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct CCFBTextArea: View {
    private typealias M = CCFBTokens.Field

    let placeholder: String
    @Binding var text: String
    let limit: Int
    @FocusState private var focused: Bool

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: M.rowGap) {
            TextField(placeholder, text: $text, axis: .vertical)
                .lineLimit(M.areaLines ... M.areaMaxLines)
                .font(CCFBFont.body)
                .foregroundStyle(Color.cc.foreground)
                .tint(Color.cc.primary)
                .textInputAutocapitalization(.sentences)
                .autocorrectionDisabled(false)
                .focused($focused)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("\(limit - text.count)")
                .font(CCFBFont.body)
                .foregroundStyle(text.count > limit ? Color.cc.destructive : Color.cc.mutedForeground)
        }
        .padding(.leading, CCFBTokens.rowInset)
        .padding(.trailing, CCFBTokens.rowInset)
        // 多行：上下留白与单行里字形离卡沿的距离相同
        .padding(.vertical, (M.rowHeight - M.icon) / 2)
        .frame(minHeight: M.rowHeight)
        .ccfbFieldSurface(focused: focused)
        .onTapGesture { focused = true }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 主钮（large · primary）：foreground 色的深色玻璃胶囊、primaryForeground 字；禁用半透、字转 mutedForeground
// 按压壳取包内 CCDesigin.CCButton（与胃之书同一套按压 / 发光 / 横抖 / 转圈）；转圈期间的扫光走包内 shimmer，不用 Pow 的重复 shine
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct CCFBPrimaryButton: View {
    let title: String
    var enable = true
    let action: () async -> Void

    var body: some View {
        CCDesigin.CCButton(enable: enable) {
            await action()
        } label: { isLoading in
            label(isLoading: isLoading)
        }
    }

    private func label(isLoading: Bool) -> some View {
        let color = enable ? Color.cc.primaryForeground : Color.cc.mutedForeground
        return HStack(alignment: .center, spacing: CCFBTokens.Button.spacing) {
            if isLoading {
                ProgressView().tint(color)
            } else if !title.isEmpty {
                Text(title).ccText(font: CCFBFont.bodyBold, color: color)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .frame(height: CCFBTokens.Button.height)
        .modifier(CCFBGlassCapsule(enable: enable))
    }
}

/// 深色玻璃胶囊（胃之书 PinkGlassButtonStyle）：渐变底 · 边 · 五层内阴影 · 外投影
private struct CCFBGlassCapsule: ViewModifier {
    let enable: Bool

    private var tone: Color { .cc.foreground }

    func body(content: Content) -> some View {
        content
            .background(background)
            .clipShape(Capsule())
            .overlay(innerShadows)
            .overlay(Capsule().stroke(tone.mix(with: .black, amount: 0.2), lineWidth: 0.5))
            .shadow(color: tone.opacity(enable ? 0.4 : 0), radius: 8, x: 0, y: 4)
            .opacity(enable ? 1 : 0.5)
    }

    private var background: some View {
        LinearGradient(
            stops: [
                .init(color: tone.mix(with: .white, amount: 0.15), location: 0),
                .init(color: tone, location: 0.5),
                .init(color: tone.mix(with: .black, amount: 0.15), location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var innerShadows: some View {
        ZStack {
            // 内边缘暗色轮廓
            Capsule()
                .stroke(tone.mix(with: .black, amount: 0.3), lineWidth: 1)
                .blur(radius: 0.5)
                .clipShape(Capsule())
            // 顶部高光条
            Capsule()
                .stroke(LinearGradient(colors: [Color.white.opacity(0.6), Color.white.opacity(0.2), Color.clear], startPoint: .top, endPoint: .center), lineWidth: 1.5)
                .blur(radius: 0.5)
                .clipShape(Capsule())
            // 整体内阴影
            Capsule()
                .stroke(tone.mix(with: .black, amount: 0.25), lineWidth: 2)
                .blur(radius: 2)
                .clipShape(Capsule())
            // 底部暗边
            Capsule()
                .stroke(LinearGradient(colors: [Color.clear, Color.clear, Color.black.opacity(0.2)], startPoint: .top, endPoint: .bottom), lineWidth: 2)
                .blur(radius: 1)
                .clipShape(Capsule())
            // 底部冷色反光
            Capsule()
                .stroke(LinearGradient(colors: [Color.clear, Color.clear, tone.mix(with: .white, amount: 0.3).opacity(0.4)], startPoint: .top, endPoint: .bottom), lineWidth: 1.5)
                .blur(radius: 1.5)
                .clipShape(Capsule())
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 原卡片：连续圆角 20、外层高光边 + 内层深色边、双层柔影
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extension View {
    func ccfbCard() -> some View {
        let shape = RoundedRectangle(cornerRadius: CCFBTokens.Card.radius, style: .continuous)
        return self
            .background(Color.cc.background)
            .clipShape(shape)
            .overlay { shape.stroke(Color.cc.background, lineWidth: 2).blendMode(.overlay) }
            .overlay { shape.stroke(Color.cc.foreground.opacity(0.12), lineWidth: 1) }
            .shadow(color: Color.cc.shadow.opacity(0.08), radius: 6, y: 3)
            .shadow(color: Color.cc.shadow.opacity(0.12), radius: 16, y: 8)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 空态：宿主给的插图（宽 240）· 标题 · 一行说明，字上提 24 压进插图下沿
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct CCFBEmptyView: View {
    private typealias T = CCFBTokens.Resolved

    let art: Image?
    let title: String
    let subline: String

    var body: some View {
        VStack(alignment: .center, spacing: T.emptyGap) {
            if let art {
                art
                    .resizable()
                    .scaledToFit()
                    .frame(width: T.emptyArt)
            }
            Group {
                Text(title).ccText(font: CCFBFont.subheadlineBold, color: .cc.foreground)
                Text(subline).ccText(font: CCFBFont.footnote, color: .cc.mutedForeground)
            }
            .offset(x: 0, y: art == nil ? 0 : T.emptyLift)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}
