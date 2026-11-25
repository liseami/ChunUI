//
//  StreamingText.swift
//  YUI
//
//  流式传输文本组件 - CCTyperText 同款效果
//

/**
 * [INPUT]: 实时变化的文本字符串
 * [OUTPUT]: 带光标和震动反馈的流式文本显示
 * [POS]: 设计系统 - 流式传输专用文本组件
 *
 * [PROTOCOL]:
 * 1. 文本变化时显示打字光标
 * 2. 新字符出现时触发 mada 震动（节流 0.15s）
 * 3. 使用 contentTransition 实现丝滑动画
 * 4. 文本稳定后自动隐藏光标
 */

import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCStreamingText (统一流式传输组件)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct CCStreamingText: View {
    let text: String
    let cursor: String
    let font: Font
    let color: Color
    let madaEnable: Bool

    // ━━━ 内部状态 ━━━
    @State private var isTyping = false
    @State private var lastMadaTime: Date = .distantPast
    @State private var hideTimer: Timer?

    // ━━━ 配置 ━━━
    private let madaMinInterval: TimeInterval = 0.15
    private let cursorHideDelay: TimeInterval = 0.8

    public init(
        _ text: String,
        cursor: String = "●",
        font: Font = .cc.callout ,
        color: Color = .cc.mutedForeground,
        madaEnable: Bool = true
    ) {
        self.text = text
        self.cursor = cursor
        self.font = font
        self.color = color
        self.madaEnable = madaEnable
    }

    public var body: some View {
        Text(text + (isTyping ? cursor : ""))
            .ccText(font: font, color: color)
            .contentTransition(.numericText())
            .animation(.smooth(duration: 0.15), value: text)
            .onChange(of: text) { _, _ in
                onTextChanged()
            }
            .onDisappear {
                hideTimer?.invalidate()
            }
    }

    // ━━━ 文本变化处理 ━━━
    private func onTextChanged() {
        // 显示光标
        isTyping = true

        // Mada 震动（节流）
        if madaEnable {
            let now = Date()
            if now.timeIntervalSince(lastMadaTime) >= madaMinInterval {
                AppHelper.shared.mada(.soft)
                lastMadaTime = now
            }
        }

        // 重置隐藏计时器
        hideTimer?.invalidate()
        hideTimer = Timer.scheduledTimer(withTimeInterval: cursorHideDelay, repeats: false) { _ in
            withAnimation(.easeOut(duration: 0.2)) {
                isTyping = false
            }
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 兼容别名
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// 兼容旧代码：AnimatedStreamingText -> CCStreamingText
typealias AnimatedStreamingText = CCStreamingText

/// 兼容旧代码：StreamingText -> CCStreamingText
typealias StreamingText = CCStreamingText

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Preview
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

#if DEBUG
#Preview {
    StreamingTextPreview()
}

private struct StreamingTextPreview: View {
    @State private var text = ""
    private let fullText = "这是一段流式出现的文字，带有打字机光标效果。每个新字符都会触发轻微震动，完成后光标自动消失。"

    var body: some View {
        VStack(spacing: 24) {
            CCStreamingText(text)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.cc.background)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            HStack(spacing: 16) {
                Button("开始") { simulateStreaming() }
                    .buttonStyle(.borderedProminent)

                Button("重置") { text = "" }
                    .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color.cc.muted)
    }

    private func simulateStreaming() {
        text = ""
        var index = 0
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            if index < fullText.count {
                let i = fullText.index(fullText.startIndex, offsetBy: index)
                text += String(fullText[i])
                index += 1
            } else {
                timer.invalidate()
            }
        }
    }
}
#endif
