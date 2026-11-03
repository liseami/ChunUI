/**
 * [INPUT]: 依赖 Theme 的 Color.cc / Font.cc、Components 的 CCDesigin.CCTyperText（打字机）与 ThinLine、Pow 的 shine 重复特效、
 *          StudioArt.xcassets 的 studio/hand-bot 与 studio/hand-human
 * [OUTPUT]: 对外提供 CCAboutPage（关于页正文）、CCAboutLink（底部法律链接一项）、CCStudioArt（两只手的 Image，宿主登录页也从这里取）
 * [POS]: Studio 层「关于」页的唯一实现，胃之书 AboutAppView 定稿，四个 App 一字不差：
 *        Logo 120（圆角 32、投影）· 应用名打字机 · Version · 两只手从两侧弹入并周期扫光 · 标语 · 细线 · 法律链接。
 *        宿主只给 Logo、名字、版本、标语、链接与打开链接的方式；页头（「关于 xx」+ ✕）与 sheet 外壳归宿主
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import Pow
import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 素材：两只手（创造亚当的构图，四个 App 共用）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public enum CCStudioArt {
    /// 机械之手（右侧，从右弹入）
    public static var handBot: Image { Image("studio/hand-bot", bundle: .module) }
    /// 人类之手（左侧，从左弹入）
    public static var handHuman: Image { Image("studio/hand-human", bundle: .module) }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 关于页
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct CCAboutLink: Identifiable, Sendable {
    public let title: String
    public let url: URL
    public var id: URL { url }

    public init(_ title: String, url: URL) {
        self.title = title
        self.url = url
    }
}

public struct CCAboutPage: View {
    private let logo: Image
    private let name: String
    private let version: String
    private let slogan: String
    private let links: [CCAboutLink]
    private let onOpen: (URL) -> Void

    @State private var show = false

    /// - Parameters:
    ///   - logo: 宿主的 App 图标（方图，页内裁圆角 32）
    ///   - links: 底部法律链接（用户协议、隐私政策…），以「｜」相隔
    ///   - onOpen: 点链接时由宿主打开（应用内浏览器 sheet 等）
    public init(logo: Image, name: String, version: String, slogan: String, links: [CCAboutLink], onOpen: @escaping (URL) -> Void) {
        self.logo = logo
        self.name = name
        self.version = version
        self.slogan = slogan
        self.links = links
        self.onOpen = onOpen
    }

    public var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Spacer()
            header
            Spacer()
            ThinLine()
                .padding(.vertical, 32)
            legal
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .onAppear { show = true }
    }

    private var header: some View {
        VStack(alignment: .center, spacing: 44) {
            VStack(alignment: .center, spacing: 12) {
                logo
                    .resizable()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 32))
                    .shadow(color: .cc.shadow.opacity(0.3), radius: 24, x: 0, y: 12)
                CCDesigin.CCTyperText(name, duration: 1.2, font: .cc.title2Bold)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 44)
                Text("Version \(version)")
                    .font(.cc.body)
                    .foregroundStyle(Color.cc.foreground)
            }

            hands

            Text(slogan)
                .font(.cc.callout)
                .foregroundStyle(Color.cc.mutedForeground)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.center)
                .frame(width: 240)
        }
    }

    /// 两只手从两侧弹入（2 s / 3 s 弹簧），到位后每 2 s 扫一道光
    private var hands: some View {
        ZStack(alignment: .center) {
            CCStudioArt.handBot
                .resizable()
                .scaledToFit()
                .frame(width: 160, height: 160)
                .opacity(show ? 1 : 0)
                .offset(x: show ? 0 : 100)
                .animation(.bouncy(duration: 2), value: show)

            CCStudioArt.handHuman
                .resizable()
                .scaledToFit()
                .frame(width: 160, height: 160)
                .opacity(show ? 1 : 0)
                .offset(x: show ? 0 : -100)
                .animation(.bouncy(duration: 3), value: show)
        }
        .scaleEffect(2.2)
        .conditionalEffect(.repeat(.shine, every: 2), condition: show)
    }

    /// 法律链接：一段 Markdown 式富文本，链接取图表第二色，点按交宿主打开
    private var legal: some View {
        Text(linksText)
            .font(.cc.callout)
            .foregroundStyle(Color.cc.mutedForeground)
            .lineSpacing(6)
            .multilineTextAlignment(.center)
            .tint(Color.cc.chart2)
            .fixedSize(horizontal: false, vertical: true)
            .environment(\.openURL, OpenURLAction { url in
                onOpen(url)
                return .handled
            })
            .padding(.horizontal, 24)
    }

    private var linksText: AttributedString {
        var text = AttributedString()
        for (index, link) in links.enumerated() {
            if index > 0 { text += AttributedString(" ｜ ") }
            var item = AttributedString(link.title)
            item.link = link.url
            text += item
        }
        return text
    }
}
