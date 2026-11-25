//
//  FilteredCameraPreview.swift
//  YUI
//
//  [INPUT]: AVCaptureSession + CameraFilter
//  [OUTPUT]: 实时滤镜预览视图 (MTKView + Metal 渲染)
//  [POS]: 相机预览的核心渲染器，替代无法处理滤镜的 AVCaptureVideoPreviewLayer
//
//  [PROTOCOL]:
//  1. 使用 AVCaptureVideoDataOutput 获取每帧 CMSampleBuffer
//  2. 转换为 CIImage 后应用 CameraFilter
//  3. 通过 Metal 渲染到 MTKView
//

import AVFoundation
import CoreImage
import MetalKit
import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - SwiftUI Wrapper
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct FilteredCameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    @Binding var filter: CameraFilter

    public func makeUIView(context: Context) -> FilteredPreviewMTKView {
        let view = FilteredPreviewMTKView()
        view.session = session
        view.currentFilter = filter
        return view
    }

    public func updateUIView(_ uiView: FilteredPreviewMTKView, context: Context) {
        uiView.currentFilter = filter
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - MTKView 实时滤镜预览
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public final class FilteredPreviewMTKView: MTKView {

    // ━━━ 公开属性 ━━━
    var session: AVCaptureSession? {
        didSet { setupVideoOutput() }
    }

    var currentFilter: CameraFilter = .none

    // ━━━ 私有属性 ━━━
    private var videoOutput: AVCaptureVideoDataOutput?
    private let videoQueue = DispatchQueue(label: "com.yui.camera.video", qos: .userInteractive)

    private var ciContext: CIContext?
    private var commandQueue: MTLCommandQueue?
    private var currentCIImage: CIImage?
    private let colorSpace = CGColorSpaceCreateDeviceRGB()

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 初始化
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    override init(frame: CGRect, device: MTLDevice?) {
        super.init(frame: frame, device: device ?? MTLCreateSystemDefaultDevice())
        setupMetal()
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
        self.device = MTLCreateSystemDefaultDevice()
        setupMetal()
    }

    private func setupMetal() {
        guard let metalDevice = device else {
            fatalError("Metal device not available")
        }

        commandQueue = metalDevice.makeCommandQueue()
        ciContext = CIContext(
            mtlDevice: metalDevice,
            options: [
                .useSoftwareRenderer: false,
                .highQualityDownsample: true,
                .cacheIntermediates: false
            ]
        )

        // MTKView 配置
        framebufferOnly = false
        enableSetNeedsDisplay = false
        isPaused = false
        preferredFramesPerSecond = 60
        contentMode = .scaleAspectFill
        backgroundColor = .black

        delegate = self
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Video Output 配置
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private func setupVideoOutput() {
        guard let session = session else { return }

        // 移除旧的 output
        if let oldOutput = videoOutput {
            session.removeOutput(oldOutput)
        }

        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: videoQueue)

        session.beginConfiguration()
        if session.canAddOutput(output) {
            session.addOutput(output)
            // 注意：不在 connection 上设置 videoRotationAngle
            // 方向修正在 captureOutput 中通过 CIImage.oriented(.right) 完成
        }
        session.commitConfiguration()

        videoOutput = output
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 清理
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    deinit {
        if let session = session, let output = videoOutput {
            session.beginConfiguration()
            session.removeOutput(output)
            session.commitConfiguration()
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extension FilteredPreviewMTKView: AVCaptureVideoDataOutputSampleBufferDelegate {

    public func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // 创建 CIImage
        var ciImage = CIImage(cvPixelBuffer: pixelBuffer)

        // 修正方向：相机传感器是横向的，需要顺时针旋转 90° 变为竖屏
        ciImage = ciImage.oriented(.right)

        // 应用滤镜
        if let ciContext {
            ciImage = currentFilter.apply(to: ciImage, context: ciContext)
        }

        // 线程安全更新
        currentCIImage = ciImage
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - MTKViewDelegate (Metal 渲染)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extension FilteredPreviewMTKView: MTKViewDelegate {

    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // 尺寸变化时不需特殊处理
    }

    public func draw(in view: MTKView) {
        guard let ciImage = currentCIImage,
              let drawable = currentDrawable,
              let ciContext,
              let commandBuffer = commandQueue?.makeCommandBuffer()
        else { return }

        let drawableSize = drawable.texture.width > 0 && drawable.texture.height > 0
            ? CGSize(width: drawable.texture.width, height: drawable.texture.height)
            : drawableSize

        guard drawableSize.width > 0, drawableSize.height > 0 else { return }

        // 计算 AspectFill 变换
        let scaleX = drawableSize.width / ciImage.extent.width
        let scaleY = drawableSize.height / ciImage.extent.height
        let scale = max(scaleX, scaleY)

        let scaledWidth = ciImage.extent.width * scale
        let scaledHeight = ciImage.extent.height * scale
        let offsetX = (drawableSize.width - scaledWidth) / 2
        let offsetY = (drawableSize.height - scaledHeight) / 2

        let transformedImage = ciImage
            .transformed(by: CGAffineTransform(scaleX: scale, y: scale))
            .transformed(by: CGAffineTransform(translationX: offsetX, y: offsetY))

        // 渲染到 drawable
        let destination = CIRenderDestination(
            width: Int(drawableSize.width),
            height: Int(drawableSize.height),
            pixelFormat: view.colorPixelFormat,
            commandBuffer: commandBuffer,
            mtlTextureProvider: { drawable.texture }
        )

        do {
            try ciContext.startTask(toRender: transformedImage, to: destination)
        } catch {
            // 静默失败
        }

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
