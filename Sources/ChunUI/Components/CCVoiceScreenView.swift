/**
 * [INPUT]: 依赖 CCVoiceScreen 的点表与光圈、Shaders/CCVoiceDots.metal 的全屏三角、MetalKit 的 MTKView
 * [OUTPUT]: 提供 CCVoiceScreenView。暗色屏面、上沿内阴影、下沿唇边、斜向反光、点阵声纹、左上已录时长的点阵数字
 * [POS]: Components 的按住说话凹屏。HoldTalkPanel 把它摆进板里，与板的弹簧同一个显示链推进
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import MetalKit
import UIKit

public final class CCVoiceScreenView: UIView {
    public var zone: CCHoldZone = .center {
        didSet { aimZone() }
    }

    public var still = false {
        didSet { model?.still = still }
    }

    private let metal = MTKView(frame: .zero, device: MTLCreateSystemDefaultDevice())
    private let renderer = VoiceDotsRenderer()
    private let digits = CAShapeLayer()
    private let sink = CAShapeLayer()
    private let lip = CAShapeLayer()
    private let lipMask = CAGradientLayer()
    private let glare = CAGradientLayer()
    private let seed: Int
    private var model: CCVoiceScreen?
    private var modelSize: CGSize = .zero
    private var last: CFTimeInterval?
    private var onAt: CFTimeInterval?
    private var offAt: CFTimeInterval?
    private var collapseAt: CFTimeInterval?
    private var elapsed: Int?
    private var digitsTone: Float = -1
    private var digitsOpen: Float = -1

    private static let face = UIColor(displayP3Red: 0.102, green: 0.102, blue: 0.102, alpha: 1)
    private static let ink = SIMD3<Float>(0.9606, 0.9606, 0.9606)
    private static let danger = SIMD3<Float>(0.819, 0.4279, 0.4147)
    private static let dot: CGFloat = 2.4
    private static let glow: CGFloat = 2.2
    private static let glowAlpha: CGFloat = 0.28
    private static let digitDot: CGFloat = 2
    private static let digitInset: CGFloat = 12
    private static let sinkY: CGFloat = 2
    private static let sinkBlur: CGFloat = 8
    private static let sinkAlpha: Float = 0.6
    private static let lipAlpha: CGFloat = 0.22
    private static let glareAlpha: CGFloat = 0.06
    private static let rim: CGFloat = 1
    private static let radius: CGFloat = 26
    private static let screenOff = 0.2

    public init(seed: Int = Int.random(in: 0..<997)) {
        self.seed = seed
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        backgroundColor = Self.face
        layer.cornerCurve = .continuous
        layer.masksToBounds = true
        metal.delegate = renderer
        metal.isOpaque = false
        metal.backgroundColor = .clear
        metal.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        metal.framebufferOnly = true
        metal.enableSetNeedsDisplay = false
        metal.isPaused = true
        renderer.build(pixelFormat: metal.colorPixelFormat)
        addSubview(metal)
        digits.shadowOffset = .zero
        digits.shadowRadius = Self.digitDot * Self.glow / 2
        digits.shadowOpacity = Float(Self.glowAlpha)
        layer.addSublayer(digits)
        sink.fillColor = UIColor.black.cgColor
        sink.shadowColor = UIColor.black.cgColor
        sink.shadowOffset = CGSize(width: 0, height: Self.sinkY)
        sink.shadowRadius = Self.sinkBlur / 2
        sink.shadowOpacity = Self.sinkAlpha
        layer.addSublayer(sink)
        lip.fillColor = nil
        lip.strokeColor = UIColor.white.withAlphaComponent(Self.lipAlpha).cgColor
        lip.lineWidth = Self.rim
        lipMask.colors = [UIColor.clear.cgColor, UIColor.white.cgColor]
        lipMask.locations = [0.5, 1]
        lip.mask = lipMask
        layer.addSublayer(lip)
        glare.colors = [UIColor.white.withAlphaComponent(Self.glareAlpha).cgColor, UIColor.clear.cgColor]
        glare.locations = [0, 0.5]
        glare.startPoint = .zero
        glare.endPoint = CGPoint(x: 1, y: 1)
        layer.addSublayer(glare)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    public func push(level: CGFloat) {
        model?.push(Float(level))
    }

    public func powerOn(at now: CFTimeInterval) {
        guard onAt == nil else { return }
        onAt = still ? now - 0.4 : now
    }

    public func powerOff(at now: CFTimeInterval) {
        offAt = offAt ?? now
    }

    public func collapse(at now: CFTimeInterval) {
        collapseAt = collapseAt ?? now
    }

    public func setElapsed(_ seconds: Int?) {
        guard seconds != elapsed else { return }
        elapsed = seconds
        drawDigits()
    }

    public func step(at now: CFTimeInterval) {
        guard model != nil else { return }
        let dt = last.map { min(0.1, max(0, now - $0)) } ?? 0
        last = now
        let crt = CCVoiceScreen.CRT.at(now, on: onAt, off: offAt)
        let c = collapseAt.map { Float(min(1, (now - $0) / Self.screenOff)) } ?? 0
        model?.step(dt, time: now, wake: crt.wake, collapse: c * (2 - c))
        if let model { present(model, crt: crt) }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let r = Self.radius
        layer.cornerRadius = r
        metal.frame = bounds
        metal.contentScaleFactor = max(1, traitCollection.displayScale)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        digits.frame = bounds
        let ring = UIBezierPath(rect: bounds.insetBy(dx: -Self.sinkBlur * 2, dy: -Self.sinkBlur * 2))
        ring.append(UIBezierPath(roundedRect: bounds, cornerRadius: r).reversing())
        sink.frame = bounds
        sink.path = ring.cgPath
        sink.shadowPath = ring.cgPath
        lip.frame = bounds
        lip.path = UIBezierPath(roundedRect: bounds.insetBy(dx: Self.rim / 2, dy: Self.rim / 2), cornerRadius: max(0, r - Self.rim / 2)).cgPath
        lipMask.frame = bounds
        glare.frame = bounds
        CATransaction.commit()
        guard bounds.width > 0, bounds.height > 0, bounds.size != modelSize else { return }
        modelSize = bounds.size
        var next = CCVoiceScreen(size: bounds.size, seed: seed)
        next.still = still
        model = next
        renderer.resize(cols: next.cols, rows: next.rows)
        aimZone()
        drawDigits()
    }

    private func aimZone() {
        model?.dangerTarget = zone == .cancel ? 1 : 0
        model?.textTarget = zone == .transcribe ? 1 : 0
    }

    private func present(_ model: CCVoiceScreen, crt: CCVoiceScreen.CRT) {
        let tone = Self.ink + (Self.danger - Self.ink) * model.danger
        renderer.frame(dots: model.dots, uniforms: .init(
            tint: SIMD4(tone, 1),
            size: SIMD2(Float(bounds.width), Float(bounds.height)),
            origin: SIMD2(Float(model.origin.x), Float(model.origin.y)),
            pitch: 6,
            dotSize: Float(Self.dot),
            glow: Float(Self.dot * Self.glow),
            glowAlpha: Float(Self.glowAlpha),
            aa: Float(1 / max(1, traitCollection.displayScale)),
            openY: crt.openY,
            openX: crt.openX,
            beam: crt.beam,
            cols: UInt32(model.cols),
            rows: UInt32(model.rows)
        ))
        metal.draw()
        let open = min(crt.openY, crt.openX) * crt.wake
        guard abs(model.danger - digitsTone) > 0.02 || abs(open - digitsOpen) > 0.02 || (open == 1) != (digitsOpen == 1) else { return }
        digitsTone = model.danger
        digitsOpen = open
        let color = UIColor(red: CGFloat(tone.x), green: CGFloat(tone.y), blue: CGFloat(tone.z), alpha: 1).cgColor
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        digits.fillColor = color
        digits.shadowColor = color
        digits.opacity = open
        CATransaction.commit()
    }

    private func drawDigits() {
        let inset = Self.digitInset
        let dot = Self.digitDot
        let points = elapsed.map { CCVoiceScreen.digits(CCVoiceScreen.clock($0), at: CGPoint(x: inset, y: inset)) } ?? []
        let path = CGMutablePath()
        for p in points { path.addEllipse(in: CGRect(x: p.x - dot / 2, y: p.y - dot / 2, width: dot, height: dot)) }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        digits.path = path
        CATransaction.commit()
    }
}

private final class VoiceDotsRenderer: NSObject, MTKViewDelegate {
    struct Uniforms {
        var tint: SIMD4<Float>
        var size: SIMD2<Float>
        var origin: SIMD2<Float>
        var pitch: Float
        var dotSize: Float
        var glow: Float
        var glowAlpha: Float
        var aa: Float
        var openY: Float
        var openX: Float
        var beam: Float
        var cols: UInt32
        var rows: UInt32
    }

    private var pipeline: MTLRenderPipelineState?
    private var queue: MTLCommandQueue?
    private var buffers: [MTLBuffer] = []
    private var index = 0
    private var uniforms: Uniforms?

    func build(pixelFormat: MTLPixelFormat) {
        guard let device = MTLCreateSystemDefaultDevice(),
              let library = try? device.makeDefaultLibrary(bundle: .module),
              let vertex = library.makeFunction(name: "ccVoiceDotsVertex"),
              let fragment = library.makeFunction(name: "ccVoiceDotsFragment")
        else { return }
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertex
        descriptor.fragmentFunction = fragment
        descriptor.colorAttachments[0].pixelFormat = pixelFormat
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .one
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        pipeline = try? device.makeRenderPipelineState(descriptor: descriptor)
        queue = device.makeCommandQueue()
    }

    func resize(cols: Int, rows: Int) {
        let length = max(1, cols * rows) * MemoryLayout<SIMD4<Float>>.stride
        guard let device = MTLCreateSystemDefaultDevice() else { return }
        buffers = (0..<3).compactMap { _ in device.makeBuffer(length: length, options: .storageModeShared) }
        index = 0
    }

    func frame(dots: [SIMD4<Float>], uniforms next: Uniforms) {
        guard buffers.count == 3 else { return }
        index = (index + 1) % 3
        let buffer = buffers[index]
        dots.withUnsafeBytes { raw in
            guard let base = raw.baseAddress, raw.count <= buffer.length else { return }
            buffer.contents().copyMemory(from: base, byteCount: raw.count)
        }
        uniforms = next
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard let pipeline, let queue, var uniforms, buffers.count == 3,
              let pass = view.currentRenderPassDescriptor, let drawable = view.currentDrawable,
              let command = queue.makeCommandBuffer(), let encoder = command.makeRenderCommandEncoder(descriptor: pass) else { return }
        encoder.setRenderPipelineState(pipeline)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 0)
        encoder.setFragmentBuffer(buffers[index], offset: 0, index: 1)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()
        command.present(drawable)
        command.commit()
    }
}
