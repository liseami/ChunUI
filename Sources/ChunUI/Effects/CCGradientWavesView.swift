/**
 * [INPUT]: 依赖 Shaders/CCGradientWaves.metal 的 ccGradientWavesVertex/Fragment 经典管线（Bundle.module metallib）、MetalKit MTKView、Color.cc 主题轴（toRGB 灌色）、Reduce Motion、Core/CCLog（DEBUG 报管线装配失败）
 * [OUTPUT]: 对外提供 CCGradientWavesView——倒挂等离子体海面（MTKView 真管线 30fps）；speech 0…1 发言能量经渲染器攻快衰慢平滑，驱动振幅/湍流/相机微抖
 * [POS]: Effects 的发言涟漪氛围层（宿主 Onboarding Hi 场景铺底）；不拦截点击；stitchable 已废——管线建不起来时 DEBUG 控制台报错，不再静默隐身
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import MetalKit
import SwiftUI

public struct CCGradientWavesView: View {
    /// 发言能量：打字时顶到 1，字间落到 ~0.28，结束归零（平滑在渲染器内做）
    var speech: CGFloat = 0

    public init(speech: CGFloat = 0) {
        self.speech = speech
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.ccAtmospherePaused) private var atmospherePaused

    public var body: some View {
        WaveMetalView(
            energyTarget: reduceMotion ? 0 : Float(speech),
            paused: reduceMotion || atmospherePaused,
            // 三层拉满对比：horizon 压深（混黑 25%）/ wave 主色提纯（混白 30%）/ crest 纯白；混背景淡化 = 隐身，禁回退
            horizon: rgba(Color.cc.primary.mix(with: .black, amount: 0.15)),
            wave: rgba(Color.cc.primary.mix(with: .white, amount: 0.30)),
            crest: rgba(.white)
        )
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .ignoresSafeArea()
    }

    private func rgba(_ color: Color) -> SIMD4<Float> {
        let rgb = color.toRGB()
        return SIMD4(rgb.x, rgb.y, rgb.z, 1)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - MTKView 桥（透明层 + 预乘 alpha 混合；能量目标值传给渲染器逐帧平滑）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

private struct WaveMetalView: UIViewRepresentable {
    var energyTarget: Float
    var paused: Bool
    var horizon: SIMD4<Float>
    var wave: SIMD4<Float>
    var crest: SIMD4<Float>

    func makeCoordinator() -> WaveRenderer { WaveRenderer() }

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView(frame: .zero, device: MTLCreateSystemDefaultDevice())
        view.delegate = context.coordinator
        view.preferredFramesPerSecond = 30
        view.isOpaque = false
        view.backgroundColor = .clear
        view.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        view.framebufferOnly = true
        context.coordinator.build(for: view)
        return view
    }

    func updateUIView(_ view: MTKView, context: Context) {
        let renderer = context.coordinator
        renderer.energyTarget = energyTarget
        renderer.colors = (horizon, wave, crest)
        view.isPaused = paused || !renderer.isReady
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - WaveRenderer（经典管线：全屏三角 + setBytes uniforms；攻快衰慢的能量包络）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

private final class WaveRenderer: NSObject, MTKViewDelegate {
    /// Metal 侧 WaveUniforms 同构布局（float2 对齐 8 / float4 对齐 16）
    private struct WaveUniforms {
        var resolution: SIMD2<Float>
        var time: Float
        var energy: Float
        var horizon: SIMD4<Float>
        var wave: SIMD4<Float>
        var crest: SIMD4<Float>
        var params: SIMD4<Float>   // opacity, brightness, 备用×2
    }

    var energyTarget: Float = 0
    var colors: (horizon: SIMD4<Float>, wave: SIMD4<Float>, crest: SIMD4<Float>) = (.zero, .zero, .zero)
    var isReady: Bool { pipeline != nil }

    private var energy: Float = 0
    private let startTime = CACurrentMediaTime()
    private var pipeline: MTLRenderPipelineState?
    private var queue: MTLCommandQueue?

    func build(for view: MTKView) {
        guard let device = view.device,
              let library = try? device.makeDefaultLibrary(bundle: .module),
              let vertexFn = library.makeFunction(name: "ccGradientWavesVertex"),
              let fragmentFn = library.makeFunction(name: "ccGradientWavesFragment")
        else {
            #if DEBUG
            CCLog.error("Pipeline setup failed: Bundle.module metallib lacks ccGradientWavesVertex/Fragment", category: "GradientWaves")
            #endif
            return
        }
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFn
        descriptor.fragmentFunction = fragmentFn
        guard let attachment = descriptor.colorAttachments[0] else { return }
        attachment.pixelFormat = view.colorPixelFormat
        // 预乘 alpha：src.rgb 已乘 a，dst 乘 (1-a)
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
            CCLog.error("makeRenderPipelineState failed: \(error)", category: "GradientWaves")
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

        // 发言包络：攻快（尖峰有冲击）、衰慢（字间有余韵）
        let rate: Float = energyTarget > energy ? 0.5 : 0.1
        energy += (energyTarget - energy) * rate

        var uniforms = WaveUniforms(
            resolution: SIMD2(Float(view.drawableSize.width), Float(view.drawableSize.height)),
            time: Float(CACurrentMediaTime() - startTime),
            energy: energy,
            horizon: colors.horizon,
            wave: colors.wave,
            crest: colors.crest,
            params: SIMD4(1.0, 1.0, 0, 0)
        )
        encoder.setRenderPipelineState(pipeline)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<WaveUniforms>.stride, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()
        buffer.present(drawable)
        buffer.commit()
    }
}

#Preview("涟漪") {
    struct Demo: View {
        @State private var speech: CGFloat = 0
        var body: some View {
            ZStack {
                Color.cc.background.ignoresSafeArea()
                CCGradientWavesView(speech: speech)
                VStack {
                    Spacer()
                    Button(speech > 0 ? "停止发言" : "模拟发言") {
                        speech = speech > 0 ? 0 : 1
                    }
                    .padding(.bottom, 60)
                }
            }
        }
    }
    return Demo()
}
