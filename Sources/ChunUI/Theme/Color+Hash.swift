//
//  Color+Hash.swift
//  YUI
//
//  Created by Claude on 2025/12/24.
//

/**
 * [INPUT]: 字符串（如菜系名称）
 * [OUTPUT]: 稳定的设计系统颜色
 * [POS]: DesignSystem/Utils - 字符串哈希颜色算法
 *
 * [PROTOCOL]:
 * 1. 使用 HSB 色彩空间，固定饱和度和亮度，只变化色相
 * 2. 相同字符串始终生成相同颜色（稳定性）
 * 3. 颜色均匀分布在色轮上（多样性）
 * 4. 符合设计系统的色彩规范（协调性）
 */

import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 字符串哈希颜色
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extension Color {

    /// 字符串经 DJB2 变体哈希取模 360 得色相，固定饱和度 0.65、亮度 0.75，生成稳定的设计系统色
    static func fromStringHash(_ string: String) -> Color {
        // DJB2 变体哈希：hash = ((hash << 5) + hash) + char
        var hash: UInt64 = 5381
        for char in string.utf8 {
            hash = ((hash << 5) &+ hash) &+ UInt64(char)
        }

        // 色相：0-360 度
        let hue = Double(hash % 360) / 360.0

        // 固定饱和度和亮度，确保颜色协调
        let saturation: Double = 0.65
        let brightness: Double = 0.75

        return Color(hue: hue, saturation: saturation, brightness: brightness)
    }

    /// 为一组字符串逐一生成颜色（图例用），与输入一一对应
    static func colorsFromStrings(_ strings: [String]) -> [Color] {
        strings.map { fromStringHash($0) }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 预设高级色板（潘通风格）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extension CCColorAccessor {

    /// 菜系专用色板（12 色，覆盖主要色相区间）
    private var cuisinePalette: [Color] { [
        Color(hex: "E57373"),  // 珊瑚红
        Color(hex: "FFB74D"),  // 琥珀橙
        Color(hex: "FFF176"),  // 柠檬黄
        Color(hex: "AED581"),  // 苹果绿
        Color(hex: "4DB6AC"),  // 薄荷绿
        Color(hex: "4FC3F7"),  // 天空蓝
        Color(hex: "7986CB"),  // 薰衣草
        Color(hex: "BA68C8"),  // 兰花紫
        Color(hex: "F06292"),  // 玫瑰粉
        Color(hex: "A1887F"),  // 摩卡棕
        Color(hex: "90A4AE"),  // 石板灰
        Color(hex: "78909C")   // 蓝灰
    ] }

    /// 从预设色板中选择颜色（基于索引取模）
    func cuisineColor(at index: Int) -> Color {
        cuisinePalette[abs(index) % cuisinePalette.count]
    }

    /// 从字符串哈希选择预设色板颜色
    func cuisineColor(for string: String) -> Color {
        var hash: UInt64 = 5381
        for char in string.utf8 {
            hash = ((hash << 5) &+ hash) &+ UInt64(char)
        }
        return cuisinePalette[Int(hash % UInt64(cuisinePalette.count))]
    }
}
