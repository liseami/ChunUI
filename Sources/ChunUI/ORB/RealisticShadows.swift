//
//  RealisticShadows.swift
//  DreamPaper
//
//  Created by zhaochunxiang on 2024-01-08.
//

import SwiftUI

 

/// 真实阴影修饰器
/// 为视图添加多层渐变阴影效果，增强立体感和真实感
public struct RealisticShadowModifier: ViewModifier {
    // MARK: - 属性
    
    /// 阴影渐变色数组
    let colors: [Color]
    
    /// 阴影模糊半径
    let radius: CGFloat
    
    // MARK: - 视图构建
    
    public func body(content: Content) -> some View {
        content
            // 添加第一层近距离阴影
            .background {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: colors,
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    // 较小的模糊半径创造锐利的近距阴影
                    .blur(radius: radius * 0.75)
                    // 较高不透明度增强近处阴影效果
                    .opacity(0.5)
                    // 轻微偏移制造悬浮感
                    .offset(y: radius * 0.5)
            }
            // 添加第二层远距离阴影
            .background {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: colors,
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    // 较大的模糊半径创造柔和的远距阴影
                    .blur(radius: radius * 3)
                    // 较低不透明度让远处阴影更自然
                    .opacity(0.3)
                    // 更大偏移增强深度感
                    .offset(y: radius * 0.75)
            }
    }
}
