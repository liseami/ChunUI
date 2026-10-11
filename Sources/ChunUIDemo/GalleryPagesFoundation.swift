/**
 * [INPUT]: 依赖 ChunUI Theme 令牌（Color.cc / Font.cc / CGFloat.cc / CCMotion）与 CCGlassView
 * [OUTPUT]: 对外提供 ThemePage / MotionPage / ButtonsPage / FormsPage / CardsPage
 * [POS]: ChunUIDemo 的 Foundation + Controls 分区页
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import ChunUI
import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Theme
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct ThemePage: View {
    private let swatches: [(String, Color)] = [
        ("primary", .cc.primary), ("background", .cc.background), ("card", .cc.card),
        ("panel", .cc.panel), ("sidebarBg", .cc.sidebarBg), ("muted", .cc.muted),
        ("accent", .cc.accent), ("border", .cc.border), ("destructive", .cc.destructive),
        ("success", .cc.success), ("foreground", .cc.foreground), ("mutedFg", .cc.mutedForeground),
    ]

    var body: some View {
        GalleryScroll {
            GallerySection(title: "语义调色板 · Color.cc.*") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 92))], spacing: 10) {
                    ForEach(swatches, id: \.0) { name, color in
                        VStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(color)
                                .frame(height: 44)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.cc.border, lineWidth: 0.5)
                                )
                            Text(name).ccText(font: .cc.sm, color: .cc.mutedForeground)
                        }
                    }
                }
            }
            GallerySection(title: "三梯度字号铁律 · Font.cc.*") {
                Text("lg 24 · 页面 title 锚点").ccText(font: .cc.lgBold, color: .cc.foreground)
                Text("base 17 · 正文锚点").ccText(font: .cc.base, color: .cc.foreground)
                Text("sm 13 · 辅助小字").ccText(font: .cc.sm, color: .cc.mutedForeground)
            }
            GallerySection(title: "一行换肤") {
                Text("var c = CCColors.default\nc.primary = .hex(\"007aff\")\nChunUI.configure(colors: c)")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(Color.cc.mutedForeground)
            }
        }
        .navigationTitle("Theme")
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Motion
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct MotionPage: View {
    @State private var shown = false

    var body: some View {
        GalleryScroll {
            GallerySection(title: "ccReveal · 零过冲入场（index 错峰）") {
                VStack(spacing: 8) {
                    ForEach(0 ..< 4, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.cc.muted)
                            .frame(height: 40)
                            .overlay(Text("row \(i)").ccText(font: .cc.sm, color: .cc.mutedForeground))
                            .ccReveal(shown, index: i)
                    }
                }
            }
            GallerySection(title: "ccWaveReveal · 微过冲波浪") {
                HStack(spacing: 8) {
                    ForEach(0 ..< 5, id: \.self) { i in
                        Circle()
                            .fill(Color.cc.primary.opacity(0.85))
                            .frame(width: 36, height: 36)
                            .ccWaveReveal(shown, index: i)
                    }
                }
            }
            CCNeoButton("重播入场", variant: .outline) {
                shown = false
                try? await Task.sleep(nanoseconds: 250_000_000)
                shown = true
            }
        }
        .onAppear { shown = true }
        .navigationTitle("Motion")
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Buttons
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct ButtonsPage: View {
    var body: some View {
        GalleryScroll {
            GallerySection(title: "CCNeoButton · 五变体") {
                CCNeoButton("Primary", variant: .primary, fullWidth: true) { try? await Task.sleep(nanoseconds: 800_000_000) }
                CCNeoButton("Secondary", variant: .secondary, fullWidth: true) {}
                CCNeoButton("Ghost", variant: .ghost, fullWidth: true) {}
                CCNeoButton("Outline", variant: .outline, fullWidth: true) {}
                CCNeoButton("Danger", variant: .danger, icon: "delete-dustbin01", fullWidth: true) {}
            }
            GallerySection(title: "尺寸与图标") {
                HStack(spacing: 10) {
                    CCNeoButton("Large", size: .large) {}
                    CCNeoButton("Med", size: .medium) {}
                    CCNeoButton("Small", size: .small, icon: "sparkle-ai01") {}
                }
            }
            GallerySection(title: "玻璃族 · GlassIconButton / CircleButton") {
                HStack(spacing: 14) {
                    CCDesigin.GlassIconButton(icon: "search-default") {}
                    CCDesigin.GlassIconButton(icon: "settings-01", tint: .cc.primary) {}
                    CCDesigin.CircleButton(icon: "arrow-left") {}
                    CCDesigin.TabBarStyleBackButton()
                }
            }
            GallerySection(title: "玻璃修饰符 · softGlassStyle（iOS 26 Liquid Glass / 以下微拟物）") {
                HStack(spacing: 14) {
                    Text("capsule").ccText(font: .cc.sm, color: .cc.foreground)
                        .padding(14).softGlassStyle(.capsule)
                    Text("circle").ccText(font: .cc.sm, color: .cc.foreground)
                        .padding(14).softGlassStyle()
                    Text("rounded").ccText(font: .cc.sm, color: .cc.foreground)
                        .padding(14).softGlassStyle(.roundedRectangle(12))
                    GlassFaceSample().frame(width: 72, height: 64)
                }
            }
        }
        .navigationTitle("Buttons")
    }
}

private struct GlassFaceSample: UIViewRepresentable {
    func makeUIView(context: Context) -> CCGlassView {
        CCGlassView(shape: .roundedRectangle(24))
    }

    func updateUIView(_ uiView: CCGlassView, context: Context) {}
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Forms
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct FormsPage: View {
    @State private var text = ""
    @State private var longText = ""
    @State private var toggle = true
    @State private var checked = true
    @State private var segment = 1

    var body: some View {
        GalleryScroll {
            GallerySection(title: "CCInput / CCTextArea") {
                CCDesigin.CCInput(placeholder: "单行输入", text: $text)
                CCDesigin.CCTextArea(placeholder: "多行输入", text: $longText)
            }
            GallerySection(title: "CCSegmentedControl · 凹槽胶囊") {
                CCSegmentedControl(selection: $segment, items: [
                    (0, "Left"),
                    (1, "Center"),
                    (2, "Right"),
                ])
            }
            GallerySection(title: "CCToggle / CCCheckbox") {
                HStack(spacing: 20) {
                    CCDesigin.CCToggle(isOn: $toggle)
                    CCDesigin.CCCheckbox(isChecked: $checked)
                    Spacer()
                }
            }
            GallerySection(title: "CCNeoInput · 微拟物输入") {
                CCNeoInput(placeholder: "焦点环走主题色", text: $text)
            }
        }
        .navigationTitle("Forms")
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Cards & Tags
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct CardsPage: View {
    var body: some View {
        GalleryScroll {
            GallerySection(title: "CCAppleCard · 连续圆角三级软阴影") {
                CCAppleCard {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Apple Card").ccText(font: .cc.baseBold, color: .cc.cardForeground)
                        Text("发丝边 + 三级软阴影").ccText(font: .cc.sm, color: .cc.mutedForeground)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.cc.base)
                }
            }
            GallerySection(title: "胶囊标签 · CCCuteTag / CCKeycapTag / CCProTag") {
                HStack(spacing: 8) {
                    CCCuteTag("128 人", icon: "user-love-heart")
                    CCKeycapTag("BETA")
                    CCKeycapTag("NEW", color: .cc.success)
                    CCProTag()
                }
            }
            GallerySection(title: "CCSettingRow · 设置行") {
                VStack(spacing: 0) {
                    CCSettingRow(icon: "settings-01", title: "通用设置", trailing: .chevron)
                    CCSettingRow(icon: "sparkle-ai01", title: "会员", trailing: .pro)
                }
                .ccGroupCard()
            }
            GallerySection(title: "CCChipFlow · 换行流布局") {
                CCChipFlow(spacing: 8) {
                    ForEach(["SwiftUI", "Metal", "Monochrome", "Neo", "Glass", "Aurora"], id: \.self) { chip in
                        Text(chip)
                            .ccText(font: .cc.sm, color: .cc.foreground)
                            .padding(.horizontal, 10)
                            .frame(height: 28)
                            .ccNeoChrome(.secondary, height: 28)
                    }
                }
            }
        }
        .navigationTitle("Cards & Tags")
    }
}
