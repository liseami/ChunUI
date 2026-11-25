//
//  CameraPreviewView.swift
//  YUI
//
//  AVCaptureSession 预览层 + 胶片效果覆盖层
//

import AVFoundation
import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 相机预览层 (UIViewRepresentable)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct CameraPreviewLayer: UIViewRepresentable {
    let session: AVCaptureSession

    public func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.session = session
        return view
    }

    public func updateUIView(_ uiView: PreviewUIView, context: Context) {
        uiView.session = session
    }

    public class PreviewUIView: UIView {
        var session: AVCaptureSession? {
            didSet { previewLayer?.session = session }
        }

        override public class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer? { layer as? AVCaptureVideoPreviewLayer }

        override init(frame: CGRect) {
            super.init(frame: frame)
            previewLayer?.videoGravity = .resizeAspectFill
            backgroundColor = .black
        }

        required init?(coder: NSCoder) { fatalError() }

        override public func layoutSubviews() {
            super.layoutSubviews()
            previewLayer?.frame = bounds
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 胶片效果覆盖层
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct FilmSimulationOverlay: View {
    let filter: CameraFilter

    public var body: some View {
        ZStack {
            // 胶片颗粒
            FilmGrainView()
                .opacity(0.2)
                .blendMode(.overlay)

            // 暗角
            RadialGradient(
                colors: [.clear, .clear, Color(hex: "140f0a").opacity(filter.vignetteIntensity)],
                center: .center,
                startRadius: 80,
                endRadius: 280
            )
            .blendMode(.multiply)

            // 滤镜色调
            filter.overlayColor
                .opacity(filter.overlayOpacity)
                .blendMode(.overlay)
        }
        .allowsHitTesting(false)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 胶片颗粒
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct FilmGrainView: View {
    public var body: some View {
        TimelineView(.animation(minimumInterval: 0.1)) { _ in
            Canvas { context, size in
                for _ in 0..<Int(size.width * size.height / 150) {
                    let x = CGFloat.random(in: 0...size.width)
                    let y = CGFloat.random(in: 0...size.height)
                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: CGFloat.random(in: 0.5...1.2), height: 1)),
                        with: .color(.white.opacity(Double.random(in: 0.1...0.3)))
                    )
                }
            }
        }
    }
}
