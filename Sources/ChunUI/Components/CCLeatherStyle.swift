//
//  CCLeatherStyle.swift
//  YUI
//
//  Created by Claude on 2025/12/24.
//

/**
 * [INPUT]: 依赖 Core/CCLog（预览里关闭钮的调试日志）
 * [OUTPUT]: CCCamera 同款皮革背景 + 金属关闭按钮
 * [POS]: DesignSystem/Compents - 公用皮革风格组件
 *
 * [PROTOCOL]:
 * 1. CCLeatherBackground: 皮革纹理渐变背景
 * 2. CCMetalCloseButton: 金属质感关闭按钮
 * 3. 替代所有平庸的 xmark 关闭按钮
 */

import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCCamera 同款皮革背景
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct CCLeatherBackground: View {
    public init() {}

    public var body: some View {
        GeometryReader { geo in
            ZStack {
                // 不透明底色（防止透视）
                Color(hex: "1a1a1a")

                // 渐变色调
                LinearGradient(
                    colors: [Color.cc.primary.opacity(0.3), Color.cc.secondary.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // 皮革纹理
                Image("camera_bg")
                    .resizable(resizingMode: .tile)
                    .opacity(0.5)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCCamera 同款金属关闭按钮
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct CCMetalCloseButton: View {
    let action: () -> Void
    let size: CGFloat

    public init(size: CGFloat = 44, action: @escaping () -> Void) {
        self.size = size
        self.action = action
    }

    public var body: some View {
        CCDesigin.CCButton {
            AppHelper.shared.mada(.light)
            action()
        } label: {
            ZStack {
                // 外壳
                Circle()
                    .fill(LinearGradient(
                        colors: [Color(hex: "f0f0f0"), Color(hex: "d0d0d0")],
                        startPoint: .top, endPoint: .bottom
                    ))
                    .frame(width: size, height: size)
                    .shadow(color: .cc.shadow.opacity(0.2), radius: 4, y: 2)

                // 金属纹理
                Circle()
                    .fill(AngularGradient(
                        colors: [Color(hex: "c0c0c0"), Color(hex: "e8e8e8"),
                                 Color(hex: "a8a8a8"), Color(hex: "d8d8d8")],
                        center: .center
                    ))
                    .frame(width: size - 4, height: size - 4)

                // 中心 + X 图标
                Circle()
                    .fill(LinearGradient(
                        colors: [Color(hex: "f8f8f8"), Color(hex: "e0e0e0")],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: size * 0.636, height: size * 0.636)
                    .shadow(color: .cc.shadow.opacity(0.1), radius: 1, y: 1)
                    .overlay {
                        Image(systemName: "xmark")
                            .font(.system(size: size * 0.273, weight: .bold))
                            .foregroundStyle(Color(hex: "666666"))
                    }
            }
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - View Extension
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extension View {
    /// 添加皮革背景
    public func leatherBackground() -> some View {
        self.background(CCLeatherBackground())
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Preview
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

#Preview("Leather Background") {
    ZStack {
        CCLeatherBackground()

        VStack(spacing: 20) {
            Text("皮革背景示例")
                .ccText(font: .cc.title2Bold, color: .white)

            CCMetalCloseButton {
                CCLog.debug("Leather close tapped", category: "CCLeatherStyle")
            }
        }
    }
}

#Preview("Metal Close Button Sizes") {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            CCMetalCloseButton(size: 32) {}
            CCMetalCloseButton(size: 44) {}
            CCMetalCloseButton(size: 56) {}
        }
    }
    .padding()
    .background(Color.cc.muted)
}
