//
//  OrbConfiguration.swift
//  Orb
//
//  Created by zhaochunxiang on 2024-01-08.
//

import SwiftUI

 

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 能量球配置
// 用于控制能量球的外观和行为表现
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct OrbConfiguration {
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 视觉属性
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    /// 能量球的主要发光颜色
    let glowColor: Color

    /// 背景渐变色数组
    let backgroundColors: [Color]

    /// 粒子特效的颜色
    let particleColor: Color

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 显示控制
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    /// 是否显示背景渐变
    let showBackground: Bool

    /// 是否显示波浪状流动效果
    let showWavyBlobs: Bool

    /// 是否显示粒子特效
    let showParticles: Bool

    /// 是否显示发光效果
    let showGlowEffects: Bool

    /// 是否显示阴影
    let showShadow: Bool

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 动画参数
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    /// 核心发光强度 (0.0-1.0)
    let coreGlowIntensity: Double

    /// 动画速度系数
    let speed: Double

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 初始化
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    public init(
        backgroundColors: [Color] = [Color.cc.chartCarbs, Color.cc.info, Color.cc.chartProtein],
        glowColor: Color = Color.cc.background,
        particleColor: Color = Color.cc.background,
        coreGlowIntensity: Double = 1.0,
        showBackground: Bool = true,
        showWavyBlobs: Bool = true,
        showParticles: Bool = true,
        showGlowEffects: Bool = true,
        showShadow: Bool = true,
        speed: Double = 60
    ) {
        self.backgroundColors = backgroundColors
        self.glowColor = glowColor
        self.particleColor = particleColor
        self.showBackground = showBackground
        self.showWavyBlobs = showWavyBlobs
        self.showParticles = showParticles
        self.showGlowEffects = showGlowEffects
        self.showShadow = showShadow
        self.coreGlowIntensity = coreGlowIntensity
        self.speed = speed
    }
}
