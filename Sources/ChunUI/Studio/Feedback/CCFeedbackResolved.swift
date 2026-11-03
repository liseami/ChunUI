/**
 * [INPUT]: 依赖本目录 CCFeedbackInbox.shared.service（resolved 分页）、CCResolvedFeedback、CCFBBone / CCFBBoneText / CCFBBoneGated、ccfbCard、CCFBEmptyView、CCFBTokens / CCFBFont / CCFBText；
 *          Components 的 CCDesigin.CCWebImage（头像，经宿主 CCImageLoader）、Core 的 ChunUI.defaultAvatarURL、Icons 的 PikaIcon check-tick-single、Color.cc
 * [OUTPUT]: 对内提供 CCFeedbackResolvedList（意见箱「解决」段：全体用户已修复的问题，新的在前）与 CCFeedbackResolvedPager（第一页 · 加载更多 · 冷却 · 失败退页）
 * [POS]: Studio/Feedback 的修复历史，逐值移植胃之书 FeedbackResolvedView + CCListDataScrollView 的分页编排：首载过门槛出三张同形骨架卡，回来为空即空态，触底出两行段落位再取下一页，下拉刷新。
 *        一条一张原卡片：类型胶囊 · 已修复 · 解决日期 / 正文 / 提出人头像与昵称，卡右侧垫淡绿大对勾（压出卡沿由卡形裁掉）。只读；已读与角标归 CCFeedbackInbox
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 分页：重载取第一页；加载更多离上次加载不足 cooldown 秒不发，失败退回页码
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

@MainActor
final class CCFeedbackResolvedPager: ObservableObject {
    private typealias T = CCFBTokens.Resolved

    @Published private(set) var isLoadingMore = false
    @Published private(set) var isLoading = false
    /// 第一页已回来（成败都算）：之前列表为空即是加载态，不落空态
    @Published private(set) var loaded = false
    @Published private(set) var noMore = false
    @Published private(set) var items: [CCResolvedFeedback] = []

    private var currentPage = 1
    private var lastLoadTime: Date = .distantPast

    func reload() async {
        guard !isLoading else { return }
        isLoading = true
        currentPage = 1
        noMore = false
        if let page = await fetch(page: currentPage) {
            items = page.items
            noMore = !page.hasMore
        }
        lastLoadTime = Date()
        isLoading = false
        loaded = true
    }

    func loadMore() async {
        guard !noMore, !isLoading, !isLoadingMore, Date().timeIntervalSince(lastLoadTime) >= T.cooldown else { return }
        isLoadingMore = true
        currentPage += 1
        if let page = await fetch(page: currentPage) {
            if page.items.isEmpty {
                noMore = true
            } else {
                items.append(contentsOf: page.items)
                noMore = !page.hasMore
            }
        } else {
            currentPage -= 1
        }
        lastLoadTime = Date()
        isLoadingMore = false
    }

    /// 一页：没接服务或请求失败都给 nil
    private func fetch(page: Int) async -> CCFeedbackPage? {
        guard let service = CCFeedbackInbox.shared.service else { return nil }
        return try? await service.resolved(page: page, pageSize: T.pageSize)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 列表：头距 · 第一页（骨架门槛 → 空态或卡）· 触底加载更多；下拉刷新
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct CCFeedbackResolvedList: View {
    private typealias T = CCFBTokens.Resolved

    let emptyArt: Image?
    @StateObject private var pager = CCFeedbackResolvedPager()

    private var swap: AnyTransition {
        .opacity.combined(with: .scale(scale: 0.98)).animation(.smooth)
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                Color.clear.frame(height: T.listTop)
                Group {
                    // 第一页没回来：过门槛才出骨架，回来为空即淡换成空态
                    if pager.items.isEmpty {
                        CCFBBoneGated(loading: !pager.loaded) {
                            CCFBEmptyView(art: emptyArt,
                                          title: CCFBText.t("feedback.resolved.empty.title"),
                                          subline: CCFBText.t("feedback.resolved.empty.subtitle"))
                                .padding(.top, T.emptyTop)
                        } bones: {
                            VStack(spacing: T.rowGap) {
                                ForEach(0 ..< T.bones, id: \.self) { _ in CCFeedbackResolvedBones() }
                            }
                            .padding(.horizontal, CCFBTokens.pageInset)
                            .padding(.top, T.listTop)
                        }
                    } else {
                        ForEach(pager.items) { item in
                            CCFeedbackResolvedRow(item: item)
                                .padding(.horizontal, CCFBTokens.pageInset)
                                .padding(.bottom, T.rowGap)
                        }
                    }
                }
                .transition(swap)

                if !pager.items.isEmpty {
                    footer.transition(swap)
                }
            }
        }
        .task { await pager.reload() }
        .refreshable { await pager.reload() }
        .padding(.bottom, T.listBottom)
    }

    /// 加载更多：一出现就请求下一页；没有更多时只留空行，否则两行段落骨架
    private var footer: some View {
        Group {
            if pager.noMore && !pager.isLoadingMore {
                Text("")
            } else {
                CCFBBoneText(lines: T.footerLines)
                    .padding(.horizontal, CCFBTokens.Bone.listInset)
            }
        }
        .opacity(pager.isLoadingMore || pager.noMore ? 1 : T.footerIdle)
        .frame(height: T.footerHeight)
        .frame(maxWidth: .infinity, alignment: .center)
        .task {
            if !pager.isLoadingMore && !pager.noMore { await pager.loadMore() }
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 一条：类型 · 已修复 · 日期 / 正文 / 提出人
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

private struct CCFeedbackResolvedRow: View {
    private typealias T = CCFBTokens.Resolved
    let item: CCResolvedFeedback

    /// 系统长日期，跟随系统语言（胃之书 DateFormat.longDate）
    private static let longDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: T.blockGap) {
            HStack(spacing: T.proposerGap) {
                Text(item.kind.title)
                    .ccText(font: CCFBFont.captionBold, color: item.kind == .bug ? .cc.destructive : .cc.foreground)
                    .padding(.horizontal, T.chipPadH)
                    .padding(.vertical, T.chipPadV)
                    .background(Capsule().fill(Color.cc.muted))
                Text(CCFBText.t("feedback.resolved.fixed"))
                    .ccText(font: CCFBFont.footnoteBold, color: .cc.foreground)
                Spacer(minLength: 0)
                Text(item.resolvedAt.map { Self.longDate.string(from: $0) } ?? "")
                    .ccText(font: CCFBFont.footnote, color: .cc.mutedForeground)
            }

            Text(item.content)
                .ccText(font: CCFBFont.body, color: .cc.foreground)
                .lineLimit(T.contentLines)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: T.proposerGap) {
                CCDesigin.CCWebImage(str: item.proposerAvatarURL.isEmpty ? ChunUI.defaultAvatarURL : item.proposerAvatarURL)
                    .frame(width: T.avatar, height: T.avatar)
                    .clipShape(Circle())
                Text(CCFBText.f("feedback.resolved.proposer", item.proposerName.isEmpty ? CCFBText.t("feedback.resolved.someone") : item.proposerName))
                    .ccText(font: CCFBFont.footnote, color: .cc.mutedForeground)
                    .lineLimit(1)
            }
        }
        .padding(T.cardPad)
        .frame(maxWidth: .infinity, alignment: .leading)
        // 淡绿大对勾垫在内容之下、卡底之上：靠右竖向居中，压出卡沿的那截由卡形裁掉
        .background(alignment: .trailing) {
            PikaIcon("check-tick-single", size: T.check, color: Color.cc.success.opacity(T.checkOpacity))
                .offset(x: T.checkBleed)
                .accessibilityHidden(true)
        }
        .ccfbCard()
        .accessibilityElement(children: .combine)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 首载骨架：与真卡同形（顶行 · 两行正文 · 头像与名字）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

private struct CCFeedbackResolvedBones: View {
    private typealias T = CCFBTokens.Resolved

    var body: some View {
        VStack(alignment: .leading, spacing: T.blockGap) {
            CCFBBone(width: 120)
            CCFBBoneText(lines: 2)
            HStack(spacing: T.proposerGap) {
                CCFBBone(height: T.avatar, circle: true)
                CCFBBone(width: 80)
            }
        }
        .padding(T.cardPad)
        .frame(maxWidth: .infinity, alignment: .leading)
        .ccfbCard()
    }
}
