/**
 * [INPUT]: 依赖 Foundation 的 DateFormatter / TimeZone
 * [OUTPUT]: 包内提供 String 的随机中文串、截断、UTC 转本地时间、手机号掩码；Optional<String>.or；Date.toTimeZoneString
 * [POS]: Extensions 的字符串与时间工具；不含业务函数
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI

extension String{
    
    /// 生成随机中文字符串，长度在 length 前后随机波动
    static func randomChineseString(length: Int) -> String {
        // 中文Unicode范围：0x4e00 - 0x9fff
        let chineseStart = 0x4e00
        let chineseEnd = 0x9fff
        
        // 计算最终长度，在传入长度的前后随机波动
        let variance = Int.random(in: -Swift.min(3, length/2)...Swift.min(3, length/2))
        let finalLength = Swift.max(1, length + variance) // 确保长度至少为1
        
        var result = ""
        
        for _ in 0..<finalLength {
            // 随机选择一个中文字符的Unicode值
            if let randomScalar = UnicodeScalar(Int.random(in: chineseStart...chineseEnd)) {
                result.append(Character(randomScalar))
            }
        }
        
        return result
    }
    
    
    func or(_ or : String) -> String{
        if self.isEmpty{
            return or
        }else{
            return self
        }
    }

    /// 截到 maxLength 个字符，超出部分以 "..." 结尾
    func limitedTo(_ maxLength: Int) -> String {
        guard count > maxLength else { return self }
        return String(prefix(maxLength)) + "..."
    }
}

extension Optional where Wrapped == String {
    /// 字符串为 nil 或空时返回 or，否则返回原串
    func or(_ or: String) -> String {
        if let self = self, !self.isEmpty {
            return self
        } else {
            return or
        }
    }
}

extension String {
    /// 把 UTC 时间串转成本地时区时间串，输出格式缺省 "yyyy-MM-dd HH:mm"
    func toLocalTimeString(format: String = "yyyy-MM-dd HH:mm") -> String? {
        let formatter = DateFormatter()
        
        // 尝试解析包含毫秒的格式
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        
        if let date = formatter.date(from: self) {
            formatter.timeZone = TimeZone.current
            formatter.dateFormat = format
            return formatter.string(from: date)
        }
        
        // 尝试解析不包含毫秒的格式
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        guard let date = formatter.date(from: self) else { return nil }
        
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = format
        return formatter.string(from: date)
    }

    /// 把 UTC 时间串转成本地时区的 Date
    func toLocalTimeDate() -> Date {
        let formatter = DateFormatter()
        // 尝试解析包含毫秒的格式
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        if let date = formatter.date(from: self) {
            return date
        }
        // 尝试解析不包含毫秒的格式
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        guard let date = formatter.date(from: self) else { return .now }
        return date
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 手机号掩码
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extension String {
    /// 手机号掩码：去国家码再掩中间四位（"+8613812345678" → "138****5678"）
    func maskedPhone() -> String {
        var cleaned = self

        // 移除国家区号前缀
        if cleaned.hasPrefix("+86") {
            cleaned = String(cleaned.dropFirst(3))
        } else if cleaned.hasPrefix("86") && cleaned.count > 11 {
            cleaned = String(cleaned.dropFirst(2))
        }

        // 确保是 11 位手机号
        guard cleaned.count == 11 else {
            return "***"
        }

        // 格式：前3位 + **** + 后4位
        let prefix = cleaned.prefix(3)
        let suffix = cleaned.suffix(4)
        return "\(prefix)****\(suffix)"
    }
}

extension Date {
    /// 按 pattern 把 Date 格式化为字符串，缺省 ISO 风格微秒格式与 UTC 时区
    func toTimeZoneString(
        _ pattern: String = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
        timeZone: TimeZone = .gmt
    ) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = pattern
        formatter.timeZone = timeZone
        return formatter.string(from: self)
    }
}
