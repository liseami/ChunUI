/**
 * [INPUT]: 依赖 SwiftUI 的 PreferenceKey / ViewModifier 与 Theme 的 CC 字体、语义色
 * [OUTPUT]: 对外提供 ccText / ccNumber 文字速写、if / when 条件修饰、占位与静态视图、键盘与延时呈现（AutoOpenKeyed、ShowAfterSecs）、getViewHeight（ViewHeightPreferenceKey）、equatable(by:) 局部等价渲染
 * [POS]: Theme 的视图修饰速写；组件与宿主页面都直接调用
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import Foundation
import SwiftUI

// MARK: - 视图高度测量

public struct ViewHeightPreferenceKey: PreferenceKey {
    public static var defaultValue: CGFloat = 0
    public static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value += nextValue()
    }
  
}

// MARK: - View 扩展方法

extension View {
    // MARK: - 文字样式

    /// 一次设好 CC 字体与语义色：Text("标题").ccText(font: .cc.hero, color: .cc.foreground)
    public func ccText(font: Font, color: Color) -> some View {
        self.font(font).foregroundStyle(color)
    }

    /// ccText 的渐变重载：style 接任意 ShapeStyle（LinearGradient、AngularGradient 等）
    public func ccText<S: ShapeStyle>(font: Font, style: S) -> some View {
        self.font(font).foregroundStyle(style)
    }

    // MARK: - 数字样式

    /// 数字样式（系统等宽字）：统计、价格、计数、百分比；常用字号 28/24/20/18/16/14/12
    public func ccNumber(size: CGFloat, color: Color) -> some View {
        self.font(.cc.mono(size)).foregroundStyle(color)
    }

    // MARK: - 条件渲染

    /// show 为 true 时显示自身，否则换成 EmptyView
    public func `if`(_ show: Bool) -> some View {
        Group {
            if show {
                self
            } else {
                EmptyView()
            }
        }
    }

    /// 条件变换：condition 为 true 时套用 transform，否则原样返回
    @ViewBuilder
    public func when<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    // MARK: - 占位效果

    /// 占位效果：红色遮罩加闪烁动画
    public func isPlaceholder(_ show: Bool = true) -> some View {
        Group {
            if show {
                self
                    .redacted(reason: .placeholder)
                    .shimmer()
            } else {
                self
            }
        }
    }

    // MARK: - 键盘控制

    /// 出现时自动唤起键盘
    public func autoOpenKeyboard() -> some View {
        self.modifier(AutoOpenKeyed())
    }

    /// 高性能死页面
    public func deadView() -> some View {
        self.equatable(by: true)
            .allowsHitTesting(false)
    }

    // MARK: - 延迟显示

    /// 延迟 sec 秒再显示，transition 缺省淡入
    public func showAfter(_ sec: Double, transition: AnyTransition = .opacity) -> some View {
        self.modifier(ShowAfterSecs(sec: sec, transition: transition))
    }

    // MARK: - 静态视图

    /// 设为静态视图：禁用交互并优化性能
    public func isStaticView() -> some View {
        return self.equatable(by: true)
            .allowsHitTesting(false)
    }

    // MARK: - 文本标签

    /// 转成文本标签样式：textcolor 为字色，backColor 为底色
    public func isTextTag(_ textcolor: Color, backColor: Color) -> some View {
        self
            .ccText(font: .cc.captionBold , color: textcolor)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(backColor)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    /// 经 PreferenceKey 量出视图实际高度，高度变化时回调 completion
    public func getViewHeight(_ completion: @MainActor @escaping (CGFloat) -> Void) -> some View {
        self
            .background(
                GeometryReader { geometry in
                    Color.clear.preference(
                        key: ViewHeightPreferenceKey.self,
                        value: geometry.size.height
                    )
                }
            )
            .onPreferenceChange(ViewHeightPreferenceKey.self) { height in
                completion(height)
            }
    }

    public func addTopAndButtonBlur(top: CGFloat = 46, bottom: CGFloat = 90) -> some View {
        self
            .overlay(alignment: .top) {
                VariableBlurView(maxBlurRadius: 8, direction: .blurredTopClearBottom, startOffset: 0.2)
                    .frame(height: top)
                    .ignoresSafeArea()
            }
            .overlay(alignment: .bottom) {
                VariableBlurView(maxBlurRadius: 8, direction: .blurredBottomClearTop, startOffset: 0.2)
                    .ignoresSafeArea()
                    .frame(height: bottom)
            }
    }

    public func isCCMainScrollView() -> some View {
        self
            .scrollIndicators(.hidden, axes: .vertical)
            .background(Color.cc.background)
            .addTopAndButtonBlur(top: 90, bottom: 46)
    }

    public func addCloseBtn(at: Alignment = .topTrailing) -> some View {
        self
            .overlay(alignment: at) {
                CCDesigin.CircleButton(icon: "arrow-down") {
                    AppHelper.shared.dismissSheet()
                }
                .padding(.all, 16)
            }
    }

}



// MARK: - 预览示例

#Preview {
    VStack(spacing: 20) {
        Text("主标题示例")
            .ccText(font: .cc.hero , color: .cc.foreground)

        Text("副标题示例")
            .ccText(font: .cc.title1 , color: .cc.mutedForeground)

        Text("正文内容示例")
            .ccText(font: .cc.body , color: .cc.mutedForeground)

        Text("小字提示示例")
            .ccText(font: .cc.footnote , color: .cc.mutedForeground)
    }
    .padding()
}


// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 局部等价渲染原语（SwiftUIX equatable(by:) 的包内替身）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

private struct CCEquatableBox<Value: Equatable, Content: View>: View, Equatable {
    let value: Value
    let content: Content
    public static func == (lhs: Self, rhs: Self) -> Bool { lhs.value == rhs.value }
    public var body: some View { content }
}

extension View {
    /// 按给定值判等跳过 diff：值不变则子树不重算（静态装饰层专用）
    public func equatable<V: Equatable>(by value: V) -> some View {
        CCEquatableBox(value: value, content: self)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 键盘 / 延时呈现修饰符（迁自宿主 ViewModifiers）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct AutoOpenKeyed: ViewModifier {
    @FocusState private var isFocused: Bool

    public func body(content: Content) -> some View {
        content
            .focused($isFocused)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isFocused = true
                }
            }
    }
}

public struct ShowAfterSecs: ViewModifier {
    public var sec: Double = 0
    public var transition: AnyTransition
    @State private var show: Bool = false
    public init(sec: Double, transition: AnyTransition = .opacity) {
        self.sec = sec
        self.transition = transition
    }

    public func body(content: Content) -> some View {
        if show {
            content
                .transition(transition)
                .animation(.smooth, value: show)
        } else {
            Color.clear.frame(width: 1, height: 1)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + sec) {
                        self.show = true
                    }
                }
        }
    }
}
