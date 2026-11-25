//
//  Orb.swift
//  CyberLife
//
///11/16.
//

import SwiftUI
import Foundation

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - ORB 预设主题 (使用设计系统颜色)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct ORB {
    // Mystic - 神秘紫色
    let mysticOrb = OrbConfiguration(
        backgroundColors: [Color.cc.primary, Color.cc.info, Color.cc.primary],
        glowColor: Color.cc.primary,
        coreGlowIntensity: 1.2
    )

    // Nature - 自然绿色
    let natureOrb = OrbConfiguration(
        backgroundColors: [Color.cc.chartCarbs, Color.cc.chartCarbs.opacity(0.7), Color.cc.chartCarbs.opacity(0.5)],
        glowColor: Color.cc.chartCarbs,
        speed: 45
    )

    // Sunset - 日落橙红
    let sunsetOrb = OrbConfiguration(
        backgroundColors: [Color.cc.chartFat, Color.cc.chartProtein, Color.cc.chartProtein.opacity(0.7)],
        glowColor: Color.cc.chartFat,
        coreGlowIntensity: 0.8
    )

    // Ocean - 海洋蓝色
    let oceanOrb = OrbConfiguration(
        backgroundColors: [Color.cc.info, Color.cc.info.opacity(0.7), Color.cc.info.opacity(0.5)],
        glowColor: Color.cc.info,
        speed: 75
    )

    // Minimal - 极简灰白
    let minimalOrb = OrbConfiguration(
        backgroundColors: [Color.cc.muted, Color.cc.background],
        glowColor: Color.cc.background,
        showWavyBlobs: false,
        showParticles: false,
        speed: 30
    )

    // Cosmic - 宇宙粉紫
    let cosmicOrb = OrbConfiguration(
        backgroundColors: [Color.cc.primary, Color.cc.chartProtein, Color.cc.info],
        glowColor: Color.cc.background,
        coreGlowIntensity: 1.5,
        speed: 90
    )

    // Fire - 火焰红橙
    let fireOrb = OrbConfiguration(
        backgroundColors: [Color.cc.destructive, Color.cc.chartFat, Color.cc.secondary],
        glowColor: Color.cc.chartFat,
        coreGlowIntensity: 1.3,
        speed: 80
    )

    // Arctic - 极地冰蓝
    let arcticOrb = OrbConfiguration(
        backgroundColors: [Color.cc.info.opacity(0.7), Color.cc.background, Color.cc.info],
        glowColor: Color.cc.background,
        coreGlowIntensity: 0.75,
        showParticles: true,
        speed: 40
    )

    // Shadow - 暗影灰黑
    let shadowOrb = OrbConfiguration(
        backgroundColors: [Color.cc.foreground, Color.cc.mutedForeground],
        glowColor: Color.cc.mutedForeground,
        coreGlowIntensity: 0.7,
        showParticles: false
    )
}
