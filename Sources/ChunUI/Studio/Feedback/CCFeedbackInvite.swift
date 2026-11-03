/**
 * [INPUT]: 依赖本目录 CCFeedbackInbox.shared.service（inviteShareText · inviteShareURL）、CCFBPrimaryButton、CCFBTokens / CCFBFont / CCFBText；Studio 的 CCStudio（storeURL，无服务时兜底）、
 *          Presentation 的 AppHelper（topMostViewController 呈现系统分享、mada 触感）、Icons 的 PikaIcon check-tick-single、Color.cc（foreground · mutedForeground · background · success）
 * [OUTPUT]: 对内提供 CCFeedbackInvitePage（意见箱「邀请」段：进化路径插图 · 标题 · 两句主张 · <24h 承诺 · 分享按钮）
 * [POS]: Studio/Feedback 的邀请页，逐值移植胃之书 FeedbackInviteView：单色细线插图只在终点着一点成功绿，入场一次描线、节点依次长出（减弱动效直接成图）。
 *        分享走系统分享表，从最上层控制器呈现（本页在 sheet 里），带宿主给的一句话与本 App 的链接；不碰网络与会话
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI
import UIKit

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 页面：插图 · 标题 · 主张 · 承诺 · 分享
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct CCFeedbackInvitePage: View {
    private typealias T = CCFBTokens.Invite

    var body: some View {
        ScrollView {
            VStack(spacing: T.blockGap) {
                CCFeedbackEvolutionArt()
                    .frame(width: T.artWidth, height: T.artHeight)

                VStack(spacing: T.textGap) {
                    Text(CCFBText.t("feedback.invite.title"))
                        .ccText(font: CCFBFont.title1Bold, color: .cc.foreground)
                    Text(CCFBText.t("feedback.invite.line1"))
                        .ccText(font: CCFBFont.callout, color: .cc.mutedForeground)
                    Text(CCFBText.t("feedback.invite.line2"))
                        .ccText(font: CCFBFont.callout, color: .cc.mutedForeground)
                }
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: T.textGap) {
                    Text("<24h")
                        .font(.system(size: T.statSize, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(Color.cc.foreground)
                    Text(CCFBText.t("feedback.invite.promise"))
                        .ccText(font: CCFBFont.footnote, color: .cc.mutedForeground)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                CCFBPrimaryButton(title: CCFBText.t("feedback.invite.share")) {
                    share()
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, CCFBTokens.pageInset)
            .padding(.top, T.pageTop)
            .padding(.bottom, T.pageBottom)
        }
    }

    /// 系统分享：宿主的一句话 + 本 App 链接；本页在 sheet 里，从最上层控制器呈现
    private func share() {
        AppHelper.shared.mada(.light)
        let service = CCFeedbackInbox.shared.service
        let text = service?.inviteShareText ?? ""
        let items: [Any] = [text, service?.inviteShareURL ?? CCStudio.storeURL].filter { !(($0 as? String)?.isEmpty ?? false) }
        let sheet = UIActivityViewController(activityItems: items, applicationActivities: nil)
        AppHelper.shared.topMostViewController()?.present(sheet, animated: true)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 插图「进化路径」：三条极淡基线上一根细线自左下升到右上，四个节点渐大（一次次意见），终点落成成功绿的对勾
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

private struct CCFeedbackEvolutionArt: View {
    private typealias T = CCFBTokens.Invite
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    /// 节点在单位框里的位置与直径（终点最大）
    private static let nodes: [(x: CGFloat, y: CGFloat, d: CGFloat)] = [
        (0.08, 0.84, 8), (0.36, 0.66, 12), (0.63, 0.44, 16), (0.90, 0.18, 40),
    ]
    private static let baselines: [CGFloat] = [0.3, 0.6, 0.9]
    private static let lineWidth: CGFloat = 1.5
    private static let baselineOpacity: Double = 0.08
    private static let checkSize: CGFloat = 20

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                ForEach(Self.baselines, id: \.self) { y in
                    Path { p in
                        p.move(to: CGPoint(x: 0, y: size.height * y))
                        p.addLine(to: CGPoint(x: size.width, y: size.height * y))
                    }
                    .stroke(Color.cc.foreground.opacity(Self.baselineOpacity), style: StrokeStyle(lineWidth: 1, dash: [3, 5]))
                }

                CCFeedbackEvolutionPath(points: Self.nodes.map { CGPoint(x: $0.x, y: $0.y) })
                    .trim(from: 0, to: shown ? 1 : 0)
                    .stroke(Color.cc.foreground, style: StrokeStyle(lineWidth: Self.lineWidth, lineCap: .round, lineJoin: .round))

                ForEach(Self.nodes.indices, id: \.self) { i in
                    node(i)
                        .position(x: size.width * Self.nodes[i].x, y: size.height * Self.nodes[i].y)
                        .scaleEffect(shown ? 1 : 0.2, anchor: .center)
                        .opacity(shown ? 1 : 0)
                        .animation(reduceMotion ? nil : .spring(duration: 0.5, bounce: 0.3).delay(T.nodeStagger * Double(i + 1)), value: shown)
                }
            }
        }
        .accessibilityHidden(true)
        .onAppear {
            guard !shown else { return }
            if reduceMotion { shown = true } else { withAnimation(.easeOut(duration: T.drawDuration)) { shown = true } }
        }
    }

    /// 前三个是空心描边的点，终点是成功绿实心圆里一枚白勾
    @ViewBuilder private func node(_ i: Int) -> some View {
        let d = Self.nodes[i].d
        if i == Self.nodes.count - 1 {
            Circle()
                .fill(Color.cc.success)
                .frame(width: d, height: d)
                .overlay { PikaIcon("check-tick-single", size: Self.checkSize, color: .white) }
        } else {
            Circle()
                .fill(Color.cc.background)
                .overlay { Circle().stroke(Color.cc.foreground, lineWidth: Self.lineWidth) }
                .frame(width: d, height: d)
        }
    }
}

/// 过各节点的平滑升线：相邻两点之间一段三次曲线，控制点取水平方向的三分之一，起止切线水平
private struct CCFeedbackEvolutionPath: Shape {
    let points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let pts = points.map { CGPoint(x: rect.minX + $0.x * rect.width, y: rect.minY + $0.y * rect.height) }
        guard let first = pts.first else { return path }
        path.move(to: first)
        for (a, b) in zip(pts, pts.dropFirst()) {
            let dx = (b.x - a.x) / 3
            path.addCurve(to: b, control1: CGPoint(x: a.x + dx, y: a.y), control2: CGPoint(x: b.x - dx, y: b.y))
        }
        return path
    }
}
