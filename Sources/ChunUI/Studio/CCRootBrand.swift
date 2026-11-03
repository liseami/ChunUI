/**
 * [INPUT]: 依赖 Theme 的 Color.cc（发丝边）、Components 的 CCNeoPressStyle（头像按压弹簧）、Studio 的 CCStudioText.settings（头像钮缺省无障碍名）；
 *          宿主主包的 Wordmark 模板矢量（deploy/ios/wordmark 生成）
 * [OUTPUT]: 对外提供 CCRootBrand（一级页头左上的品牌位：圆头像钮 + 英文小写字标）与 CCRootBrandTokens（几何）
 * [POS]: Studio 层的页头品牌位，单仓根「页头范式」的唯一实现。四个 App 的一级页头左上只摆它：头像点按进设置页（阿奇例外：呼出侧边栏），字标只读不接触摸。
 *        几何取自 perplexity 页头实测（3× 截图）：头像 40、头像到字标 12、字标 x 高 ≈ 头像 × 0.344。
 *        字标画布的纵向中心就是 x 高中线（wordmark.py 定画布上下界），所以居中摆放即 x 高中线对准头像圆心。
 *        头像内容（取图方式、占位图）由宿主给，本件只裁圆、描发丝边；头像不挂未读点（意见箱未读在宿主意见钮的 ccCountBadge）；字标颜色跟随宿主的 foregroundStyle
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 几何：四端逐值一致，宿主不改
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public enum CCRootBrandTokens {
    /// 头像直径
    public static let avatar: CGFloat = 40
    /// 头像右沿到字标墨迹左沿（字标画布左右贴墨迹）
    public static let gap: CGFloat = 12
    /// 字标画布高：x 高 = 高 × 528 / 992 ≈ 13.8，即头像 × 0.344
    public static let wordmark: CGFloat = 26
    /// 头像发丝边
    public static let hairline: CGFloat = 0.5
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 品牌位：头像钮 · 字标
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct CCRootBrand<Avatar: View>: View {
    private typealias T = CCRootBrandTokens

    let name: String
    let wordmark: Image
    let actionLabel: String
    let action: () -> Void
    let avatar: Avatar

    /// name：字标的无障碍名（品牌英文名）；wordmark 缺省取宿主主包的 Wordmark；
    /// actionLabel：头像钮的无障碍名，缺省「设置」（阿奇的头像呼出侧边栏，宿主改给侧边栏名）
    public init(name: String, wordmark: Image = Image("Wordmark"),
                actionLabel: String = CCStudioText.settings, action: @escaping () -> Void, @ViewBuilder avatar: () -> Avatar) {
        self.name = name
        self.wordmark = wordmark
        self.actionLabel = actionLabel
        self.action = action
        self.avatar = avatar()
    }

    public var body: some View {
        HStack(spacing: T.gap) {
            Button(action: action) {
                avatar
                    .frame(width: T.avatar, height: T.avatar)
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(Color.cc.border, lineWidth: T.hairline))
                    .contentShape(Circle())
            }
            .buttonStyle(CCNeoPressStyle())
            .accessibilityLabel(actionLabel)

            wordmark
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(height: T.wordmark)
                .accessibilityLabel(name)
                .accessibilityAddTraits(.isHeader)
                .allowsHitTesting(false)
        }
        .fixedSize()
    }
}
