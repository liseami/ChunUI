//
//  CCFloatingChrome.swift
//  Chat0IM
//

/**
 * [INPUT]: 依赖 DesignSystem/Blur.swift 的 VariableBlurView 与 Color.cc 设计令牌
 * [OUTPUT]: 对外提供 CCChromeBacking（上/下双向渐变模糊承托原子）、ccFloatingPageHeader 浮动页头修饰符与 ccFloatingHeaderHeight 环境键
 * [POS]: DesignSystem/Compents 的页面 chrome 范式唯一真相源——所有 tab 页/详情页的「内容自由滚过模糊页头」都经此实现，禁止各页手写模糊承托
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import Combine
import UIKit
import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCChromeBacking（渐变模糊承托：VariableBlur + 背景色渐变，上下双向）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct CCChromeBacking: View {
    public enum Edge {
        case top
        case bottom
    }

    let edge: Edge

    public init(edge: Edge) {
        self.edge = edge
    }

    public var body: some View {
        ZStack {
            VariableBlurView(
                maxBlurRadius: 16,
                direction: edge == .top ? .blurredTopClearBottom : .blurredBottomClearTop,
                startOffset: edge == .top ? 0.12 : 0.1
            )
            LinearGradient(
                colors: edge == .top
                    ? [Color.cc.background.opacity(0.96), Color.cc.background.opacity(0)]
                    : [Color.cc.background.opacity(0), Color.cc.background.opacity(0.96)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .allowsHitTesting(false)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - ccFloatingPageHeader（浮动页头范式：内容从模糊页头下自由滚过）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

private struct CCFloatingHeaderHeightKey: EnvironmentKey {
    public static let defaultValue: CGFloat = 64
}

extension EnvironmentValues {
    /// 浮动页头实测占位高（非滚动内容用它做顶部避让；滚动内容由 contentMargins 自动处理）
    public var ccFloatingHeaderHeight: CGFloat {
        get { self[CCFloatingHeaderHeightKey.self] }
        set { self[CCFloatingHeaderHeightKey.self] = newValue }
    }
}

private struct CCFloatingPageHeaderModifier<Header: View>: ViewModifier {
    @ViewBuilder var header: () -> Header
    @State private var headerHeight: CGFloat = 64

    func body(content: Content) -> some View {
        content
            // 后代 ScrollView 内容避让页头，但视口仍延伸到顶——滚动内容自然从模糊下穿过
            .contentMargins(.top, headerHeight + 2, for: .scrollContent)
            .environment(\.ccFloatingHeaderHeight, headerHeight + 2)
            .overlay(alignment: .top) {
                header()
                    .frame(maxWidth: .infinity)
                    .onGeometryChange(for: CGFloat.self) { proxy in
                        proxy.size.height
                    } action: { height in
                        headerHeight = height
                    }
                    .background(alignment: .top) {
                        CCChromeBacking(edge: .top)
                            .frame(height: headerHeight + 96)
                            .ignoresSafeArea(edges: .top)
                    }
            }
    }
}

extension View {
    /// 页头浮在渐变模糊上、内容从其下滚过；底部承托由宿主全局 CCChromeBacking(edge: .bottom) 提供，页面不自理
    public func ccFloatingPageHeader<Header: View>(@ViewBuilder header: @escaping () -> Header) -> some View {
        modifier(CCFloatingPageHeaderModifier(header: header))
    }
}

#Preview {
    ScrollView {
        LazyVStack(spacing: 12) {
            ForEach(0..<30, id: \.self) { index in
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.cc.muted)
                    .frame(height: 72)
                    .overlay(Text("row \(index)"))
            }
        }
        .padding(.horizontal, 18)
    }
    .ccFloatingPageHeader {
        CCPageHeader(title: "预览", subtitle: "内容从模糊页头下滚过")
    }
    .background(Color.cc.background.ignoresSafeArea())
}
