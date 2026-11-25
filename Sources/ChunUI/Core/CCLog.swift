/**
 * [INPUT]: 依赖 OSLog 的 Logger
 * [OUTPUT]: 包内提供 CCLog（internal）：logger(_:) 按分类取 os.Logger；debug / error 两个字符串快捷口
 * [POS]: Core 的统一日志出口。包内日志只走这里，文案一律英文；禁散落 print / NSLog / Logger(subsystem:)。
 *        nonisolated：图片回调与 Metal 装配不在主线程，也能直接记日志。
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import OSLog

nonisolated enum CCLog {
    static let subsystem = "ChunUI"

    /// 取一个分类 logger：需要 OSLog 插值隐私控制的调用方持有它
    static func logger(_ category: String) -> Logger {
        Logger(subsystem: subsystem, category: category)
    }

    /// 调试日志：只在开发期有意义的过程信息
    static func debug(_ message: String, category: String = "general") {
        logger(category).debug("\(message, privacy: .public)")
    }

    /// 错误日志：失败路径必记
    static func error(_ message: String, category: String = "general") {
        logger(category).error("\(message, privacy: .public)")
    }
}
