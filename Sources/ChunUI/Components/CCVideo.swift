//
//  CCVideo.swift
//  Chat0IM
//

/**
 * [INPUT]: 依赖 AVKit/AVFoundation（AVAssetImageGenerator 取帧、AVPlayer 播放）、UIKit（锚点转场源 UIImageView + 全屏查看器）、Color.cc 设计令牌与 Presentation 的 CCNav.present（查看器呈现出口）
 * [OUTPUT]: 对外提供 CCVideoThumb（真实 UIImageView 首帧缩略 + 播放角标，点按锚点缩放打开）与 CCVideoViewerController（图片查看器同款手感：Laper 曲线锚点放大 + 跟手拖拽关闭回落锚点）
 * [POS]: DesignSystem/Compents 的视频呈现唯一系统——媒体数组图视频混存（.mp4/.mov 扩展名区分），与 Lantern 图片查看器同一转场语言；playable=false 时关闭 UIView 命中，把点击还给外层编辑选择
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import AVFoundation
import AVKit
import SwiftUI
import UIKit

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 首帧缓存（URL → UIImage，进程内）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

@MainActor
public final class VideoThumbCache {
    static let shared = VideoThumbCache()
    private var cache: [String: UIImage] = [:]

    func image(for key: String) -> UIImage? { cache[key] }

    func store(_ image: UIImage, for key: String) {
        cache[key] = image
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCVideoThumb（UIViewRepresentable：真实 UIImageView 作转场锚点）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct CCVideoThumb: UIViewRepresentable {
    let url: URL
    var cornerRadius: CGFloat = 0
    /// false 时只展示不可点播（编辑选择模式等外层接管点击）
    var playable = true

    public init(urlString: String, cornerRadius: CGFloat = 0, playable: Bool = true) {
        self.url = URL(string: urlString) ?? URL(fileURLWithPath: urlString)
        self.cornerRadius = cornerRadius
        self.playable = playable
    }

    public init(fileURL: URL, cornerRadius: CGFloat = 0, playable: Bool = true) {
        self.url = fileURL
        self.cornerRadius = cornerRadius
        self.playable = playable
    }

    public func makeUIView(context: Context) -> VideoThumbView {
        let view = VideoThumbView()
        view.clipsToBounds = true
        view.layer.cornerRadius = cornerRadius
        view.layer.cornerCurve = .continuous
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.setContentHuggingPriority(.defaultLow, for: .vertical)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return view
    }

    public func updateUIView(_ view: VideoThumbView, context: Context) {
        view.layer.cornerRadius = cornerRadius
        view.playable = playable
        view.isUserInteractionEnabled = playable
        view.configure(url: url)
    }

    public func sizeThatFits(_ proposal: ProposedViewSize, uiView: VideoThumbView, context: Context) -> CGSize? {
        nil
    }
}

/// 缩略本体：首帧 UIImageView（转场锚点）+ 播放角标 + 点按打开查看器
public final class VideoThumbView: UIView {
    private let imageView = UIImageView()
    private let badge = UIVisualEffectView(effect: nil)
    private let playIcon = UIImageView(image: UIImage(systemName: "play.fill"))
    private var currentURL: URL?
    var playable = true

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(Color.cc.muted)

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.frame = bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(imageView)

        badge.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
        badge.layer.cornerRadius = 18
        badge.clipsToBounds = true
        badge.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        addSubview(badge)

        playIcon.tintColor = .white
        playIcon.contentMode = .scaleAspectFit
        playIcon.frame = CGRect(x: 10, y: 10, width: 16, height: 16)
        badge.contentView.addSubview(playIcon)

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    public override func layoutSubviews() {
        super.layoutSubviews()
        badge.center = CGPoint(x: bounds.midX, y: bounds.midY)
    }

    func configure(url: URL) {
        guard currentURL != url else { return }
        currentURL = url
        imageView.image = nil
        let key = url.absoluteString
        if let cached = VideoThumbCache.shared.image(for: key) {
            imageView.image = cached
            return
        }
        Task { @MainActor in
            let generator = AVAssetImageGenerator(asset: AVURLAsset(url: url))
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = CGSize(width: 720, height: 720)
            guard let cgImage = try? await generator.image(at: .init(seconds: 0.1, preferredTimescale: 600)).image,
                  self.currentURL == url
            else { return }
            let image = UIImage(cgImage: cgImage)
            VideoThumbCache.shared.store(image, for: key)
            self.imageView.image = image
        }
    }

    @objc private func handleTap() {
        guard playable, let url = currentURL else { return }
        CCVideoViewerController.present(from: imageView, url: url)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCVideoViewerController（锚点缩放打开 + 跟手拖拽关闭，图片查看器同款手感）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public final class CCVideoViewerController: UIViewController {
    private let url: URL
    private weak var sourceView: UIImageView?
    private let anchorFrame: CGRect
    private let anchorRadius: CGFloat
    private let thumbnail: UIImage?

    private let dimming = UIView()
    private let container = UIView()
    private let thumbView = UIImageView()
    private var player: AVPlayer?
    private var playerView = UIView()
    private let closeButton = UIButton(type: .system)

    // MARK: 入口

    @MainActor
    static func present(from sourceView: UIImageView, url: URL) {
        guard let window = sourceView.window else { return }
        var top: UIViewController? = window.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        guard let top else { return }
        let anchor = sourceView.convert(sourceView.bounds, to: window)
        let radius = (sourceView.superview as? VideoThumbView)?.layer.cornerRadius ?? sourceView.layer.cornerRadius
        let viewer = CCVideoViewerController(
            url: url,
            sourceView: sourceView,
            anchorFrame: anchor,
            anchorRadius: radius,
            thumbnail: sourceView.image
        )
        viewer.modalPresentationStyle = .overFullScreen
        CCNav.present(viewer, from: top, animated: false)
    }

    private init(url: URL, sourceView: UIImageView, anchorFrame: CGRect, anchorRadius: CGFloat, thumbnail: UIImage?) {
        self.url = url
        self.sourceView = sourceView
        self.anchorFrame = anchorFrame
        self.anchorRadius = anchorRadius
        self.thumbnail = thumbnail
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    // MARK: 布局

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        dimming.backgroundColor = .black
        dimming.alpha = 0
        dimming.frame = view.bounds
        dimming.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(dimming)

        container.frame = anchorFrame
        container.layer.cornerRadius = anchorRadius
        container.layer.cornerCurve = .continuous
        container.clipsToBounds = true
        view.addSubview(container)

        thumbView.image = thumbnail
        thumbView.contentMode = .scaleAspectFill
        thumbView.frame = container.bounds
        thumbView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        container.addSubview(thumbView)

        closeButton.setImage(UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)), for: .normal)
        closeButton.tintColor = .white
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        closeButton.layer.cornerRadius = 20
        closeButton.frame = CGRect(x: 18, y: view.safeAreaInsets.top + 8, width: 40, height: 40)
        closeButton.alpha = 0
        closeButton.addTarget(self, action: #selector(dismissToAnchor), for: .touchUpInside)
        view.addSubview(closeButton)

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        view.addGestureRecognizer(pan)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard player == nil else { return }
        openAnimation()
    }

    public override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        closeButton.frame.origin.y = view.safeAreaInsets.top + 8
    }

    /// 终点矩形：按缩略图长宽比 aspect-fit 满屏内接
    private var fitFrame: CGRect {
        let bounds = view.bounds
        guard let size = thumbnail?.size, size.width > 0, size.height > 0 else { return bounds }
        let scale = min(bounds.width / size.width, bounds.height / size.height)
        let w = size.width * scale
        let h = size.height * scale
        return CGRect(x: (bounds.width - w) / 2, y: (bounds.height - h) / 2, width: w, height: h)
    }

    /// Laper drawer 曲线：与图片查看器同款 cubic-bezier(0.32, 0.72, 0, 1)
    private func makeAnimator(duration: TimeInterval, animations: @escaping () -> Void) -> UIViewPropertyAnimator {
        UIViewPropertyAnimator(
            duration: duration,
            controlPoint1: CGPoint(x: 0.32, y: 0.72),
            controlPoint2: CGPoint(x: 0, y: 1),
            animations: animations
        )
    }

    // MARK: 开场：锚点 → 内接满屏，随后起播

    private func openAnimation() {
        sourceView?.isHidden = true
        let animator = makeAnimator(duration: 0.38) {
            self.dimming.alpha = 1
            self.container.frame = self.fitFrame
            self.container.layer.cornerRadius = 0
        }
        animator.addCompletion { _ in
            self.startPlayback()
            UIView.animate(withDuration: 0.2) { self.closeButton.alpha = 1 }
        }
        animator.startAnimation()
    }

    private func startPlayback() {
        let avPlayer = AVPlayer(url: url)
        player = avPlayer
        let layer = AVPlayerLayer(player: avPlayer)
        layer.videoGravity = .resizeAspect
        playerView = UIView(frame: container.bounds)
        playerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        layer.frame = playerView.bounds
        playerView.layer.addSublayer(layer)
        container.addSubview(playerView)
        avPlayer.play()
    }

    // MARK: 关场：当前位置 → 回落锚点

    @objc private func dismissToAnchor() {
        player?.pause()
        // 回落用首帧承接（AVPlayerLayer 不参与 frame 补间）
        playerView.removeFromSuperview()
        // 把拖拽 transform 固化为视觉包围盒，再做纯 frame 补间（平移+缩放下二者等价）
        let visual = container.frame
        container.transform = .identity
        container.frame = visual
        let animator = makeAnimator(duration: 0.32) {
            self.dimming.alpha = 0
            self.closeButton.alpha = 0
            self.container.frame = self.anchorFrame
            self.container.layer.cornerRadius = self.anchorRadius
        }
        animator.addCompletion { _ in
            self.sourceView?.isHidden = false
            self.dismiss(animated: false)
        }
        animator.startAnimation()
    }

    // MARK: 跟手拖拽：位移 + 缩放 + 遮罩联动，松手按位移/速度定去留

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        switch gesture.state {
        case .changed:
            let progress = min(1, abs(translation.y) / 320)
            let scale = 1 - 0.25 * progress
            container.transform = CGAffineTransform(translationX: translation.x, y: translation.y)
                .scaledBy(x: scale, y: scale)
            dimming.alpha = 1 - 0.85 * progress
            closeButton.alpha = 0
        case .ended, .cancelled:
            let velocity = gesture.velocity(in: view).y
            if abs(translation.y) > 140 || abs(velocity) > 800 {
                dismissToAnchor()
            } else {
                let spring = UIViewPropertyAnimator(duration: 0.4, dampingRatio: 0.8) {
                    self.container.transform = .identity
                    self.dimming.alpha = 1
                    self.closeButton.alpha = 1
                }
                spring.startAnimation()
            }
        default:
            break
        }
    }
}
