/**
 * [INPUT]: 依赖 ChunUI Feedback/Text/Effects/Ambient/Icons 公开 API
 * [OUTPUT]: 对外提供 FeedbackPage / SkeletonPage / TextPage / AIEffectsPage / FractalPage / ShaderZooPage / AmbientPage / IconsPage
 * [POS]: ChunUIDemo 的 Feedback + Text + Effects + Ambient + Icons 分区页
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import ChunUI
import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Feedback
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct FeedbackPage: View {
    var body: some View {
        GalleryScroll {
            GallerySection(title: "Toast · Kumo 叠放（旧张退身后成叠，点整叠展开）") {
                HStack(spacing: 8) {
                    CCNeoButton("成功", variant: .secondary, size: .small) { CCToastCenter.shared.show(.success, "已保存") }
                    CCNeoButton("错误", variant: .secondary, size: .small) { CCToastCenter.shared.show(.error, "网络异常") }
                    CCNeoButton("加载", variant: .secondary, size: .small) {
                        CCToastCenter.shared.show(.loading, "上传中…")
                        try? await Task.sleep(nanoseconds: 1_500_000_000)
                        CCToastCenter.shared.show(.success, "完成")
                    }
                    CCNeoButton("连发", variant: .secondary, size: .small) {
                        CCToastCenter.shared.show(.success, "第一张：已保存")
                        try? await Task.sleep(nanoseconds: 600_000_000)
                        CCToastCenter.shared.show(.info, "第二张：正在同步到云端")
                        try? await Task.sleep(nanoseconds: 600_000_000)
                        CCToastCenter.shared.show(.warning, "第三张：网络波动，已自动重试")
                    }
                }
            }
            GallerySection(title: "沉底 Alert · Twitter 双胶囊（禁 UIAlert）") {
                CCNeoButton("删除确认", variant: .danger, fullWidth: true) {
                    AppHelper.shared.showBottomAlert(
                        title: "删除这条记录？",
                        message: "删除后不可恢复。",
                        actions: [CCAlertAction(title: "删除", role: .destructive)]
                    )
                }
            }
            GallerySection(title: "原生 Sheet · AppHelper.presentSheet") {
                HStack(spacing: 8) {
                    CCNeoButton(".form", size: .small) {
                        AppHelper.shared.presentSheet(.form) { SheetDemoContent(name: ".form 全高") }
                    }
                    CCNeoButton(".half", size: .small) {
                        AppHelper.shared.presentSheet(.half) { SheetDemoContent(name: ".half 半高") }
                    }
                    CCNeoButton(".compact", size: .small) {
                        AppHelper.shared.presentSheet(.compact(280)) { SheetDemoContent(name: ".compact 280pt") }
                    }
                }
            }
            GallerySection(title: "CCEmptyState · 统一缺省态") {
                CCEmptyState(kind: .knowledge, message: "这里还什么都没有", compact: true)
                    .frame(height: 200)
            }
        }
        .navigationTitle("Feedback")
    }
}

private struct SheetDemoContent: View {
    let name: String
    var body: some View {
        VStack(spacing: 14) {
            Text(name).ccText(font: .cc.lgBold, color: .cc.foreground)
            CCNeoButton("收起", variant: .outline) { AppHelper.shared.dismissSheet() }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.cc.background)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Skeleton & Shimmer
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct SkeletonPage: View {
    var body: some View {
        GalleryScroll {
            GallerySection(title: "CCSkeleton · 骨架编排（镜像真实布局）") {
                CCSkeleton {
                    HStack(spacing: 12) {
                        CCBone(height: 44, circle: true)
                        VStack(alignment: .leading, spacing: 8) {
                            CCBone(width: 120, height: 12)
                            CCBoneText(lines: 2)
                        }
                    }
                }
            }
            GallerySection(title: "shimmer · 扫光修饰符") {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.cc.muted)
                    .frame(height: 64)
                    .shimmer()
            }
        }
        .navigationTitle("Skeleton")
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Text
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct TextPage: View {
    @State private var streamed = ""
    private let full = "流式文本会带着光标逐字浮现，稳定后光标自动隐藏。"

    var body: some View {
        GalleryScroll {
            GallerySection(title: "CCTyperText · 打字机") {
                CCDesigin.CCTyperText("质感是一种可以携带的资产。")
            }
            GallerySection(title: "CCStreamingText · 流式（模拟 AI 输出）") {
                CCStreamingText(streamed)
                CCNeoButton("重放流", variant: .outline, size: .small) {
                    streamed = ""
                    for ch in full {
                        streamed.append(ch)
                        try? await Task.sleep(nanoseconds: 60_000_000)
                    }
                }
            }
            GallerySection(title: "MarkdownText") {
                MarkdownText("**加粗** 与 *斜体*，~~删除线~~，`code` 一应俱全。")
            }
        }
        .navigationTitle("Text")
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - AI Effects（Aurora / Generating / Sweep）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct AIEffectsPage: View {
    @State private var auroraOn = true

    var body: some View {
        GalleryScroll {
            GallerySection(title: "CCAuroraLayer · AI 工作态极光（暂停零帧）") {
                CCAuroraLayer(visible: auroraOn)
                    .frame(height: 110)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                CCNeoButton(auroraOn ? "熄灭" : "点亮", variant: .outline, size: .small) { auroraOn.toggle() }
            }
            GallerySection(title: "CCGeneratingCover · 呼吸点阵 + 对表流光") {
                CCGeneratingCover()
                    .frame(height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            GallerySection(title: "CCGradientWavesView · 发言涟漪（MTKView 海面，speech 抖动）") {
                SpeechWavesDemo()
            }
            GallerySection(title: "CCSpeechBubbleShape · 一体尖尾气泡（Laper tooltip 法）") {
                Text("尾巴与气泡是一条闭合路径")
                    .ccText(font: .cc.smBold, color: .cc.foreground)
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
                    .padding(.bottom, 12 + CCSpeechBubbleShape.tailHeight)
                    .background {
                        CCSpeechBubbleShape()
                            .fill(Color.cc.card)
                            .stroke(Color.cc.border, lineWidth: 1)
                    }
            }
            GallerySection(title: "CCCardSwap · centered 居中翻动") {
                CCCardSwap(count: 5, style: .centered, cardSize: CGSize(width: 240, height: 130), verticalDistance: 12, delay: 1.0, flyInIntro: true) { index in
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.cc.card)
                        .overlay { RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.cc.border, lineWidth: 1) }
                        .overlay { Text("Card \(index + 1)").ccText(font: .cc.lgBold, color: .cc.foreground) }
                        .shadow(color: .black.opacity(0.08), radius: 10, y: 5)
                }
                .frame(maxWidth: .infinity)
            }
            GallerySection(title: "CCCardSwap · 3D 卡堆轮换（1 秒一页）") {
                CCCardSwap(count: 6, cardSize: CGSize(width: 210, height: 120), delay: 1.0) { index in
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.cc.foreground)
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(.white.opacity(0.35), lineWidth: 1)
                        }
                        .overlay {
                            Text("Card \(index + 1)")
                                .ccText(font: .cc.lgBold, color: .cc.background)
                        }
                }
                .frame(maxWidth: .infinity)
            }
            GallerySection(title: "CCParticleText · 粒子聚字（拖动斥开）") {
                CCParticleText("$200,000,000", fontSize: 44)
                    .frame(height: 150)
            }
            GallerySection(title: "CCSplitFlapText · 机场翻牌板") {
                VStack(spacing: 16) {
                    CCSplitFlapText(phrases: ["$20,000,000+"], fontSize: 22, flipsPerChar: 9, charset: "0123456789")
                    CCSplitFlapText(phrases: ["ZINNER", "SIGNAL"], fontSize: 30, loop: true)
                }
            }
            GallerySection(title: "CCSweepLight · 转场扫光（全屏覆盖窗）") {
                CCNeoButton("Fire ✦", variant: .primary) { CCSweepLight.fire() }
            }
        }
        .navigationTitle("AI Effects")
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Fractal Floor（九分形）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct FractalPage: View {
    private let kinds: [(String, CCFractalFloor.Kind)] = [
        ("Julia", .julia), ("Newton³", .newton3), ("Mandelbrot", .mandelbrot),
        ("Burning Ship", .burningShip), ("Tricorn", .tricorn), ("Celtic", .celtic),
        ("Phoenix", .phoenix), ("Multibrot³", .multibrot3), ("Newton⁴", .newton4),
    ]
    @State private var kind: CCFractalFloor.Kind = .mandelbrot

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(kinds, id: \.0) { name, k in
                        Button {
                            kind = k
                        } label: {
                            Text(name)
                                .ccText(font: .cc.sm, color: kind == k ? .cc.primaryForeground : .cc.foreground)
                                .padding(.horizontal, 12)
                                .frame(height: 32)
                                .ccNeoChrome(kind == k ? .primary : .secondary, height: 32)
                        }
                        .buttonStyle(CCNeoPressStyle())
                    }
                }
                .padding(.cc.base)
            }
            CCFractalFloor(edge: .bottom, height: 420, kind: kind)
                .id(kind)
                .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .background(Color.cc.background)
        .navigationTitle("Fractal Floor")
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Shader Zoo
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct ShaderZooPage: View {
    var body: some View {
        GalleryScroll {
            GallerySection(title: "MetaBalls · 元球") {
                MetaBallsBackground()
                    .frame(height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            GallerySection(title: "Silk · 丝绸") {
                SilkView()
                    .frame(height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            GallerySection(title: "Beams · 光束") {
                BeamsView()
                    .frame(height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            GallerySection(title: "ColorBends · 颜色弯曲") {
                ColorBendsView()
                    .frame(height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            GallerySection(title: "RainbowLine · 彩虹线") {
                RainbowLineView()
                    .frame(height: 60)
            }
            GallerySection(title: "CCSkyHeroCard · 极光卡 + 点阵") {
                CCSkyHeroCard(height: 260) {
                    Text("金刚区")
                        .font(.cc.title2Bold)
                        .foregroundStyle(Color.cc.foreground)
                }
            }
        }
        .navigationTitle("Shader Zoo")
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Ambient
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct AmbientPage: View {
    var body: some View {
        GalleryScroll {
            GallerySection(title: "FluidGradient · 流体渐变") {
                FluidGradient(
                    blobs: [.cc.primary, Color(hex: "9000ff"), Color(hex: "00e5ff")],
                    highlights: [.cc.primary.opacity(0.6)],
                    speed: 1.0
                )
                .frame(height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            GallerySection(title: "OrbView · 拟物 AI 球") {
                HStack {
                    Spacer()
                    OrbView()
                        .frame(width: 140, height: 140)
                    Spacer()
                }
            }
            GallerySection(title: "CCRainbowBar · 彩虹进度") {
                CCRainbowBar(progress: 0.66)
            }
            GallerySection(title: "GridBackground · 网格") {
                GridBackground()
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .navigationTitle("Ambient")
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Icons
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct IconsPage: View {
    private let names = [
        "search-default", "settings-01", "arrow-right", "arrow-left", "plus-default",
        "chevron-right", "chevron-down", "three-dots-menu-horizontal", "pencil-edit",
        "delete-dustbin01", "file-default", "file-text", "file-plus", "sparkle-ai01",
        "user-love-heart", "calendar-default",
    ]

    var body: some View {
        GalleryScroll {
            GallerySection(title: "PikaIcon · 随包 1225 枚模板矢量（示例 16 枚）") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 64))], spacing: 14) {
                    ForEach(names, id: \.self) { name in
                        VStack(spacing: 6) {
                            PikaIcon(name, size: 22, color: .cc.foreground)
                            Text(name.split(separator: "-").first.map(String.init) ?? name)
                                .ccText(font: .cc.sm, color: .cc.mutedForeground)
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
        .navigationTitle("PikaIcon")
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 涟漪演示（speech 开关驱动能量包络）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

private struct SpeechWavesDemo: View {
    @State private var speaking = false

    var body: some View {
        ZStack(alignment: .bottom) {
            CCGradientWavesView(speech: speaking ? 1 : 0)
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            CCNeoButton(speaking ? "停止发言" : "模拟发言", variant: .secondary, size: .small) {
                speaking.toggle()
            }
            .padding(.bottom, 10)
        }
    }
}
