/**
 * [INPUT]: 依赖 UIKit 的 UIWindow / UIHostingController、Core/CCLog 的分类 logger
 * [OUTPUT]: 对外提供 TopCardPresenter.shared（presentCard / dismissCard / dismissAllCards）、DemoCardView、TopCardPreviewView
 * [POS]: Presentation 的屏幕中央卡片呈现窗：每张卡一个独立 UIWindow，叠成栈；拖动越过阈值或点卡片 / 背景即关
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI
import UIKit
import OSLog

/// 用于在顶级窗口展示SwiftUI视图卡片的控制器
public final class TopCardPresenter : NSObject{
    
    // MARK: - 单例实例
    
    /// 共享实例
    public static let shared = TopCardPresenter()
    
    // MARK: - 私有属性
    
    /// 卡片数据模型，存储每个卡片的相关数据
    private struct CardData {
        let window: UIWindow
        let viewController: UIViewController
        let backgroundView: UIView
        let cardView: UIView
        let initialCenter: CGPoint
        var isTopmost: Bool // 是否是最顶层卡片
    }
    
    /// 卡片堆栈
    private var cards: [CardData] = []
    
    // 日志记录器（经 Core/CCLog）
    private let logger = CCLog.logger("TopCardPresenter")
    
    // MARK: - 初始化方法
    
    private override init() {}
    
    // MARK: - 公共方法
    
    /// 在独立窗口中央展示 SwiftUI 卡片；isUserInteractionEnabled 为 true 时点背景即关
    @MainActor
    public func presentCard<Content: View>(
        view: Content,
        animated: Bool = true,
        backgroundColor: UIColor = UIColor.black.withAlphaComponent(0.5),
        isUserInteractionEnabled: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        logger.debug("Presenting card, current count: \(self.cards.count)")
        
        // 将之前的所有卡片标记为非顶层
        for i in 0..<cards.count {
            var cardData = cards[i]
            cardData.isTopmost = false
            cards[i] = cardData
        }
        
        let hostingController = UIHostingController(rootView: view)
        hostingController.view.backgroundColor = .clear
        logger.debug("HostingController created")
        
        // 创建背景视图
        let bgView = UIView()
        bgView.backgroundColor = backgroundColor
        bgView.alpha = 0.3
        logger.debug("Background view created, color: \(backgroundColor)")
        
        if isUserInteractionEnabled {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
            bgView.addGestureRecognizer(tapGesture)
            logger.debug("Background tap gesture added")
        }
        
        // 获取当前活跃的场景和窗口
        guard let windowScene = UIApplication.shared.connectedScenes
                .filter({ $0.activationState == .foregroundActive })
                .first as? UIWindowScene else {
            logger.error("No active UIWindowScene")
            return
        }
        
        logger.debug("Active WindowScene: \(windowScene)")
        
        // 创建新窗口，使用当前活跃的windowScene
        let window = UIWindow(windowScene: windowScene)
        window.windowLevel = .alert + 100 + CGFloat(cards.count) // 每个新卡片增加层级
        window.backgroundColor = .clear
        logger.debug("Window created, windowLevel: \(window.windowLevel.rawValue)")
        
        let containerVC = UIViewController()
        containerVC.view.backgroundColor = .clear
        window.rootViewController = containerVC
        logger.debug("Container controller set")
        
        // 添加背景视图和卡片视图
        containerVC.view.addSubview(bgView)
        containerVC.addChild(hostingController)
        containerVC.view.addSubview(hostingController.view)
        hostingController.didMove(toParent: containerVC)
        logger.debug("Subview and child controller added")
        
        // 配置布局
        bgView.frame = containerVC.view.bounds
        
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.centerXAnchor.constraint(equalTo: containerVC.view.centerXAnchor),
            hostingController.view.centerYAnchor.constraint(equalTo: containerVC.view.centerYAnchor),
            hostingController.view.widthAnchor.constraint(lessThanOrEqualTo: containerVC.view.widthAnchor, multiplier: 0.9),
            hostingController.view.heightAnchor.constraint(lessThanOrEqualTo: containerVC.view.heightAnchor, multiplier: 0.9)
        ])
        logger.debug("Constraints set")
        
        // 添加手势识别器到卡片视图
        addGesturesToCardView(hostingController.view)
        
        // 添加到卡片堆栈
        let initialCenter = CGPoint(
            x: containerVC.view.bounds.midX,
            y: containerVC.view.bounds.midY
        )
        
        let cardData = CardData(
            window: window, 
            viewController: hostingController,
            backgroundView: bgView,
            cardView: hostingController.view,
            initialCenter: initialCenter,
            isTopmost: true
        )
        cards.append(cardData)
        logger.debug("Card pushed to stack, current count: \(self.cards.count)")
        
        // 显示窗口
        window.isHidden = false
        window.makeKeyAndVisible()
        logger.debug("Window made visible: isHidden=\(window.isHidden), isKeyWindow=\(window.isKeyWindow)")
        
        // 应用动画
        if animated {
            hostingController.view.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            hostingController.view.alpha = 0
            
            logger.debug("Starting present animation")
            UIView.animate(
                withDuration: 0.25,
                delay: 0,
                usingSpringWithDamping: 0.7,
                initialSpringVelocity: 0.3,
                options: .curveEaseOut,
                animations: {
                    bgView.alpha = 1
                    hostingController.view.alpha = 1
                    hostingController.view.transform = CGAffineTransform(scaleX: 1.05, y: 1.05) // 过量变化
                    self.logger.debug("Present animation - phase 1")
                },
                completion: { _ in
                    UIView.animate(withDuration: 0.15, animations: {
                        hostingController.view.transform = .identity // 恢复正常大小
                        self.logger.debug("Present animation - phase 2")
                    }, completion: { _ in
                        self.logger.debug("Present animation finished")
                        completion?()
                    })
                }
            )
        } else {
            bgView.alpha = 1
            logger.debug("Presenting without animation")
            completion?()
        }
    }
    
    /// 关闭最顶层卡片；栈空时直接回调 completion
    @MainActor
    public func dismissCard(animated: Bool = true, completion: (() -> Void)? = nil) {
        guard !cards.isEmpty else {
            logger.warning("No presented card found, it may already be dismissed")
            completion?()
            return
        }
        
        dismissCard(at: cards.count - 1, animated: animated, completion: completion)
    }
    
    /// 关闭指定索引的卡片；索引无效时只记日志并回调 completion
    @MainActor
    public func dismissCard(at index: Int, animated: Bool = true, completion: (() -> Void)? = nil) {
        logger.debug("Dismissing card at index \(index)")
        
        guard index >= 0 && index < cards.count else {
            logger.warning("Invalid card index: \(index)")
            completion?()
            return
        }
        
        let cardData = cards[index]
        
        if animated {
            logger.debug("Starting dismiss animation")
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseIn, animations: {
                cardData.backgroundView.alpha = 0
                cardData.cardView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                cardData.cardView.alpha = 0
                self.logger.debug("Dismiss animation running")
            }, completion: { _ in
                self.logger.debug("Dismiss animation finished")
                self.cleanupCard(at: index)
                
                // 如果还有卡片，将最上层的卡片标记为顶层
                if !self.cards.isEmpty {
                    var topCardData = self.cards[self.cards.count - 1]
                    topCardData.isTopmost = true
                    self.cards[self.cards.count - 1] = topCardData
                }
                
                completion?()
            })
        } else {
            logger.debug("Dismissing without animation")
            cleanupCard(at: index)
            
            // 如果还有卡片，将最上层的卡片标记为顶层
            if !cards.isEmpty {
                var topCardData = cards[cards.count - 1]
                topCardData.isTopmost = true
                cards[cards.count - 1] = topCardData
            }
            
            completion?()
        }
    }
    
    /// 关闭全部卡片，全部关完再回调 completion
    @MainActor
    public func dismissAllCards(animated: Bool = true, completion: (() -> Void)? = nil) {
        guard !cards.isEmpty else {
            logger.warning("No card to dismiss")
            completion?()
            return
        }
        
        let group = DispatchGroup()
        
        // 从后往前关闭每个卡片
        for i in (0..<cards.count).reversed() {
            group.enter()
            dismissCard(at: i, animated: animated) {
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.logger.debug("All cards dismissed")
            completion?()
        }
    }
    
    // MARK: - 私有方法
    
    /// 添加手势到卡片视图
    private func addGesturesToCardView(_ view: UIView) {
        // 添加拖动手势
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        panGesture.delaysTouchesBegan = false
        panGesture.delaysTouchesEnded = false
        view.addGestureRecognizer(panGesture)
        
        // 添加点击手势（点击卡片内部但不触发其他交互时关闭）
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cardTapped(_:)))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
        
        logger.debug("Pan and tap gestures added to card view")
    }
    
    @objc @MainActor private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        // 只有顶层卡片响应手势
        guard let cardView = gesture.view,
              let cardIndex = getCardIndex(for: cardView),
              cards[cardIndex].isTopmost else {
            return
        }
        
        let cardData = cards[cardIndex]
        let translation = gesture.translation(in: cardView.superview)
        let velocity = gesture.velocity(in: cardView.superview)
        
        switch gesture.state {
        case .began:
            // 记录开始拖动
            logger.debug("Card drag began, index: \(cardIndex)")
            // 重置手势的初始平移量，确保每次新的拖动从零开始计算
            gesture.setTranslation(.zero, in: cardView.superview)
            
        case .changed:
            // 允许向下拖动，不限制距离
            if translation.y > 0 {
                // 设置卡片位置，只跟随Y轴移动
                cardView.center = CGPoint(
                    x: cardData.initialCenter.x,
                    y: cardData.initialCenter.y + translation.y
                )
                
                // 随着拖动距离增加，计算透明度和缩放比例
                let screenHeight = UIScreen.cc_active.bounds.height
                let dragPercentage = min(translation.y / (screenHeight / 4), 1.0)
                
                // 减小背景视图透明度
                cardData.backgroundView.alpha = 1.0 - dragPercentage * 0.7
                
                // 轻微缩小
                let scale = max(1.0 - dragPercentage * 0.1, 0.9)
                cardView.transform = CGAffineTransform(scaleX: scale, y: scale)
            }
            
        case .ended, .cancelled:
            // 仅在松手时判断是否满足关闭条件
            let dismissThreshold = cardView.frame.height * 0.3
            
            if velocity.y > 300 || translation.y > dismissThreshold {
                // 满足关闭条件，淡出消失
                UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut, .beginFromCurrentState], animations: {
                    // 不改变位置和transform，只改变透明度
                    cardView.alpha = 0
                    cardData.backgroundView.alpha = 0
                }, completion: { _ in
                    self.dismissCard(at: cardIndex, animated: false)
                })
                logger.debug("Drag ended past threshold, fading card out")
            } else {
                // 否则，恢复卡片位置
                UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0.2, options: .curveEaseOut, animations: {
                    cardView.center = cardData.initialCenter
                    cardView.transform = .identity
                    cardData.backgroundView.alpha = 1.0
                }, completion: nil)
                logger.debug("Drag ended below threshold, restoring card position")
            }
            
        default:
            break
        }
    }
    
    @objc @MainActor private func cardTapped(_ gesture: UITapGestureRecognizer) {
        // 只有顶层卡片响应手势
        guard let cardView = gesture.view,
              let cardIndex = getCardIndex(for: cardView),
              cards[cardIndex].isTopmost,
              gesture.state == .ended else {
            return
        }

        logger.debug("Card tapped, dismissing")
        dismissCard(at: cardIndex)
    }
    
    @objc @MainActor private func backgroundTapped() {
        // 只关闭最顶层的卡片
        guard !cards.isEmpty else { return }
        
        logger.debug("Background tapped, dismissing card")
        dismissCard()
    }
    
    private func cleanupCard(at index: Int) {
        guard index >= 0 && index < cards.count else {
            logger.warning("Cleanup skipped, invalid card index: \(index)")
            return
        }
        
        logger.debug("Cleaning up card at index \(index)")
        
        let cardData = cards[index]
        
        if let hostingController = cardData.viewController as? UIHostingController<AnyView> {
            hostingController.view.removeFromSuperview()
            hostingController.removeFromParent()
        } else {
            cardData.viewController.view.removeFromSuperview()
            cardData.viewController.removeFromParent()
        }
        logger.debug("Card controller removed")
        
        cardData.backgroundView.removeFromSuperview()
        cardData.window.isHidden = true
        logger.debug("Window hidden, background view removed")
        
        // 从数组中移除卡片数据
        cards.remove(at: index)
    }
    
    private func getCardIndex(for view: UIView) -> Int? {
        return cards.firstIndex { $0.cardView === view }
    }
    
    private func printWindowsInfo() {
        logger.debug("Dumping all windows:")
        UIApplication.shared.connectedScenes.forEach { scene in
            if let windowScene = scene as? UIWindowScene {
                logger.debug("Scene: \(windowScene), activationState: \(windowScene.activationState.rawValue)")
                windowScene.windows.forEach { window in
                    logger.debug("Window: \(window), level: \(window.windowLevel.rawValue), visible: \(window.isHidden ? "no" : "yes"), isKey: \(window.isKeyWindow ? "yes" : "no")")
                }
            }
        }
    }
}

// MARK: - UIGestureRecognizerDelegate
extension TopCardPresenter: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // 对于卡片上的点击手势，只有当用户点击的是卡片本身而不是其内部控件时才允许响应
        if let tapGesture = gestureRecognizer as? UITapGestureRecognizer,
           let cardView = tapGesture.view,
           let cardIndex = getCardIndex(for: cardView) {
            return touch.view === cardView && cards[cardIndex].isTopmost
        }
        return false
    }
}

// MARK: - 预览
#if DEBUG

public struct DemoCardView: View {
    var onClose: () -> Void
    
    public var body: some View {
        VStack(spacing: 20) {
            Text("这是一个演示卡片")
                .ccText(font: .cc.body , color: .cc.foreground)
                .padding(.top)
            
            Text("这个卡片将在屏幕中央展示，并且会在顶级窗口上")
                .multilineTextAlignment(.center)
                .ccText(font: .cc.callout , color: .cc.mutedForeground)
                .padding(.horizontal)
            
            CCDesigin.CCButton {
                onClose()
            } label: {
                Text("关闭卡片")
            }
            .padding(.bottom)
        }
        .frame(width: 300)
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 10)
    }
}

public struct TopCardPreviewView: View {
    @State private var showCard = false
    
    public var body: some View {
        VStack(spacing: 20) {
            Text("顶级卡片演示")
                .font(.title)
                .padding(.top)
            
            Button("显示卡片") {
                Task { @MainActor in
                    showCard = true
                    TopCardPresenter.shared.presentCard(
                        view: DemoCardView(onClose: {
                            Task { @MainActor in
                                TopCardPresenter.shared.dismissCard()
                            }
                        })
                    )
                }
            }
            .buttonStyle(.borderedProminent)
            
            Button("显示多个卡片") {
                Task { @MainActor in
                    showCard = true
                    TopCardPresenter.shared.presentCard(
                        view: DemoCardView(onClose: {
                            Task { @MainActor in
                                TopCardPresenter.shared.dismissCard()
                            }
                        })
                    )
                    
                    // 延迟显示第二个卡片
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        TopCardPresenter.shared.presentCard(
                            view: DemoCardView(onClose: {
                                Task { @MainActor in
                                    TopCardPresenter.shared.dismissCard()
                                }
                            })
                        )
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            
            Button("关闭所有卡片") {
                Task { @MainActor in
                    TopCardPresenter.shared.dismissAllCards()
                }
            }
            .buttonStyle(.bordered)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview {
    TopCardPreviewView()
}

#endif 
