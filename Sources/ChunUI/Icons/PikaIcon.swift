//
//  PikaIcon.swift
//  Chat0IM
//

/**
 * [INPUT]: 依赖 DesignSystem/PikaIcons.xcassets 的 pika 命名空间模板矢量资产（1225 枚，迁自 Laper pika-icons）
 * [OUTPUT]: 对外提供 PikaIcon 组件、PikaIcon.uiImage（模板 UIImage）与 PikaIcon.Name 常用图标名常量
 * [POS]: DesignSystem/Compents 的图标原子组件，全应用统一图标入口，替代散落的 SF Symbols
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - PikaIcon
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Pika 图标：24×24 stroke 模板矢量，可染色可缩放
/// 用法: PikaIcon(.search) / PikaIcon("arrow-right", size: 18, color: .cc.mutedForeground)
public struct PikaIcon: View {
    public let name: String
    public var size: CGFloat
    public var color: Color

    public init(_ name: String, size: CGFloat = 18, color: Color = .cc.foreground) {
        self.name = name
        self.size = size
        self.color = color
    }

    public var body: some View {
        Image("pika/\(name)", bundle: .module)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .foregroundStyle(color)
    }

    /// UIKit 取同一张模板图
    public static func uiImage(_ name: String) -> UIImage? {
        UIImage(named: "pika/\(name)", in: .module, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 常用图标名（防拼写错误的薄常量层，全量 1225 枚按需追加）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public extension PikaIcon {
    enum Name {
        public static let search = "search-default"
        public static let settings = "settings-01"
        public static let arrowRight = "arrow-right"
        public static let arrowLeft = "arrow-left"
        public static let plus = "plus-default"
        public static let chevronRight = "chevron-right"
        public static let chevronDown = "chevron-down"
        public static let more = "three-dots-menu-horizontal"
        public static let edit = "pencil-edit"
        public static let trash = "delete-dustbin01"
        public static let file = "file-default"
        public static let fileText = "file-text"
        public static let filePlus = "file-plus"
        public static let folder = "folder-default"
        public static let folderPlus = "folder-plus"
        public static let close = "multiple-cross-cancel-default"
        public static let copy = "copy-default"
        public static let save = "hardrive"
        public static let broom = "clean-broom"
        public static let note = "note-outline"
        public static let thumbsUp = "thumb-reaction-like"
        public static let thumbsDown = "thumb-reaction-dislike"
        public static let refresh = "refresh"
        public static let bold = "bold"
        public static let italic = "italic"
        public static let underline = "underline"
        public static let headingH1 = "heading-h1"
        public static let headingH2 = "heading-h2"
        public static let headingH3 = "heading-h3"
        public static let listBullet = "list-check"
        public static let listChecklist = "list-check-box"
        public static let code = "code"
        public static let text = "text"
        public static let keyboardDown = "keyboard-chevron-down"
        public static let minimizeTwoArrow = "minimize-two-arrow"
    }
}
