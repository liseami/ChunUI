//
//  OrbView.swift
//  DreamPaper
//
//  Created by zhaochunxiang on 2024-01-08.
//

import UIKit
import SwiftUI

 

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 能量球视图
// 可配置的动态能量球效果组件，包含发光、粒子、波浪等视觉效果
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct OrbView: View {
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 属性
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private let config: OrbConfiguration

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 初始化
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    public init(configuration: OrbConfiguration = OrbConfiguration()) {
        self.config = configuration
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Body
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    public var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)

            ZStack {
                // 基础渐变背景层
                if config.showBackground {
                    background
                        
                }
                
                // 创建深度感的旋转发光效果
                baseDepthGlows(size: size)
                    

                // 添加有机的流动波浪形状
                if config.showWavyBlobs {
                    Group {
                        wavyBlob
                        wavyBlobTwo
                    }
                    
                }

                // 添加明亮、充满活力的核心发光动画
                if config.showGlowEffects {
                    coreGlowEffects(size: size)
                        
                }

                // 叠加浮动粒子效果以增加动态感
                if config.showParticles {
                    particleView
                        .frame(maxWidth: size, maxHeight: size)
                        
                }
            }
            // 添加球体轮廓以增加深度感
            .overlay {
                realisticInnerGlows
                    
            }
            // 将所有效果遮罩成完美的圆形
            .mask {
                Circle()
            }
            .aspectRatio(1, contentMode: .fit)
            // 添加逼真的分层阴影,使其在核心附近更亮,向外逐渐变软
            .modifier(
                RealisticShadowModifier(
                    colors: config.showShadow ? config.backgroundColors : [.clear],
                    radius: size * 0.08
                )
            )
            
        }
    }

    // MARK: - 私有视图组件
    
    /// 背景渐变
    private var background: some View {
        LinearGradient(colors: config.backgroundColors,
                       startPoint: .bottom,
                       endPoint: .top)
    }

    /// 球体轮廓渐变色
    private var orbOutlineColor: LinearGradient {
        LinearGradient(colors: [Color.cc.background, .clear],
                       startPoint: .bottom,
                       endPoint: .top)
    }
    
    /// 粒子效果视图
    private var particleView: some View {
        // 添加多层粒子效果,使用不同的模糊量
        ZStack {
            // 慢速大粒子
            ParticlesView(
                color: config.particleColor,
                speedRange: 10...20,
                sizeRange: 0.5...1,
                particleCount: 10,
                opacityRange: 0...0.3
            )
            .blur(radius: 1)
            
            // 快速小粒子
            ParticlesView(
                color: config.particleColor,
                speedRange: 20...30,
                sizeRange: 0.2...1,
                particleCount: 10,
                opacityRange: 0.3...0.8
            )
        }
        .blendMode(.plusLighter)
    }

    /// 第一层波浪效果
    private var wavyBlob: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)

            RotatingGlowView(color: Color.cc.background.opacity(0.75),
                           rotationSpeed: config.speed * 1.5,
                           direction: .clockwise)
                .mask {
                    WavyBlobView(color: Color.cc.background, loopDuration: 60 / config.speed * 1.75)
                        .frame(maxWidth: size * 1.875)
                        .offset(x: 0, y: size * 0.31)
                }
                .blur(radius: 1)
                .blendMode(.plusLighter)
        }
    }

    /// 第二层波浪效果
    private var wavyBlobTwo: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)

            RotatingGlowView(color: Color.cc.background,
                           rotationSpeed: config.speed * 0.75,
                           direction: .counterClockwise)
                .mask {
                    WavyBlobView(color: Color.cc.background, loopDuration: 60 / config.speed * 2.25)
                        .frame(maxWidth: size * 1.25)
                        .rotationEffect(.degrees(90))
                        .offset(x: 0, y: size * -0.31)
                }
                .opacity(0.5)
                .blur(radius: 1)
                .blendMode(.plusLighter)
        }
    }

    /// 核心发光效果
    private func coreGlowEffects(size: CGFloat) -> some View {
        ZStack {
            // 外层发光
            RotatingGlowView(color: config.glowColor,
                          rotationSpeed: config.speed * 3,
                          direction: .clockwise)
                .blur(radius: size * 0.08)
                .opacity(config.coreGlowIntensity)

            // 内层发光
            RotatingGlowView(color: config.glowColor,
                          rotationSpeed: config.speed * 2.3,
                          direction: .clockwise)
                .blur(radius: size * 0.06)
                .opacity(config.coreGlowIntensity)
                .blendMode(.plusLighter)
        }
        .padding(size * 0.08)
    }

    /// 基础深度发光效果
    private func baseDepthGlows(size: CGFloat) -> some View {
        ZStack {
            // 外部发光
            RotatingGlowView(color: config.glowColor,
                          rotationSpeed: config.speed * 0.75,
                          direction: .counterClockwise)
                .padding(size * 0.03)
                .blur(radius: size * 0.06)
                .rotationEffect(.degrees(180))
                .blendMode(.destinationOver)
            
            // 外环
            RotatingGlowView(color: config.glowColor.opacity(0.5),
                          rotationSpeed: config.speed * 0.25,
                          direction: .clockwise)
                .frame(maxWidth: size * 0.94)
                .rotationEffect(.degrees(180))
                .padding(8)
                .blur(radius: size * 0.032)
        }
    }

    /// 逼真的内部发光效果
    private var realisticInnerGlows: some View {
        ZStack {
            // 外层描边(重度模糊)
            Circle()
                .stroke(orbOutlineColor, lineWidth: 8)
                .blur(radius: 32)
                .blendMode(.plusLighter)

            // 中层描边(轻度模糊)
            Circle()
                .stroke(orbOutlineColor, lineWidth: 4)
                .blur(radius: 12)
                .blendMode(.plusLighter)
            
            // 内层描边(微弱模糊)
            Circle()
                .stroke(orbOutlineColor, lineWidth: 1)
                .blur(radius: 4)
                .blendMode(.plusLighter)
        }
        .padding(1)
    }
}

// MARK: - 预览
#Preview {
    let config = OrbConfiguration()
    OrbView(configuration: config)
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: 120)
}
