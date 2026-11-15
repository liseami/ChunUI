//
//  CCSplitFlapText.swift
//  ChunUI
//

/**
 * [INPUT]: 依赖 Color.cc 设计令牌、Theme 的 CCFontFamily（翻牌字）、SwiftUI rotation3DEffect、Reduce Motion；形制移植 React Bits SplitFlapText（机场翻牌板：暗色瓦片 + 中缝 + 上翻页折下/下翻页落定两相动画）
 * [OUTPUT]: 对外提供 CCSplitFlapText——逐字翻牌文本板（进场从空白翻入随机字符序列后落定目标；可多词循环；每瓦随 index 错拍）
 * [POS]: Components 的数字/字母展示特效原语，宿主 Onboarding 收益页等消费；Reduce Motion 直落无翻页
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCSplitFlapText（翻牌板：目标短语逐瓦翻入；loop 时多词循环）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct CCSplitFlapText: View {
    var phrases: [String]
    var fontSize: CGFloat
    var flipDuration: Double
    var stagger: Double
    var flipsPerChar: Int
    var cycleDelay: Double
    var loop: Bool
    var charset: String
    var tileColor: Color
    var textColor: Color
    var tileRadius: CGFloat
    var gap: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var chars: [Character] = []

    public init(
        phrases: [String],
        fontSize: CGFloat = 40,
        flipDuration: Double = 0.12,
        stagger: Double = 0.05,
        flipsPerChar: Int = 6,
        cycleDelay: Double = 2.4,
        loop: Bool = false,
        charset: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789",
        tileColor: Color = .cc.foreground,
        textColor: Color = .cc.background,
        tileRadius: CGFloat = 7,
        gap: CGFloat = 5
    ) {
        self.phrases = phrases.isEmpty ? [" "] : phrases
        self.fontSize = fontSize
        self.flipDuration = flipDuration
        self.stagger = stagger
        self.flipsPerChar = flipsPerChar
        self.cycleDelay = cycleDelay
        self.loop = loop
        self.charset = charset.isEmpty ? "0123456789" : charset
        self.tileColor = tileColor
        self.textColor = textColor
        self.tileRadius = tileRadius
        self.gap = gap
    }

    /// 板宽 = 最长短语，短的右侧补空格（React 版 padEnd 同构）
    private var width: Int { max(1, phrases.map(\.count).max() ?? 1) }
    private var tileW: CGFloat { fontSize * 0.78 }
    private var tileH: CGFloat { fontSize * 1.08 }

    public var body: some View {
        HStack(spacing: gap) {
            ForEach(0 ..< width, id: \.self) { index in
                CCFlapTile(
                    char: index < chars.count ? chars[index] : " ",
                    tileWidth: tileW, tileHeight: tileH, fontSize: fontSize,
                    radius: tileRadius, tileColor: tileColor, textColor: textColor,
                    flipDuration: flipDuration
                )
            }
        }
        .task(id: phrases) { await run() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(phrases.first ?? "")
    }

    private func pad(_ phrase: String) -> [Character] {
        Array(phrase.padding(toLength: width, withPad: " ", startingAt: 0))
    }

    private func randomChar() -> Character {
        charset.randomElement() ?? " "
    }

    @MainActor
    private func run() async {
        if reduceMotion {
            chars = pad(phrases[0])
            return
        }
        chars = Array(repeating: " ", count: width)
        var phraseIndex = 0
        let staggerTicks = max(0, Int((stagger / flipDuration).rounded()))
        while !Task.isCancelled {
            let target = pad(phrases[phraseIndex])
            // 每瓦序列：flipsPerChar 个随机字符 + 目标字符；已达标的瓦不动
            let sequences: [[Character]] = target.indices.map { i in
                chars[i] == target[i] ? [] : (0 ..< flipsPerChar).map { _ in randomChar() } + [target[i]]
            }
            let maxSteps = sequences.map(\.count).max() ?? 0
            let totalTicks = maxSteps + staggerTicks * max(0, width - 1)
            var tick = 0
            while tick < totalTicks, !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(flipDuration * 1_000_000_000))
                tick += 1
                var next = chars
                for i in 0 ..< width {
                    let local = tick - 1 - i * staggerTicks
                    if local >= 0, local < sequences[i].count {
                        next[i] = sequences[i][local]
                    }
                }
                chars = next
            }
            guard loop, phrases.count > 1, !Task.isCancelled else { return }
            try? await Task.sleep(nanoseconds: UInt64(cycleDelay * 1_000_000_000))
            phraseIndex = (phraseIndex + 1) % phrases.count
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 单瓦（上下半分体 + 两相翻页：前翻上折 → 后翻落定；中缝铰链高光）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

private struct CCFlapTile: View {
    let char: Character
    let tileWidth: CGFloat
    let tileHeight: CGFloat
    let fontSize: CGFloat
    let radius: CGFloat
    let tileColor: Color
    let textColor: Color
    let flipDuration: Double

    @State private var current: Character = " "
    @State private var incoming: Character?
    @State private var frontAngle: Double = 0
    @State private var backAngle: Double = 90
    @State private var generation = 0

    var body: some View {
        ZStack(alignment: .top) {
            // 静态层：上半露新字（前翻掀开即见），下半持旧字（后翻落定覆盖）
            half(incoming ?? current, top: true)
            half(current, top: false)
                .offset(y: tileHeight / 2)

            if incoming != nil {
                // 前翻页：旧字上半，绕中缝向下折
                half(current, top: true)
                    .rotation3DEffect(.degrees(frontAngle), axis: (x: 1, y: 0, z: 0),
                                      anchor: .bottom, perspective: 0.42)
                // 后翻页：新字下半，从中缝落定
                half(incoming ?? current, top: false)
                    .rotation3DEffect(.degrees(backAngle), axis: (x: 1, y: 0, z: 0),
                                      anchor: .top, perspective: 0.42)
                    .offset(y: tileHeight / 2)
            }

            // 中缝铰链：上亮下暗一线
            VStack(spacing: 0) {
                Rectangle().fill(.white.opacity(0.14)).frame(height: 0.5)
                Rectangle().fill(.black.opacity(0.55)).frame(height: 1)
            }
            .frame(width: tileWidth)
            .offset(y: tileHeight / 2 - 0.75)
            .allowsHitTesting(false)
        }
        .frame(width: tileWidth, height: tileHeight)
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.28), radius: 5, y: 2.5)
        .onAppear { current = char }
        .onChange(of: char) { _, newChar in flip(to: newChar) }
    }

    /// 半瓦：整字居中后裁半；上半底色微亮、下半微暗（机械瓦片受光）
    private func half(_ character: Character, top: Bool) -> some View {
        Text(String(character == " " ? " " : character))
            .font(CCFontFamily.font(size: fontSize, weight: .heavy, design: .monospaced))
            .foregroundStyle(textColor)
            .shadow(color: .black.opacity(0.4), radius: 1, y: 1)
            .frame(width: tileWidth, height: tileHeight)
            .frame(width: tileWidth, height: tileHeight / 2, alignment: top ? .top : .bottom)
            .background {
                LinearGradient(
                    colors: top
                        ? [tileColor.mix(with: .white, amount: 0.14), tileColor]
                        : [tileColor, tileColor.mix(with: .black, amount: 0.16)],
                    startPoint: .top, endPoint: .bottom
                )
            }
            .clipped()
    }

    private func flip(to newChar: Character) {
        guard newChar != current else { return }
        // 上一拍未收尾：先落定再开新翻
        if let pending = incoming { current = pending }
        incoming = newChar
        generation += 1
        let gen = generation
        frontAngle = 0
        backAngle = 90
        withAnimation(.easeIn(duration: flipDuration * 0.5)) { frontAngle = -90 }
        withAnimation(.easeOut(duration: flipDuration * 0.5).delay(flipDuration * 0.5)) { backAngle = 0 }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(flipDuration * 1.1 * 1_000_000_000))
            guard generation == gen else { return }
            current = newChar
            incoming = nil
            frontAngle = 0
            backAngle = 90
        }
    }
}

#Preview("翻牌板") {
    VStack(spacing: 28) {
        CCSplitFlapText(phrases: ["$20,000,000+"], fontSize: 26, flipsPerChar: 9, charset: "0123456789")
        CCSplitFlapText(phrases: ["ZINNER", "SIGNAL"], fontSize: 40, loop: true)
    }
    .padding(24)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.cc.background)
}
