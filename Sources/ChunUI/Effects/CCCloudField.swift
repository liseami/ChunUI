/**
 * [INPUT]: 依赖 Shaders/CCCloudField.metal 的 ccCloudFieldVertex/Fragment 经典管线（Bundle.module metallib）、MetalKit MTKView、ccAtmospherePaused（侧边栏跟手时宿主暂停）、Core/CCLog（DEBUG 报管线装配失败）
 * [OUTPUT]: 对外提供 CCCloudField——Cromma 体积云独立 IsolatedCloudMTKView（30fps、原生 DPR；Equatable 按 pause；离窗 / 氛围暂停才停）；点阵/极光在 CCSkyHeroCard
 * [POS]: Effects 的体积云氛围层。只画云。形态表与 cromma-cloud/layouts 同构，步进改连续时间
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import MetalKit
import SwiftUI

private struct CCAtmospherePausedKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// 侧边栏跟手 / 离屏时暂停氛围层（云、极光、涟漪），避免 60fps 位移去合成活 shader
    public var ccAtmospherePaused: Bool {
        get { self[CCAtmospherePausedKey.self] }
        set { self[CCAtmospherePausedKey.self] = newValue }
    }
}

public struct CCCloudField: View {
    public init() {}

    @Environment(\.ccAtmospherePaused) private var atmospherePaused
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public var body: some View {
        CloudMetalView(paused: atmospherePaused || reduceMotion)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .transaction { $0.animation = nil }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 形态（cromma-cloud/layouts.ts 同构）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

private struct CloudBlob {
    var x: Float
    var y: Float
    var r: Float
}

private struct CloudBody {
    var cx: Float
    var cy: Float
    var hw: Float
    var hh: Float
}

private enum CloudLayout {
    static let aspect: Float = 0.6
    static let golden: Float = 0.618
    static let wingReachMax: Float = 0.98 + 0.05 + 0.34 * 1.08 * aspect
    /// 手机卡窄：舞台放大让云铺满（Hero CLOUD_STAGE_SCALE_MOBILE = 2.2）
    static let stageScale: Float = 2.2
    static let seeds: [(Float, Float, Float)] = [
        (0, 0.02, 0.6),
        (-0.52, 0.12, 0.44),
        (0.54, 0.08, 0.46),
        (-0.26, -0.36, 0.4),
        (0.3, -0.4, 0.38),
        (-0.98, 0.3, 0.34),
        (0.98, 0.26, 0.34),
    ]

    static func body(width: Float, height: Float) -> CloudBody {
        let stageW = width * stageScale
        let hw = (stageW * golden) / 2 / wingReachMax
        let hh = min(hw * aspect, height * 0.34)
        return CloudBody(cx: width / 2, cy: height * 0.5, hw: hw, hh: hh)
    }

    static func cumulus(step: Float, _ b: CloudBody) -> [CloudBlob] {
        var blobs = seeds.enumerated().map { i, c in
            let wing = i >= 5
            let ax: Float = wing ? 0.05 : 0.22
            let ay: Float = wing ? 0.06 : 0.26
            let ar: Float = wing ? 0.08 : 0.26
            return CloudBlob(
                x: b.cx + (c.0 + ax * sin(step * 0.32 + Float(i) * 1.3)) * b.hw,
                y: b.cy + (c.1 + ay * cos(step * 0.24 + Float(i) * 0.9)) * b.hh,
                r: c.2 * (1 + ar * sin(step * 0.18 + Float(i) * 1.7)) * b.hh
            )
        }
        let extra = 0.22 + 0.16 * (0.5 + 0.5 * sin(step * 0.22 + 0.4))
        blobs.append(CloudBlob(x: b.cx + 0.35 * sin(step * 0.16) * b.hw, y: b.cy - 0.55 * b.hh, r: extra * 0.38 * b.hh))
        return blobs
    }

    static func pad(_ blobs: [CloudBlob]) -> [CloudBlob] {
        var out = Array(blobs.prefix(8))
        let anchor = out.first ?? CloudBlob(x: 0, y: 0, r: 0)
        while out.count < 8 { out.append(CloudBlob(x: anchor.x, y: anchor.y, r: 0)) }
        return out
    }
}

/// drawer 曲线已不再用于换形；保留会误导。连续采样 sin/cos 即云舒云卷。

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - MTKView（独立渲染：pause 只认氛围/离窗，业务 Store 进不来）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// 只认窗口与氛围暂停，不认业务 Store。pause 以外的 SwiftUI 差分进不了帧循环。
private struct CloudMetalView: UIViewRepresentable, Equatable {
    var paused: Bool
    static func == (lhs: Self, rhs: Self) -> Bool { lhs.paused == rhs.paused }

    func makeCoordinator() -> CloudRenderer { CloudRenderer() }

    func makeUIView(context: Context) -> IsolatedCloudMTKView {
        let view = IsolatedCloudMTKView(frame: .zero, device: MTLCreateSystemDefaultDevice())
        view.delegate = context.coordinator
        view.preferredFramesPerSecond = 30
        view.isOpaque = false
        view.backgroundColor = .clear
        view.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        view.framebufferOnly = true
        view.presentsWithTransaction = false
        view.enableSetNeedsDisplay = false
        view.contentScaleFactor = UIScreen.main.scale
        view.atmospherePaused = paused
        view.applyPause()
        context.coordinator.build(for: view)
        return view
    }

    func updateUIView(_ view: IsolatedCloudMTKView, context: Context) {
        view.atmospherePaused = paused
        view.applyPause()
    }

    static func dismantleUIView(_ view: IsolatedCloudMTKView, coordinator: CloudRenderer) {
        view.isPaused = true
        view.delegate = nil
    }
}

/// 离窗 / 氛围暂停 / Reduce Motion 才停。业务 View 刷新改不了 isPaused。
private final class IsolatedCloudMTKView: MTKView {
    var atmospherePaused = false

    override func didMoveToWindow() {
        super.didMoveToWindow()
        applyPause()
    }

    func applyPause() {
        isPaused = window == nil || atmospherePaused || UIAccessibility.isReduceMotionEnabled
    }
}

private final class CloudRenderer: NSObject, MTKViewDelegate {
    struct CloudUniforms {
        var resolution: SIMD2<Float>
        var dpr: Float
        var time: Float
        var blob0: SIMD4<Float>
        var blob1: SIMD4<Float>
        var blob2: SIMD4<Float>
        var blob3: SIMD4<Float>
        var blob4: SIMD4<Float>
        var blob5: SIMD4<Float>
        var blob6: SIMD4<Float>
        var blob7: SIMD4<Float>
        var box: SIMD4<Float>
        var alpha: Float
        var shadow: Float
        var scale: Float
        var count: Float
        var sweep: Float
        var sweepAlpha: Float
        var pad0: Float = 0
        var pad1: Float = 0
        var palA: SIMD4<Float>
        var palB: SIMD4<Float>
        var palC: SIMD4<Float>
        var palD: SIMD4<Float>
    }

    var isReady: Bool { pipeline != nil }

    private let startTime = CACurrentMediaTime()
    private var pipeline: MTLRenderPipelineState?
    private var queue: MTLCommandQueue?

    func build(for view: MTKView) {
        guard let device = view.device,
              let library = try? device.makeDefaultLibrary(bundle: .module),
              let vertexFn = library.makeFunction(name: "ccCloudFieldVertex"),
              let fragmentFn = library.makeFunction(name: "ccCloudFieldFragment")
        else {
            #if DEBUG
            CCLog.error("Pipeline setup failed: Bundle.module metallib lacks ccCloudFieldVertex/Fragment", category: "CloudField")
            #endif
            return
        }
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFn
        descriptor.fragmentFunction = fragmentFn
        guard let attachment = descriptor.colorAttachments[0] else { return }
        attachment.pixelFormat = view.colorPixelFormat
        attachment.isBlendingEnabled = true
        attachment.sourceRGBBlendFactor = .one
        attachment.sourceAlphaBlendFactor = .one
        attachment.destinationRGBBlendFactor = .oneMinusSourceAlpha
        attachment.destinationAlphaBlendFactor = .oneMinusSourceAlpha
        do {
            pipeline = try device.makeRenderPipelineState(descriptor: descriptor)
            queue = device.makeCommandQueue()
        } catch {
            #if DEBUG
            CCLog.error("makeRenderPipelineState failed: \(error)", category: "CloudField")
            #endif
        }
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard let pipeline, let queue,
              let drawable = view.currentDrawable,
              let pass = view.currentRenderPassDescriptor,
              let buffer = queue.makeCommandBuffer(),
              let encoder = buffer.makeRenderCommandEncoder(descriptor: pass)
        else { return }

        let dpr = Float(view.contentScaleFactor)
        let css = SIMD2(Float(view.drawableSize.width) / max(dpr, 1), Float(view.drawableSize.height) / max(dpr, 1))
        let reduce = UIAccessibility.isReduceMotionEnabled
        let time = reduce ? 0 : Float(CACurrentMediaTime() - startTime)
        let body = CloudLayout.body(width: max(css.x, 1), height: max(css.y, 1))
        let blobs = CloudLayout.pad(CloudLayout.cumulus(step: time * 0.07, body))

        var top: Float = .greatestFiniteMagnitude
        var bottom: Float = -.greatestFiniteMagnitude
        var left: Float = .greatestFiniteMagnitude
        var right: Float = -.greatestFiniteMagnitude
        var packed = [SIMD4<Float>](repeating: .zero, count: 8)
        for i in 0..<8 {
            let c = blobs[i]
            let dx = sin(time * 0.11 + Float(i) * 1.7) * 3
            let dy = cos(time * 0.09 + Float(i) * 1.1) * 2
            packed[i] = SIMD4(c.x + dx, c.y + dy, c.r, 0)
            if c.r > 0.5 {
                top = min(top, c.y + dy - c.r)
                bottom = max(bottom, c.y + dy + c.r)
                left = min(left, c.x + dx - c.r)
                right = max(right, c.x + dx + c.r)
            }
        }

        let box: SIMD4<Float> = top.isFinite
            ? SIMD4(left, top, max(1, right - left), max(1, bottom - top))
            : SIMD4(0, 0, 1, 1)
        let fadeIn = min(1, time / 1.4)

        var uniforms = CloudUniforms(
            resolution: SIMD2(Float(view.drawableSize.width), Float(view.drawableSize.height)),
            dpr: dpr,
            time: time,
            blob0: packed[0], blob1: packed[1], blob2: packed[2], blob3: packed[3],
            blob4: packed[4], blob5: packed[5], blob6: packed[6], blob7: packed[7],
            box: box,
            alpha: reduce ? 1 : fadeIn,
            shadow: 0.06,
            scale: 1,
            count: 8,
            sweep: -1,
            sweepAlpha: 0,
            palA: SIMD4(0.8, 0.88, 0.96, 0),
            palB: SIMD4(0.1, 0.075, 0.05, 0),
            palC: SIMD4(0.6, 0.5, 0.4, 0),
            palD: SIMD4(0.5, 0.55, 0.65, 0)
        )
        encoder.setRenderPipelineState(pipeline)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<CloudUniforms>.stride, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()
        buffer.present(drawable)
        buffer.commit()
        if reduce { view.isPaused = true }
    }
}

#Preview("云") {
    ZStack {
        Color.cc.background.ignoresSafeArea()
        CCCloudField()
            .frame(height: 320)
    }
}
