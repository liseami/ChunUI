/*
 ╔═══════════════════════════════════════════════════════════════════════════╗
 ║                         Color+Mix.swift                                   ║
 ║                       颜色混合工具扩展                                      ║
 ╚═══════════════════════════════════════════════════════════════════════════╝

 [INPUT]: SwiftUI Color, UIKit UIColor
 [OUTPUT]: 混合后的 Color
 [POS]: DesignSystem/Utils - 颜色运算工具，服务于微拟物效果

 [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
*/

import SwiftUI
import UIKit

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Color 混合扩展
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extension Color {

    /// 两色线性插值：amount 0 为纯 self、1 为纯 color；微拟物的暗边（混黑 0.15）与高光（混白 0.20）都用它
    public func mix(with color: Color, amount: Double) -> Color {
        let c1 = UIColor(self)
        let c2 = UIColor(color)

        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0

        c1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        c2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)

        return Color(
            red: r1 + (r2 - r1) * amount,
            green: g1 + (g2 - g1) * amount,
            blue: b1 + (b2 - b1) * amount
        )
    }
}
