/**
 * [INPUT]: 依赖本目录 CCFeedbackService（CCFeedbackInbox.shared.service 与 unread）、CCFBSegmentBar（顶部分段 + 字后角标）、CCFBTextArea / ccfbFieldSurface / CCFBFieldShape / CCFBPrimaryButton、
 *          CCFeedbackResolvedList / CCFeedbackInvitePage、CCFBTokens / CCFBFont / CCFBText；PhotosUI 的 PhotosPicker、Icons 的 PikaIcon、Presentation 的 AppHelper（触感）、Color.cc
 * [OUTPUT]: 对外提供 CCFeedbackBox（意见箱 sheet 的正文：「提出 · 解决 · 邀请」三段）；对内提供 CCFeedbackDraftModel（类型、正文、选图、提交）
 * [POS]: Studio/Feedback 的入口视图，四个 App 的意见箱唯一实现（胃之书 FeedbackView 定稿）。页头（✕）、有填写先问、成功后关都归宿主的 sheet：
 *        本视图只经 isDirty 报脏态、提交成功调 onSubmitted。草稿归容器，来回切段不丢；进「解决」段即 markSeen 清零角标
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import PhotosUI
import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 草稿：类型 · 正文 · 选图 → 交宿主服务提交
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

@MainActor
final class CCFeedbackDraftModel: ObservableObject {
    /// 一张已选截图：id 给 ForEach，移除不靠下标
    struct Shot: Identifiable {
        let id = UUID()
        let image: UIImage
    }

    /// 缺省 Bug：最常见的来意，少点一次
    @Published var category: CCFeedbackCategory = .bug
    @Published var content = ""
    @Published private(set) var shots: [Shot] = []

    private var service: CCFeedbackService? { CCFeedbackInbox.shared.service }
    private var trimmedContent: String { content.trimmingCharacters(in: .whitespacesAndNewlines) }

    var imageLimit: Int { max(0, service?.imageLimit ?? 0) }

    /// 正文非空且不超限
    var canSubmit: Bool { !trimmedContent.isEmpty && content.count <= CCFeedbackDraft.contentLimit }

    /// 填过任何一项：关之前先问
    var isDirty: Bool { !content.isEmpty || !shots.isEmpty }

    /// 还能再选几张
    var remaining: Int { max(0, imageLimit - shots.count) }

    /// 相册选中的按序读出，满额即止；读不出的跳过
    func add(_ items: [PhotosPickerItem]) async {
        for item in items {
            guard remaining > 0 else { break }
            if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                shots.append(Shot(image: image))
            }
        }
    }

    func remove(_ shot: Shot) {
        shots.removeAll { $0.id == shot.id }
    }

    /// 提交：成功返回 true（调用方关 sheet），失败已提示、表单原样保留
    func submit() async -> Bool {
        guard canSubmit else { return false }
        guard let service else {
            AppHelper.shared.pushNotification(type: .error(message: CCFBText.t("feedback.failed")))
            return false
        }
        let draft = CCFeedbackDraft(
            category: category,
            content: trimmedContent,
            images: shots.map(\.image),
            appVersion: Self.appVersion,
            device: Self.modelName,
            osVersion: UIDevice.current.systemVersion
        )
        do {
            try await service.submit(draft)
        } catch CCFeedbackError.upload {
            service.toast(.error(message: CCFBText.t("feedback.upload_failed")))
            return false
        } catch {
            service.toast(.error(message: CCFBText.t("feedback.failed")))
            return false
        }
        service.toast(.success(message: CCFBText.t("feedback.success")))
        return true
    }

    // ━━━ 端侧环境：版本「短版本 (构建号)」、机型标识 ━━━

    private static var appVersion: String {
        let info = Bundle.main.infoDictionary
        let short = (info?["CFBundleShortVersionString"] as? String) ?? "0.0.0"
        let build = (info?["CFBundleVersion"] as? String) ?? "0"
        return "\(short) (\(build))"
    }

    private static var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return Mirror(reflecting: systemInfo.machine).children.reduce("") { id, element in
            guard let value = element.value as? Int8, value != 0 else { return id }
            return id + String(UnicodeScalar(UInt8(value)))
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 容器：顶部「提出 · 解决 · 邀请」；「解决」带未读角标，进段即清零
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct CCFeedbackBox: View {
    private typealias T = CCFBTokens.Compose
    /// 段序：0 提出 · 1 解决 · 2 邀请
    private static let resolvedTab = 1
    private static let inviteTab = 2

    @Binding private var isDirty: Bool
    private let onSubmitted: () -> Void
    private let emptyArt: Image?
    @StateObject private var draft = CCFeedbackDraftModel()
    @ObservedObject private var inbox = CCFeedbackInbox.shared
    @State private var tab = 0

    /// isDirty：有填写即真，宿主据此在关之前先问；onSubmitted：提交成功（提示已出），宿主关 sheet；emptyArt：「解决」空态的插图
    public init(isDirty: Binding<Bool>, onSubmitted: @escaping () -> Void, emptyArt: Image? = nil) {
        _isDirty = isDirty
        self.onSubmitted = onSubmitted
        self.emptyArt = emptyArt
    }

    private var segments: [CCFBSegmentItem] {
        [CCFBSegmentItem(id: "submit", title: CCFBText.t("feedback.tab.submit")),
         CCFBSegmentItem(id: "resolved", title: CCFBText.t("feedback.tab.resolved"), badge: inbox.unread),
         CCFBSegmentItem(id: "invite", title: CCFBText.t("feedback.tab.invite"))]
    }

    public var body: some View {
        VStack(spacing: 0) {
            CCFBSegmentBar(items: segments, selection: $tab)
                .frame(height: CCFBTokens.Segment.height)
                .padding(.horizontal, CCFBTokens.pageInset)
                .padding(.top, T.segmentTop)
                .padding(.bottom, T.segmentBottom)

            switch tab {
            case Self.resolvedTab: CCFeedbackResolvedList(emptyArt: emptyArt)
            case Self.inviteTab: CCFeedbackInvitePage()
            default: CCFeedbackCompose(draft: draft, onSubmitted: onSubmitted)
            }
        }
        .task { await inbox.refresh() }
        .onChange(of: tab) { _, now in
            guard now == Self.resolvedTab else { return }
            Task { await inbox.markSeen() }
        }
        .onChange(of: draft.isDirty, initial: true) { _, dirty in
            if isDirty != dirty { isDirty = dirty }
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 「提出」：标题 · 类型点选 · 说说 · 截图 · 公开说明 · 提交
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

private struct CCFeedbackCompose: View {
    private typealias T = CCFBTokens.Compose

    @ObservedObject var draft: CCFeedbackDraftModel
    let onSubmitted: () -> Void
    @State private var pickerItems: [PhotosPickerItem] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: T.sectionGap) {
                intro

                categoryChips

                CCFBTextArea(placeholder: CCFBText.t("feedback.content.placeholder"), text: $draft.content, limit: CCFeedbackDraft.contentLimit)

                if draft.imageLimit > 0 {
                    VStack(alignment: .leading, spacing: T.titleGap) {
                        shotTiles
                        Text(CCFBText.f("feedback.images.footer", draft.imageLimit))
                            .ccText(font: CCFBFont.footnote, color: .cc.mutedForeground)
                            .padding(.horizontal, CCFBTokens.rowInset)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                VStack(alignment: .leading, spacing: T.titleGap) {
                    CCFBPrimaryButton(title: CCFBText.t("common.submit"), enable: draft.canSubmit) {
                        if await draft.submit() { onSubmitted() }
                    }
                    Text(CCFBText.t("feedback.public_notice"))
                        .ccText(font: CCFBFont.footnote, color: .cc.mutedForeground)
                        .padding(.horizontal, CCFBTokens.rowInset)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, CCFBTokens.pageInset)
            .padding(.top, T.pageTop)
            .padding(.bottom, T.pageBottom)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // ━━━ 标题：大标题与一句副标题，与输入卡内文字同起点 ━━━

    private var intro: some View {
        VStack(alignment: .leading, spacing: T.introGap) {
            Text(CCFBText.f("feedback.title", CCFeedbackInbox.shared.service?.appName ?? ""))
                .ccText(font: CCFBFont.title2Bold, color: .cc.foreground)
            Text(CCFBText.t("feedback.subtitle"))
                .ccText(font: CCFBFont.callout, color: .cc.mutedForeground)
        }
        .padding(.horizontal, CCFBTokens.rowInset)
        .fixedSize(horizontal: false, vertical: true)
    }

    // ━━━ 类型点选：三选一、缺省 Bug；三枚等宽铺满一行，选中实色胶囊、未选灰底 ━━━

    private var categoryChips: some View {
        HStack(spacing: T.chipGap) {
            ForEach(CCFeedbackCategory.allCases, id: \.self) { kind in
                let on = draft.category == kind
                Button {
                    AppHelper.shared.mada(.light)
                    draft.category = kind
                } label: {
                    Text(kind.title)
                        .ccText(font: CCFBFont.subheadlineBold, color: on ? .cc.background : .cc.foreground)
                        .lineLimit(1)
                        .minimumScaleFactor(T.chipMinScale)
                        .padding(.horizontal, T.chipPad)
                        .frame(maxWidth: .infinity, minHeight: T.chipHeight)
                        .background(Capsule().fill(on ? Color.cc.foreground : Color.cc.muted))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
    }

    // ━━━ 截图：缩略图（右上角 ×）+ 加号格；加号格一次只许选剩下的张数 ━━━

    private var shotTiles: some View {
        HStack(spacing: T.tileGap) {
            ForEach(draft.shots) { shot in
                shotTile(shot)
            }
            if draft.remaining > 0 {
                PhotosPicker(selection: $pickerItems, maxSelectionCount: draft.remaining,
                             selectionBehavior: .ordered, matching: .images) {
                    PikaIcon("plus-default", size: T.addIcon, color: .cc.mutedForeground)
                        .frame(width: T.tile, height: T.tile)
                        .ccfbFieldSurface()
                }
                .accessibilityLabel(CCFBText.t("common.add"))
                .onChange(of: pickerItems) { _, items in
                    guard !items.isEmpty else { return }
                    pickerItems = []
                    Task { await draft.add(items) }
                }
            }
        }
    }

    private func shotTile(_ shot: CCFeedbackDraftModel.Shot) -> some View {
        Image(uiImage: shot.image)
            .resizable()
            .scaledToFill()
            .frame(width: T.tile, height: T.tile)
            .clipShape(CCFBFieldShape())
            .overlay(alignment: .topTrailing) {
                Button { draft.remove(shot) } label: {
                    PikaIcon("multiple-cross-cancel-default", size: T.removeIcon, color: .white)
                        .padding(T.removePad)
                        .background(Circle().fill(Color.black.opacity(T.removeBacking)))
                }
                .buttonStyle(.plain)
                .padding(T.removeInset)
                .accessibilityLabel(CCFBText.t("feedback.images.remove"))
            }
    }
}
