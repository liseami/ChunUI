/**
 * [INPUT]: 依赖 QuartzCore 的 CADisplayLink、Core/CCComponentText（演示面板文案）
 * [OUTPUT]: 对外提供 DisplayLinkManager（全局帧订阅）、DisplayLinkViewModifier / DisplayLinkView（按屏幕最高刷新率重绘）、RefreshRateMonitor（帧率读数）、DisplayLinkViewExample（演示）
 * [POS]: Components 的帧同步原子；一个 CADisplayLink 服务全部订阅者
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */
 
import QuartzCore

// DisplayLinkManager - 管理CADisplayLink的单例类
public class DisplayLinkManager {
    static let shared = DisplayLinkManager()
    
    private var displayLink: CADisplayLink?
    private var subscribers: [UUID: () -> Void] = [:]
    
    private init() {
        setupDisplayLink()
    }
    
    private func setupDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink?.preferredFramesPerSecond = 120 // 请求120Hz刷新率（如果设备支持）
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @objc private func update() {
        // 通知所有订阅者
        for callback in subscribers.values {
            callback()
        }
    }
    
    // 添加订阅者
    func subscribe(id: UUID, callback: @escaping () -> Void) -> Void {
        subscribers[id] = callback
    }
    
    // 移除订阅者
    func unsubscribe(id: UUID) {
        subscribers.removeValue(forKey: id)
    }
    
    // 获取当前实际刷新率
    var actualFramesPerSecond: Int {
        return displayLink?.preferredFramesPerSecond ?? 60
    }
    
    // 获取设备支持的最大刷新率
    var maximumFramesPerSecond: Int {
        return Int(displayLink?.preferredFrameRateRange.maximum ?? 60)
    }
    
    deinit {
        displayLink?.invalidate()
    }
}

// DisplayLinkViewModifier - 使任何视图以高刷新率渲染
public struct DisplayLinkViewModifier: ViewModifier {
    @State private var id = UUID()
    @State private var counter: Int = 0
    
    public func body(content: Content) -> some View {
        content
            .onAppear {
                // 订阅DisplayLink更新
                DisplayLinkManager.shared.subscribe(id: id) {
                    // 增加计数器以触发SwiftUI重绘
                    counter += 1
                }
            }
            .onDisappear {
                // 取消订阅
                DisplayLinkManager.shared.unsubscribe(id: id)
            }
            .id(counter) // 使用计数器强制SwiftUI重绘
    }
}

// DisplayLinkView - 包装任何内容的高刷新率视图
public struct DisplayLinkView<Content: View>: View {
    let content: Content
    
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    public var body: some View {
        content
            .modifier(DisplayLinkViewModifier())
    }
}

// 扩展View以添加高刷新率功能
extension View {
    func highRefreshRate() -> some View {
        self.modifier(DisplayLinkViewModifier())
    }
}

// 用于显示当前刷新率的辅助视图
public struct RefreshRateMonitor: View {
    @State private var fps: Double = 0
    @State private var maxFps: Int = 0
    @State private var id = UUID()
    @State private var updateCounter = 0
    
    public var body: some View {
        VStack {
            Text(CCComponentText.f("demo.refreshRate.current", Int(fps)))
                .ccText(font: .cc.caption, color: .cc.background)
            Text(CCComponentText.f("demo.refreshRate.max", maxFps))
                .ccText(font: .cc.caption, color: .cc.background)
        }
        .padding(8)
        .background(Color.cc.foreground.opacity(0.7))
        .cornerRadius(8)
        .onAppear {
            // 每秒更新一次FPS显示
            let timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                fps = Double(DisplayLinkManager.shared.actualFramesPerSecond)
                maxFps = DisplayLinkManager.shared.maximumFramesPerSecond
            }
            timer.fire()
            
            // 确保视图本身以高刷新率更新
            DisplayLinkManager.shared.subscribe(id: id) {
                updateCounter += 1
            }
        }
        .onDisappear {
            DisplayLinkManager.shared.unsubscribe(id: id)
        }
        .id(updateCounter)
    }
}

// 示例用法
public struct DisplayLinkViewExample: View {
    public var body: some View {
        ZStack {
            // 主内容
            VStack {
                Text(CCComponentText.t("demo.refreshRate.content"))
                    .ccText(font: .cc.title1Bold, color: .cc.foreground)
                
                // 一些动画内容
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [Color.cc.info, Color.cc.primary]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 200, height: 200)
                    .rotation3DEffect(
                        .degrees(Double(Date().timeIntervalSince1970).truncatingRemainder(dividingBy: 360)),
                        axis: (x: 0, y: 1, z: 0)
                    )
            }
            
            // 刷新率监视器
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    RefreshRateMonitor()
                        .padding()
                }
            }
        }
        .highRefreshRate() // 应用高刷新率修饰符
    }
}

// 预览
public struct DisplayLinkView_Previews: PreviewProvider {
    public static var previews: some View {
        DisplayLinkViewExample()
    }
}
