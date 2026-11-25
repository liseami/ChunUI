/**
 * [INPUT]: URL (String 或 URL 类型)、CCDesigin.GlassIconButton、PikaIcon.Name.close、Presentation 的 CCNav.present（分享面板呈现出口）
 * [OUTPUT]: 应用内浏览器视图（顶栏左上 regular 大玻璃关闭，顶缘忽略安全区）；CCWebView + WebViewState 亦可被宿主单独内嵌
 * [POS]: DesignSystem/Compents - 通用 WebView 封装；底栏工具条圆角矩形（禁胶囊）
 *
 * [PROTOCOL]:
 * 1. 使用 Combine 订阅 WKWebView 的 estimatedProgress
 * 2. 进度条使用设计系统主色 Color.cc.primary
 * 3. 单一真相源：所有状态由 WebViewCoordinator 统一管理
 * 变更时更新此头部，然后检查 CLAUDE.md
 */

import Combine
import SwiftUI
import WebKit

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - InAppBrowser
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct InAppBrowser: View {
    let url: URL
    @StateObject private var state = WebViewState()

    // ━━━ 初始化 ━━━
    public init(url: URL) {
        self.url = url
    }

    public init(url: String) {
        guard let parsed = URL(string: url) ?? URL(string: "about:blank") else {
            preconditionFailure("Failed to construct fallback about:blank URL")
        }
        self.url = parsed
    }

    public var body: some View {
        VStack(spacing: 0) {
            browserHeader

            ZStack(alignment: .bottom) {
                CCWebView(url: url, state: state)
                    .ignoresSafeArea(edges: .bottom)

                browserFooter
            }
        }
        // 背景铺满含状态栏；顶栏布局仍吃安全区，关闭钮不额外再 inset 一层
        .background(Color.cc.background.ignoresSafeArea())
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 顶部导航栏（左上 regular 大玻璃关闭）
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var browserHeader: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                CCDesigin.GlassIconButton(icon: PikaIcon.Name.close) {
                    AppHelper.shared.mada(.soft)
                    AppHelper.shared.dismissSheet()
                }

                if state.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.8)
                }

                Text(state.title.isEmpty ? CCStrings.current.loading : state.title)
                    .ccText(font: .cc.callout, color: .cc.foreground)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 12)

            // ━━━ 进度条 ━━━
            GeometryReader { geo in
                Rectangle()
                    .fill(Color.cc.primary)
                    .frame(width: geo.size.width * state.progress)
                    .animation(.easeInOut(duration: 0.2), value: state.progress)
            }
            .frame(height: state.isLoading ? 2 : 0)
            .opacity(state.isLoading ? 1 : 0)
            .animation(.easeInOut(duration: 0.3), value: state.isLoading)
        }
        .background(Color.cc.background)
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 底部工具栏
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var browserFooter: some View {
        HStack(spacing: 0) {
            toolbarButton(icon: "chevron.left", enabled: state.canGoBack) {
                state.webView?.goBack()
            }
            toolbarDivider
            toolbarButton(icon: "chevron.right", enabled: state.canGoForward) {
                state.webView?.goForward()
            }
            toolbarDivider
            toolbarButton(icon: "arrow.clockwise", enabled: true) {
                state.webView?.reload()
            }
            toolbarDivider
            toolbarButton(icon: "square.and.arrow.up", enabled: true) {
                shareURL()
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .modifier(GlassToolbarModifier())
        .padding(.horizontal, 60)
        .padding(.bottom, 24)
    }

    private func toolbarButton(icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            guard enabled else { return }
            action()
            AppHelper.shared.mada(.soft)
        } label: {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(enabled ? Color.cc.foreground : Color.cc.mutedForeground.opacity(0.5))
                .frame(width: 44, height: 36)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var toolbarDivider: some View {
        Rectangle()
            .fill(Color.cc.mutedForeground.opacity(0.15))
            .frame(width: 1, height: 16)
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 分享
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private func shareURL() {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)

        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }

        if let presented = root.presentedViewController {
            presented.dismiss(animated: true) { CCNav.present(activityVC, from: root, animated: true) }
        } else {
            CCNav.present(activityVC, from: root, animated: true)
        }

        AppHelper.shared.mada(.soft)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - WebView 状态容器
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public final class WebViewState: ObservableObject {
    @Published public internal(set) var title: String = ""
    @Published public internal(set) var progress: Double = 0
    @Published public internal(set) var isLoading: Bool = true
    @Published public internal(set) var canGoBack: Bool = false
    @Published public internal(set) var canGoForward: Bool = false

    weak var webView: WKWebView?
    var cancellables = Set<AnyCancellable>()

    public init() {}

    /// 宿主内嵌时的重载入口（如应用重新发布后刷新）
    public func reload() { webView?.reload() }

    /// 绑定 WKWebView 的 KVO 属性
    func bind(to webView: WKWebView) {
        self.webView = webView

        // ━━━ 进度 ━━━
        webView.publisher(for: \.estimatedProgress)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.progress = value
                self?.isLoading = value < 1.0
            }
            .store(in: &cancellables)

        // ━━━ 标题 ━━━
        webView.publisher(for: \.title)
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .assign(to: &$title)

        // ━━━ 导航状态 ━━━
        webView.publisher(for: \.canGoBack)
            .receive(on: DispatchQueue.main)
            .assign(to: &$canGoBack)

        webView.publisher(for: \.canGoForward)
            .receive(on: DispatchQueue.main)
            .assign(to: &$canGoForward)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCWebView (UIViewRepresentable)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct CCWebView: UIViewRepresentable {
    let url: URL
    @ObservedObject var state: WebViewState

    /// 宿主可直接内嵌（不带 InAppBrowser 的顶栏与工具条）；state 由宿主持有以读进度、触发重载
    public init(url: URL, state: WebViewState) {
        self.url = url
        self.state = state
    }

    public func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        context.coordinator.url = url

        // 绑定状态
        state.bind(to: webView)

        // 加载请求
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
        webView.load(request)

        return webView
    }

    public func updateUIView(_ webView: WKWebView, context: Context) {}

    public func makeCoordinator() -> Coordinator { Coordinator() }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Coordinator (WKNavigationDelegate)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    public class Coordinator: NSObject, WKNavigationDelegate {
        var url: URL?

        /// 页面加载失败
        public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            handleError(error, webView: webView)
        }

        /// 页面开始加载失败（DNS/连接错误等）
        public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            handleError(error, webView: webView)
        }

        /// WebContent 进程被系统终止（白屏恢复关键）
        public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            // 进程被杀，重新加载
            if let url = url {
                let request = URLRequest(url: url)
                webView.load(request)
            } else {
                webView.reload()
            }
        }

        private func handleError(_ error: Error, webView: WKWebView) {
            let nsError = error as NSError

            // 忽略取消请求的错误
            guard nsError.code != NSURLErrorCancelled else { return }

            // 其他错误可以 toast 提示
            AppHelper.shared.pushNotification(
                type: .error(message: CCStrings.current.pageLoadFailed)
            )
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 玻璃圆角矩形工具条
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

private struct GlassToolbarModifier: ViewModifier {
    func body(content: Content) -> some View {
        let shape = RoundedRectangle.ccButton(height: 48)
        if #available(iOS 26, *) {
            content
                .contentShape(shape)
                .containerShape(shape)
                .glassEffect(.regular.interactive())
        } else {
            content
                .background {
                    shape
                        .fill(.ultraThinMaterial)
                        .shadow(color: .cc.shadow.opacity(0.08), radius: 12, x: 0, y: 4)
                        .shadow(color: .cc.shadow.opacity(0.04), radius: 2, x: 0, y: 1)
                }
                .overlay {
                    shape.stroke(Color.cc.border, lineWidth: 0.5)
                }
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Preview
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

#Preview {
    InAppBrowser(url: "https://www.apple.com")
}
