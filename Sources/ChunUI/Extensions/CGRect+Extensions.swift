/**
 * [INPUT]: 依赖 CoreGraphics 的 CGRect（经 SwiftUI 带入）
 * [OUTPUT]: 包内提供 CGRect.aspectFit / aspectFitWidth / aspectFitHeight（等比适配并居中）
 * [POS]: Extensions 的几何原子；转场遮罩按它算目标框
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI

extension CGRect {
    /// 按宽或按高等比适配到 frame（SharedTransitionAnimationController 的遮罩用）
    func aspectFit(to frame: CGRect) -> CGRect {
        let ratio = width / height
        let frameRatio = frame.width / frame.height
        
        // If target frame is narrower than original, fit to width,
        // else if target frame is wider than original, fit to height
        if frameRatio < ratio {
            return aspectFitWidth(to: frame)
        } else {
            return aspectFitHeight(to: frame)
        }
    }

    /// 按 frame 宽度等比适配，并在 frame 内垂直居中
    func aspectFitWidth(to frame: CGRect) -> CGRect {
        let ratio = width / height
        let height = frame.width * ratio
        let offsetY = (frame.height - height) / 2 // Center vertically
        let origin = CGPoint(x: frame.origin.x, y: frame.origin.y + offsetY)
        let size = CGSize(width: frame.width, height: height)
        return CGRect(origin: origin, size: size)
    }

    /// 按 frame 高度等比适配，并在 frame 内水平居中
    func aspectFitHeight(to frame: CGRect) -> CGRect {
        let ratio = height / width
        let width = frame.height * ratio
        let offsetX = (frame.width - width) / 2 // Center horizontally
        let origin = CGPoint(x: frame.origin.x + offsetX, y: frame.origin.y)
        let size = CGSize(width: width, height: frame.height)
        return CGRect(origin: origin, size: size)
    }
}
