/**
 * [INPUT]: 依赖 SwiftUI 的 AttributedString 与 Text、Theme 的 Font.cc / Color.cc 与 CCFontFamily.uiFont（代码段 12pt 字）、本目录 MarkdownTextRenderer 的分段
 * [OUTPUT]: 对外提供 MarkdownText（轻量 Markdown 文本视图：粗体 · 斜体 · 行内代码）
 * [POS]: Markdown 的展示件；代码段字随宿主字族（缺省系统字），正文字由调用方传入
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI

 

public struct MarkdownText: View {
    let text: String
    let font: Font
    let color: Color
    
    @State private var attributedText: AttributedString = .init("")
    
    public init(_ text: String, font: Font = .body, color: Color = .primary) {
        self.text = text
        self.font = font
        self.color = color
    }
    
    public var body: some View {
        Text(attributedText)
            .ccText(font: font, color: color)
            .onAppear {
                updateAttributedText()
            }
            .onChange(of: text) { _, _ in
                updateAttributedText()
            }
    }
    
    private func updateAttributedText() {
        let segments = MarkdownTextRenderer.parse(text)
        var newAttributedText = AttributedString("")
        
        for segment in segments {
            var segmentText = AttributedString(segment.text)
            
            // 应用字体
            if segment.styles.contains(.code) {
                segmentText.font = CCFontFamily.uiFont(size: 12)
            } else {
                var textFont = font
                if segment.styles.contains(.bold) {
                    textFont = textFont.bold()
                }
                if segment.styles.contains(.italic) {
                    textFont = textFont.italic()
                }
                segmentText.font = textFont
            }
            
            // 应用删除线
            if segment.styles.contains(.strikethrough) {
                segmentText.strikethroughStyle = .single
            }
            
            // 应用下划线
            if segment.styles.contains(.underline) {
                segmentText.underlineStyle = .single
            }
            
            // 如果是代码，添加浅灰色背景
            if segment.styles.contains(.code) {
                segmentText.backgroundColor = Color.cc.muted
            }
            
            newAttributedText += segmentText
        }
        
        attributedText = newAttributedText
    }
}

#Preview {
    VStack(spacing: 20) {
        MarkdownText("这是一个**粗体**和*斜体*文本示例")
            .ccText(font: .cc.body , color: .cc.foreground)
        
        MarkdownText("~~删除线~~和__下划线__测试")
            .ccText(font: .cc.callout , color: .cc.mutedForeground)
        
        MarkdownText("`行内代码`和**粗体**混合\n第二行*斜体*文本")
            .ccText(font: .cc.footnote , color: .cc.mutedForeground)
            
        MarkdownText("组合样式：**粗体中的*斜体***和`代码`")
            .ccText(font: .cc.callout , color: .cc.foreground)
    }
    .padding()
}
