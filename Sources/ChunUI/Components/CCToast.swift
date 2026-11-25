//
//  CCToast.swift
//  ChunUI
//

/**
 * [INPUT]: 依赖 PikaIcon、CCAqiBubbleTail、Color.cc/Font.cc 设计令牌与 CCUploadToast（上传进度胶囊，同窗合流）；气泡路由锚点由宿主上报 advisorAvatarAnchor；叠放编舞参照 Cloudflare Kumo / Laper Toast（曲线 cubic-bezier(0.22,1,0.36,1)）
 * [OUTPUT]: 对外提供 CCToastCenter 单例（info/success/warning/error/loading 多张栈事实源 + Route 双路由 + 展开冻结倒计时）、CCToastView（Kumo 叠放：最新在前，旧张退身后缩 0.1 上探 12pt 对齐前张尺寸正文淡出；点击整叠展开成列表并暂停倒计时；限 3 张可见；卡片 = 状态色圆徽 + 正文 + 关闭钮进度环）、CCAqiBubbleToast（iMessage 式气泡：尖尾指向 tabbar 头像、点外即关）、CCKeyboardWatcher 与 CCToastWindow 置顶窗口（触摸只在叠层命中区/气泡态接管，其余全透传）
 * [POS]: Components 的全应用 toast 唯一系统——AppHelper.pushNotification 的唯一出口（路由判定在 AppHelper），全自研零第三方；宿主 SceneDelegate 挂载 CCToastWindow
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import Combine
import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 编舞常量（Kumo 原值：曲线 / 叠距 / 缩放步 / 可见上限）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

enum CCToastMotion {
    /// Kumo 原曲线 cubic-bezier(0.22, 1, 0.36, 1) · 0.5s
    static let kumo = Animation.timingCurve(0.22, 1, 0.36, 1, duration: 0.5)
    /// 叠放上探（--peek）与展开列表间距（--gap）
    static let peek: CGFloat = 12
    /// 每层缩放步进
    static let scaleStep: CGFloat = 0.1
    /// 可见上限：第 4 张起只占位不显（倒计时照走，栈不因看不见而堆积）
    static let visibleLimit = 3
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCToastCenter（多张栈事实源：结果顶换 loading；展开冻结全部倒计时）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

@MainActor
public final class CCToastCenter: ObservableObject {
    public static let shared = CCToastCenter()

    public enum Kind: Equatable {
        case info
        case success
        case warning
        case error
        case loading
    }

    /// 呈现路由：顶部叠放卡片（缺省）/ tabbar 阿奇头像气泡（一级页面专属，锚点为头像全局 frame）
    public enum Route: Equatable {
        case capsule
        case aqiBubble(anchor: CGRect)
    }

    public struct Toast: Identifiable, Equatable {
        public let id = UUID()
        let kind: Kind
        let message: String
        let route: Route
        let duration: TimeInterval
        /// 运行中的截止时刻（进度环从这里读剩余）
        var deadline: Date
        /// 非 nil = 冻结中（展开阅读），值为剩余秒数
        var frozenRemaining: TimeInterval?
    }

    @Published private(set) var toasts: [Toast] = []
    /// hover 的触屏等价物：点击整叠展开成列表；展开期间全部倒计时与进度环冻结（Kumo：用户在读就不该消失）
    @Published var expanded = false {
        didSet {
            guard expanded != oldValue else { return }
            expanded ? freezeAll() : thawAll()
        }
    }

    /// tabbar 阿奇头像的全局 frame（宿主持续上报），气泡路由的锚点事实源
    public var advisorAvatarAnchor: CGRect = .null
    /// 胶囊叠层的全局命中区（CCToastView 上报），CCToastWindow 触摸策略事实源
    var capsuleHitRect: CGRect = .null

    private var hideTasks: [UUID: Task<Void, Never>] = [:]

    private init() {}

    /// 兼容旧读法：最新一条
    var current: Toast? { toasts.last }

    public func show(_ kind: Kind, _ message: String, route: Route = .capsule) {
        // 既有契约：结果 toast 顶换在场 loading
        if kind != .loading {
            for toast in toasts where toast.kind == .loading {
                close(toast.id)
            }
        }
        // loading 常驻等待被顶换，15s 安全阀防悬挂；错误多停留一拍
        let duration: TimeInterval = switch kind {
        case .loading: 15
        case .error: 3.6
        default: 2.8
        }
        var toast = Toast(kind: kind, message: message, route: route,
                          duration: duration, deadline: Date().addingTimeInterval(duration),
                          frozenRemaining: nil)
        if expanded { toast.frozenRemaining = duration }   // 展开中进场即冻结
        withAnimation(CCToastMotion.kumo) {
            toasts.append(toast)
        }
        if toast.frozenRemaining == nil { schedule(toast.id, after: duration) }
        // 总量安全阀：栈深超 6 挤掉最旧
        if toasts.count > 6, let oldest = toasts.first { close(oldest.id) }
    }

    /// 关一张（退场由 SwiftUI transition 演，身后张立即前补）
    public func close(_ id: UUID) {
        hideTasks[id]?.cancel()
        hideTasks[id] = nil
        withAnimation(CCToastMotion.kumo) {
            toasts.removeAll { $0.id == id }
            if toasts.count <= 1 { expanded = false }
        }
    }

    /// 旧 API：清场
    public func dismiss() {
        hideTasks.values.forEach { $0.cancel() }
        hideTasks.removeAll()
        withAnimation(CCToastMotion.kumo) {
            toasts.removeAll()
            expanded = false
        }
    }

    // ━━━ 可暂停倒计时（Kumo/Base UI：展开阅读期间冻结，收起续走）━━━

    private func schedule(_ id: UUID, after seconds: TimeInterval) {
        hideTasks[id] = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(max(0, seconds) * 1_000_000_000))
            guard !Task.isCancelled else { return }
            self?.close(id)
        }
    }

    private func freezeAll() {
        let now = Date()
        for index in toasts.indices where toasts[index].frozenRemaining == nil {
            hideTasks[toasts[index].id]?.cancel()
            hideTasks[toasts[index].id] = nil
            // 至少留 0.6s：收起瞬间不闪退
            toasts[index].frozenRemaining = max(0.6, toasts[index].deadline.timeIntervalSince(now))
        }
    }

    private func thawAll() {
        let now = Date()
        for index in toasts.indices {
            guard let remaining = toasts[index].frozenRemaining else { continue }
            toasts[index].deadline = now.addingTimeInterval(remaining)
            toasts[index].frozenRemaining = nil
            schedule(toasts[index].id, after: remaining)
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 语义轴（状态色 / 图标，卡片与气泡共用）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extension CCToastCenter.Kind {
    var statusColor: Color {
        switch self {
        case .info: .cc.info
        case .success: .cc.success
        case .warning: .cc.warning
        case .error: .cc.destructive
        case .loading: .cc.primary
        }
    }

    var iconName: String {
        switch self {
        case .info: "information-circle"
        case .success: "check-tick-single"
        case .warning: "alert-triangle"
        case .error: "alert-circle"
        case .loading: ""
        }
    }
}

private struct CCToastIconSlot: View {
    let kind: CCToastCenter.Kind

    var body: some View {
        if kind == .loading {
            ProgressView()
                .controlSize(.small)
                .tint(.cc.foreground)
        } else {
            PikaIcon(kind.iconName, size: 18, color: kind.statusColor)
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCToastView（Kumo 叠放编舞：几何在此算——index / 展开位移 / 前张尺寸对齐）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct CCToastView: View {
    @ObservedObject private var center = CCToastCenter.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// 各张实测本尺寸（身后张被压成前张尺寸时不回写——那是编舞给的，不是它的本尺寸）
    @State private var sizes: [UUID: CGSize] = [:]

    public init() {}

    /// index 0 = 最新最前
    private var stack: [CCToastCenter.Toast] {
        center.toasts.filter { $0.route == .capsule }.reversed()
    }

    public var body: some View {
        let stack = self.stack
        if !stack.isEmpty {
            ZStack(alignment: .top) {
                ForEach(Array(stack.enumerated()), id: \.element.id) { index, toast in
                    card(toast, index: index, stackCount: stack.count)
                }
            }
            .frame(maxWidth: 420)
            .frame(height: viewportHeight(stack), alignment: .top)
            .padding(.horizontal, 16)
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame in
                center.capsuleHitRect = frame
            }
            .onDisappear { center.capsuleHitRect = .null }
            .animation(reduceMotion ? nil : CCToastMotion.kumo, value: center.expanded)
            .accessibilityElement(children: .contain)
        }
    }

    // ━━━ 单张：叠态缩放上探 + 尺寸对齐前张，展开态累加位移 ━━━

    @ViewBuilder
    private func card(_ toast: CCToastCenter.Toast, index: Int, stackCount: Int) -> some View {
        let behind = index > 0 && !center.expanded
        let hidden = !center.expanded && index >= CCToastMotion.visibleLimit
        let front = frontSize()
        CCToastCard(toast: toast, contentFaded: behind) {
            center.close(toast.id)
        }
        .onGeometryChange(for: CGSize.self) { $0.size } action: { size in
            if !behind { sizes[toast.id] = size }
        }
        // 身后张与最前张同尺寸（Kumo --toast-frontmost-height）：缩放后边缘才齐，一叠才像一叠
        .frame(width: behind ? front.width : nil, height: behind ? front.height : nil)
        .scaleEffect(center.expanded ? 1 : max(0, 1 - CGFloat(index) * CCToastMotion.scaleStep), anchor: .top)
        .offset(y: offsetY(index: index, stack: stack))
        .opacity(hidden ? 0 : 1)
        .zIndex(Double(1000 - index))
        .allowsHitTesting(!hidden)
        .contentShape(Rectangle())
        .onTapGesture {
            // hover 的触屏等价物：点整叠展开 / 再点收起（单张无叠可展）
            guard stackCount > 1 else { return }
            withAnimation(reduceMotion ? nil : CCToastMotion.kumo) {
                center.expanded.toggle()
            }
        }
        .transition(
            reduceMotion
                ? .opacity
                : .offset(y: -(frontSize().height + 80)).combined(with: .opacity)
        )
    }

    /// 叠态上探 peek 并补回缩掉的高度（每层底边恰露一条边）；展开态按前面各张本高度加间距累加
    private func offsetY(index: Int, stack: [CCToastCenter.Toast]) -> CGFloat {
        guard index > 0 else { return 0 }
        if center.expanded {
            let heights = stack.prefix(index).map { sizes[$0.id]?.height ?? frontSize().height }
            return heights.reduce(0, +) + CGFloat(index) * CCToastMotion.peek
        }
        let front = frontSize().height
        return CGFloat(index) * (CCToastMotion.peek + front * CCToastMotion.scaleStep)
    }

    private func frontSize() -> CGSize {
        guard let id = stack.first?.id, let size = sizes[id] else { return CGSize(width: 320, height: 64) }
        return size
    }

    /// 视口高度：叠态 = 前张高 + 可见层上探；展开 = 全列累加（命中区要盖住整叠/整列）
    private func viewportHeight(_ stack: [CCToastCenter.Toast]) -> CGFloat {
        let front = frontSize().height
        if center.expanded {
            let heights = stack.map { sizes[$0.id]?.height ?? front }
            return heights.reduce(0, +) + CGFloat(max(0, stack.count - 1)) * CCToastMotion.peek
        }
        // 叠态第 i 层底边 = 前张高 + i×peek（缩放锚顶 + 补高位移的净效果），视口只到最深可见层
        let layers = min(stack.count - 1, CCToastMotion.visibleLimit - 1)
        return front + CGFloat(max(0, layers)) * CCToastMotion.peek
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCToastCard（Laper 卡样：横向渐变白卡 + 状态色圆徽 + 关闭钮进度环）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

private struct CCToastCard: View {
    let toast: CCToastCenter.Toast
    /// 身后张：卡壳保留，正文淡出（Laper .laper-toast-content）
    var contentFaded = false
    var onClose: () -> Void

    private var status: Color { toast.kind.statusColor }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            iconBadge
            Text(toast.message)
                .ccText(font: .cc.smBold, color: .cc.foreground)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            closeControl
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .opacity(contentFaded ? 0 : 1)
        .animation(.easeOut(duration: 0.25), value: contentFaded)
        .background {
            // Laper 卡底：background → muted → background 横向渐变 + 2px muted 边
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color.cc.background, location: 0),
                            .init(color: Color.cc.muted, location: 0.5),
                            .init(color: Color.cc.background, location: 1),
                        ],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.cc.muted, lineWidth: 2)
                }
                // 0 0 0 2px background 外圈光环
                .background {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.cc.background)
                        .padding(-2)
                }
                .shadow(color: .black.opacity(0.08), radius: 12, y: 8)
        }
    }

    /// 状态色圆徽：渐变描边圈 + 状态色淡渐变底 + 语义图标（Laper 三层圆配方）
    private var iconBadge: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [status.opacity(0.04), status.opacity(0.28)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [status.opacity(0.24), status.opacity(0.44)],
                        startPoint: .top, endPoint: .bottom
                    ),
                    lineWidth: 2
                )
            CCToastIconSlot(kind: toast.kind)
        }
        .frame(width: 40, height: 40)
        .background {
            // 外层 background 细圈（Laper 0 0 0 2px var(--background)）
            Circle().stroke(Color.cc.background, lineWidth: 2)
        }
    }

    /// 关闭钮 + SVG 进度环等价物：按 duration 转满；冻结时环与倒计时一同暂停；loading 无环
    private var closeControl: some View {
        ZStack {
            if toast.kind != .loading {
                TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { timeline in
                    Circle()
                        .trim(from: 0, to: fraction(at: timeline.date))
                        .stroke(status.opacity(0.5), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .padding(2)
                }
                .allowsHitTesting(false)
            }
            CCCloseIcon(status: status, faded: contentFaded)
        }
        .frame(width: 36, height: 36)
        .contentShape(Circle())
        .onTapGesture { onClose() }
    }

    private func fraction(at now: Date) -> CGFloat {
        let remaining = toast.frozenRemaining ?? max(0, toast.deadline.timeIntervalSince(now))
        return CGFloat(min(1, max(0, 1 - remaining / toast.duration)))
    }
}

/// 关闭钮图形：前景色 3.33s 渐变到状态色（Laper toast-icon-color 同构）
private struct CCCloseIcon: View {
    let status: Color
    let faded: Bool
    @State private var tinted = false

    var body: some View {
        PikaIcon(PikaIcon.Name.close, size: 13, color: tinted ? status : .cc.foreground)
            .animation(.easeOut(duration: 3.33), value: tinted)
            .onAppear { tinted = true }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCAqiBubbleToast（阿奇气泡：iMessage 式从头像左上方弹出，尖尾指头像）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct CCAqiBubbleToast: View {
    @ObservedObject private var center = CCToastCenter.shared

    public init() {}

    private var bubbleToast: (toast: CCToastCenter.Toast, anchor: CGRect)? {
        guard let toast = center.toasts.last(where: {
            if case .aqiBubble = $0.route { return true } else { return false }
        }), case .aqiBubble(let anchor) = toast.route else { return nil }
        return (toast, anchor)
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomTrailing) {
                if let (toast, anchor) = bubbleToast {
                    // 点击气泡外任意处即关（触摸由 CCToastWindow 在气泡态接管）
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { center.close(toast.id) }

                    bubble(for: toast)
                        // 气泡右缘压在头像左上角内侧，尖尾自然落在头像左上方
                        .padding(.trailing, max(12, geo.size.width - anchor.minX - 26))
                        .padding(.bottom, max(0, geo.size.height - anchor.minY + 4))
                        .transition(
                            .scale(scale: 0.1, anchor: .bottomTrailing)
                                .combined(with: .opacity)
                        )
                        .id(toast.id)   // 顶换时旧退新进
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
        .ignoresSafeArea()
    }

    /// 阿奇说的一句话：语义图标 + 正文字号消息 + X 关闭钮，卡片白底 + 尖尾
    private func bubble(for toast: CCToastCenter.Toast) -> some View {
        HStack(alignment: .center, spacing: 10) {
            CCToastIconSlot(kind: toast.kind)
            Text(toast.message)
                .ccText(font: .cc.base, color: .cc.foreground)
                .multilineTextAlignment(.leading)
                .lineLimit(4)
            closeButton(toast.id)
        }
        .padding(.leading, 14)
        .padding(.trailing, 8)
        .padding(.vertical, 10)
        .background(Color.cc.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.cc.border.opacity(0.8), lineWidth: CGFloat.cc.hairline)
        }
        .overlay(alignment: .bottomTrailing) {
            AqiBubbleTail()
                .fill(Color.cc.card)
                .frame(width: 16, height: 10)
                .offset(x: -10, y: 9)
        }
        .shadow(color: Color.cc.shadow.opacity(0.14), radius: 12, x: 0, y: 5)
        .frame(maxWidth: 300, alignment: .trailing)
    }

    private func closeButton(_ id: UUID) -> some View {
        Button {
            CCToastCenter.shared.close(id)
        } label: {
            PikaIcon(PikaIcon.Name.close, size: 13, color: .cc.mutedForeground)
                .frame(width: 28, height: 28)
                .background(Color.cc.muted, in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCKeyboardWatcher（键盘可见性单例：气泡路由判定 + 宿主常驻区让位共用）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

@MainActor
public final class CCKeyboardWatcher: ObservableObject {
    public static let shared = CCKeyboardWatcher()

    @Published public private(set) var isVisible = false
    private var cancellables: Set<AnyCancellable> = []

    private init() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .map { _ in true }
            .merge(with: NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
                .map { _ in false })
            .receive(on: RunLoop.main)
            .sink { [weak self] visible in self?.isVisible = visible }
            .store(in: &cancellables)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCToastWindow（置顶窗口：叠层命中区/气泡态接管触摸，其余全透传）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

@MainActor
public final class CCToastWindow {
    public static let shared = CCToastWindow()
    private var window: UIWindow?

    private init() {}

    public func attach(to scene: UIWindowScene) {
        guard window == nil else { return }
        let toastWindow = CCToastHitWindow(windowScene: scene)
        toastWindow.windowLevel = UIWindow.Level.alert + 1
        toastWindow.backgroundColor = .clear

        let hosting = UIHostingController(rootView: CCToastRoot())
        hosting.view.backgroundColor = .clear
        toastWindow.rootViewController = hosting
        toastWindow.isHidden = false
        window = toastWindow
        // 键盘观察必须随窗口启动即在岗：首次 toast 时才建单例会漏掉已弹出的键盘
        _ = CCKeyboardWatcher.shared
    }
}

/// 触摸策略窗口：气泡态整窗接管（点外即关）；叠层态只在叠层命中区内接管（关闭钮/展开），
/// 其余触摸全透传底层窗口——toast 永不挡住身后的应用
private final class CCToastHitWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let center = CCToastCenter.shared
        let hasBubble = center.toasts.contains {
            if case .aqiBubble = $0.route { return true } else { return false }
        }
        if hasBubble { return super.hitTest(point, with: event) }
        let rect = center.capsuleHitRect
        guard !rect.isNull, rect.contains(point) else { return nil }
        return super.hitTest(point, with: event)
    }
}

/// 窗口根视图：上传进度条与叠放 toast 纵向合流钉顶，气泡 toast 锚定 tabbar 阿奇头像
private struct CCToastRoot: View {
    var body: some View {
        ZStack {
            VStack(spacing: 8) {
                CCUploadToast()
                CCToastView()
                Spacer(minLength: 0)
            }
            .padding(.top, 6)
            .frame(maxWidth: .infinity)

            CCAqiBubbleToast()
        }
    }
}
