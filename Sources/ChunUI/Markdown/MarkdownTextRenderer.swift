/**
 * [INPUT]: 依赖 Foundation 的字符串处理（经 Core/CCExports 转出，本文件不写 import）
 * [OUTPUT]: 对外提供 MarkdownTextSegment（文本片段 + TextStyles 样式位）与 MarkdownTextRenderer（parse 解析）
 * [POS]: Markdown 的解析层；MarkdownText 组件只消费它的片段数组
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

/// 用于存储 Markdown 文本的解析结果
public struct MarkdownTextSegment: Equatable {
    let text: String
    let styles: TextStyles
    
    public struct TextStyles: OptionSet, Equatable {
        public let rawValue: Int
        
        public init(rawValue: Int) { self.rawValue = rawValue }

        public static let normal = TextStyles([])
        public static let bold = TextStyles(rawValue: 1 << 0)
        public static let italic = TextStyles(rawValue: 1 << 1)
        public static let strikethrough = TextStyles(rawValue: 1 << 2)
        public static let underline = TextStyles(rawValue: 1 << 3)
        public static let code = TextStyles(rawValue: 1 << 4)
        public static let h1 = TextStyles(rawValue: 1 << 5)
        public static let h2 = TextStyles(rawValue: 1 << 6)
        public static let h3 = TextStyles(rawValue: 1 << 7)
        public static let h4 = TextStyles(rawValue: 1 << 8)
        public static let h5 = TextStyles(rawValue: 1 << 9)
        public static let h6 = TextStyles(rawValue: 1 << 10)
    }
    
    public init(text: String, styles: TextStyles = .normal) {
        self.text = text
        self.styles = styles
    }
}

/// Markdown 文本渲染器
public class MarkdownTextRenderer {
    private struct Token {
        let pattern: String
        let style: MarkdownTextSegment.TextStyles
        let isLineStart: Bool
        
        public init(pattern: String, style: MarkdownTextSegment.TextStyles, isLineStart: Bool = false) {
            self.pattern = pattern
            self.style = style
            self.isLineStart = isLineStart
        }
    }
    
    private static let tokens: [Token] = [
        // 标题标记
        Token(pattern: "######", style: .h6, isLineStart: true),
        Token(pattern: "#####", style: .h5, isLineStart: true),
        Token(pattern: "####", style: .h4, isLineStart: true),
        Token(pattern: "###", style: .h3, isLineStart: true),
        Token(pattern: "##", style: .h2, isLineStart: true),
        Token(pattern: "#", style: .h1, isLineStart: true),
        // 其他标记
        Token(pattern: "**", style: .bold),
        Token(pattern: "*", style: .italic),
        Token(pattern: "~~", style: .strikethrough),
        Token(pattern: "__", style: .underline),
        Token(pattern: "`", style: .code)
    ]
    
    /// 把原始 Markdown 文本解析成文本片段数组
    static func parse(_ text: String) -> [MarkdownTextSegment] {
        var segments: [MarkdownTextSegment] = []
        var currentText = ""
        var activeStyles: MarkdownTextSegment.TextStyles = .normal
        var i = text.startIndex
        var isLineStart = true
        
        while i < text.endIndex {
            let char = text[i]
            var matched = false
            
            // 检查每种标记
            for token in tokens {
                // 只在行首检查需要在行首的标记
                if token.isLineStart && !isLineStart {
                    continue
                }
                
                if let matchRange = matchToken(token.pattern, at: i, in: text) {
                    // 处理当前累积的文本
                    if !currentText.isEmpty {
                        segments.append(MarkdownTextSegment(text: currentText, styles: activeStyles))
                        currentText = ""
                    }
                    
                    // 对于标题标记，移除其他标题样式
                    if token.isLineStart {
                        activeStyles.remove([.h1, .h2, .h3, .h4, .h5, .h6])
                        activeStyles.insert(token.style)
                        // 跳过标题后的空格
                        i = matchRange.upperBound
                        while i < text.endIndex && text[i] == " " {
                            i = text.index(after: i)
                        }
                        matched = true
                        break
                    } else {
                        // 切换样式状态
                        if activeStyles.contains(token.style) {
                            activeStyles.remove(token.style)
                        } else {
                            activeStyles.insert(token.style)
                        }
                        i = matchRange.upperBound
                        matched = true
                        break
                    }
                }
            }
            
            if !matched {
                currentText.append(char)
                i = text.index(after: i)
            }
            
            // 更新行首状态
            isLineStart = char == "\n"
        }
        
        // 添加最后剩余的文本
        if !currentText.isEmpty {
            segments.append(MarkdownTextSegment(text: currentText, styles: activeStyles))
        }
        
        return segments
    }
    
    private static func matchToken(_ pattern: String, at index: String.Index, in text: String) -> Range<String.Index>? {
        let remainingText = text[index...]
        let patternLength = pattern.count
        
        guard remainingText.count >= patternLength else { return nil }
        
        let possibleMatch = remainingText.prefix(patternLength)
        if possibleMatch == pattern {
            return index..<text.index(index, offsetBy: patternLength)
        }
        return nil
    }
} 
