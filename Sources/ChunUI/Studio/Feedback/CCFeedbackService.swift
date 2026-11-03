/**
 * [INPUT]: 依赖 UIKit 的 UIImage、Presentation 的 AppHelper（缺省提示出口）、Studio 的 CCStudio（邀请分享缺省落点）、本目录 CCFBText（类型名）
 * [OUTPUT]: 对外提供 CCFeedbackCategory（三类）、CCFeedbackDraft（一份待提交的意见）、CCResolvedFeedback / CCFeedbackPage（修复历史一条与一页）、
 *           CCFeedbackError（upload · submit）、CCFeedbackService（宿主实现的唯一接缝）与 CCFeedbackInbox（未读数单例，宿主入口钮的角标与「解决」段共读）
 * [POS]: Studio/Feedback 的公开契约。意见箱只认这个协议，不认任何宿主类型（DIP）：截图怎么传、接口在哪、会话何时落定，全由宿主的服务决定。
 *        CCFeedbackInbox 取代各宿主自己的 FeedbackInbox：真相在中台，本机不存；refresh 失败保留旧值，markSeen 先乐观清零再上报
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI
import UIKit

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 数据：类型 · 草稿 · 修复历史
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// 提出时的三类，点选顺序即 allCases；rawValue 即后端 category：bug · experience 已有功能意见 · suggestion 新功能请求
public enum CCFeedbackCategory: String, CaseIterable, Sendable {
    case bug
    case experience
    case suggestion

    /// 界面上的名字（Studio 表，跟 CCLanguage）
    public var title: String { CCFBText.t("feedback.category.\(rawValue)") }
}

/// 一份待提交的意见：正文已去首尾空白，截图与选图同序，端侧环境由意见箱自己填
public struct CCFeedbackDraft {
    /// 契约上限：正文字数
    public static let contentLimit = 2000

    public let category: CCFeedbackCategory
    public let content: String
    public let images: [UIImage]
    /// 「短版本 (构建号)」
    public let appVersion: String
    /// 机型标识，如 iPhone16,2
    public let device: String
    public let osVersion: String

    public init(category: CCFeedbackCategory, content: String, images: [UIImage], appVersion: String, device: String, osVersion: String) {
        self.category = category
        self.content = content
        self.images = images
        self.appVersion = appVersion
        self.device = device
        self.osVersion = osVersion
    }
}

/// 修复历史一条：全体用户已解决的问题，新的在前
public struct CCResolvedFeedback: Identifiable, Sendable {
    public let id: String
    /// 后端原值；认不出的（旧版 other / recognition）按已有功能意见显示
    public let category: String
    public let content: String
    public let resolvedAt: Date?
    /// 空即显示通用的「一位用户」
    public let proposerName: String
    /// 空即 ChunUI.defaultAvatarURL
    public let proposerAvatarURL: String

    public init(id: String, category: String, content: String, resolvedAt: Date?, proposerName: String, proposerAvatarURL: String) {
        self.id = id
        self.category = category
        self.content = content
        self.resolvedAt = resolvedAt
        self.proposerName = proposerName
        self.proposerAvatarURL = proposerAvatarURL
    }

    var kind: CCFeedbackCategory { CCFeedbackCategory(rawValue: category) ?? .experience }
}

/// 一页修复历史
public struct CCFeedbackPage: Sendable {
    public let items: [CCResolvedFeedback]
    public let hasMore: Bool

    public init(items: [CCResolvedFeedback], hasMore: Bool) {
        self.items = items
        self.hasMore = hasMore
    }
}

/// 提交失败的两种：截图没传上去 · 意见没交上去；意见箱按它出对应的提示
public enum CCFeedbackError: Error, Sendable {
    case upload
    case submit
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 接缝：宿主实现，意见箱只认它
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

@MainActor
public protocol CCFeedbackService: AnyObject {
    /// 宿主本地化的应用名（「向 %@ 提意见」）
    var appName: String { get }
    /// 截图上限；0 即不收截图（截图格与脚注都不出）
    var imageLimit: Int { get }
    /// 邀请页系统分享里的一句话（宿主本地化）
    var inviteShareText: String { get }
    /// 提交：截图怎么传由宿主决定；失败抛 CCFeedbackError.upload 或 .submit
    func submit(_ draft: CCFeedbackDraft) async throws
    /// 修复历史一页（page 从 1 起）
    func resolved(page: Int, pageSize: Int) async throws -> CCFeedbackPage
    /// 已解决未看的条数
    func unread() async throws -> Int
    /// 进「解决」段：标已读
    func markSeen() async throws
    /// 提示出口；缺省走 ChunUI 的 AppHelper.pushNotification，宿主有自己的提示外观就接管
    func toast(_ type: AppHelper.NotificationType)
}

public extension CCFeedbackService {
    /// 邀请分享的落点：缺省取工作室身份的分享地址，没有即 App Store 页
    var inviteShareURL: URL { CCStudio.shareURL ?? CCStudio.storeURL }

    func toast(_ type: AppHelper.NotificationType) {
        AppHelper.shared.pushNotification(type: type)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 未读：入口钮的角标与「解决」段共读这一个数
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

@MainActor
public final class CCFeedbackInbox: ObservableObject {
    public static let shared = CCFeedbackInbox()

    @Published public private(set) var unread = 0
    /// 宿主启动时 configure 的服务；意见箱从这里取
    private(set) var service: CCFeedbackService?

    public var hasUnread: Bool { unread > 0 }

    private init() {}

    /// 启动时接上宿主的服务（一次）
    public func configure(_ service: CCFeedbackService) {
        self.service = service
    }

    /// 取服务端未读数；失败保留旧值，没接服务即 0
    public func refresh() async {
        guard let service else {
            unread = 0
            return
        }
        guard let count = try? await service.unread() else { return }
        unread = count
    }

    /// 进「解决」段：角标当帧清零，再写服务端的已读时刻
    public func markSeen() async {
        unread = 0
        try? await service?.markSeen()
    }
}
