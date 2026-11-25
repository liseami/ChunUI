//
//  FluidGradientView.swift
//  FluidGradientView
//
//  Created by Oskar Groth on 2021-12-23.
//

 
   
 
import Combine
import SwiftUI

#if os(OSX)
import AppKit
public typealias SystemColor = NSColor
public typealias SystemView = NSView
#else
 
public typealias SystemColor = UIColor
public typealias SystemView = UIView
#endif

/// A system view that presents an animated gradient with ``CoreAnimation``
public class FluidGradientView: SystemView {
    var speed: CGFloat
    var noiseOpacity: CGFloat = 0.1
    var noiseScale: CGFloat = 50.0  // 控制噪声的缩放
    var noiseSpeed: CGFloat = 1.0   // 控制噪声动画速度
    
    let baseLayer = ResizableLayer()
    let highlightLayer = ResizableLayer()
    let noiseLayer = CALayer()
    
    var cancellables = Set<AnyCancellable>()
    var noiseTimer: Timer?
    var time: CGFloat = 0
    
    weak var delegate: FluidGradientDelegate?
    
    public init(blobs: [Color] = [],
         highlights: [Color] = [],
         speed: CGFloat = 1.0,
         noiseOpacity: CGFloat = 0.1,
         noiseScale: CGFloat = 50.0,
         noiseSpeed: CGFloat = 1.0) {
        self.speed = speed
        self.noiseOpacity = noiseOpacity
        self.noiseScale = noiseScale
        self.noiseSpeed = noiseSpeed
        super.init(frame: .zero)
        
        if let compositingFilter = CIFilter(name: "CIOverlayBlendMode") {
            highlightLayer.compositingFilter = compositingFilter
        }
        
        #if os(OSX)
        layer = ResizableLayer()
        
        wantsLayer = true
        postsFrameChangedNotifications = true
        
        layer?.delegate = self
        baseLayer.delegate = self
        highlightLayer.delegate = self
        noiseLayer.delegate = self
        
        self.layer?.addSublayer(baseLayer)
        self.layer?.addSublayer(highlightLayer)
        
        // 设置和添加噪点图层（确保在最后添加）
        setupNoiseLayer()
        self.layer?.addSublayer(noiseLayer)
        #else
        self.layer.addSublayer(baseLayer)
        self.layer.addSublayer(highlightLayer)
        
        // 设置和添加噪点图层（确保在最后添加）
        setupNoiseLayer()
        self.layer.addSublayer(noiseLayer)
        #endif
        
        create(blobs, layer: baseLayer)
        create(highlights, layer: highlightLayer)
        
        startNoiseAnimation()
        
        DispatchQueue.main.async {
            self.update(speed: speed)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupNoiseLayer() {
        // 设置混合模式为 Screen
        noiseLayer.compositingFilter = "screenBlendMode"
        
        // 确保噪点图层覆盖整个视图
        noiseLayer.frame = bounds
        noiseLayer.masksToBounds = true
        
        // 设置重复模式
        noiseLayer.contentsGravity = .resize
        noiseLayer.magnificationFilter = .nearest
        noiseLayer.minificationFilter = .nearest
        
        // 设置不透明度
        noiseLayer.opacity = Float(noiseOpacity)
        
        // 初始化噪点图像
        updateNoiseImage()
    }
    
    private func startNoiseAnimation() {
        noiseTimer?.invalidate()
        noiseTimer = Timer.scheduledTimer(withTimeInterval: 1.0/30.0, repeats: true) { [weak self] _ in
            self?.updateNoiseAnimation()
        }
    }
    
    private func updateNoiseAnimation() {
        time += 0.1 * noiseSpeed  // 增加变化速度
        updateNoiseImage()
    }
    
    private func updateNoiseImage() {
        let noiseImage = generateNoiseImage()
        noiseLayer.contents = noiseImage
        
        // 更新frame以确保噪点覆盖整个视图
        noiseLayer.frame = bounds
    }
    
    private func generateNoiseImage() -> CGImage? {
        let size = CGSize(width: 100, height: 100)  // 更小的尺寸以获得更明显的噪点
        let bytesPerRow = Int(size.width * 4)
        var pixels = [UInt8](repeating: 0, count: Int(size.width * size.height * 4))
        
        for i in 0..<Int(size.width * size.height) {
            let offset = i * 4
            
            // 生成更明显的噪点
            let random = Double.random(in: 0...1)
            let noiseValue = random > 0.5 ? 255 : 0  // 二值化噪点
            
            // 设置像素值（白色噪点）
            pixels[offset] = UInt8(noiseValue)     // R
            pixels[offset + 1] = UInt8(noiseValue) // G
            pixels[offset + 2] = UInt8(noiseValue) // B
            pixels[offset + 3] = UInt8(255)        // A
        }
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        guard let context = CGContext(data: &pixels,
                                    width: Int(size.width),
                                    height: Int(size.height),
                                    bitsPerComponent: 8,
                                    bytesPerRow: bytesPerRow,
                                    space: colorSpace,
                                    bitmapInfo: bitmapInfo.rawValue) else {
            return nil
        }
        
        return context.makeImage()
    }
    
    public func updateNoiseSettings(opacity: CGFloat? = nil, scale: CGFloat? = nil, speed: CGFloat? = nil) {
        if let opacity = opacity {
            self.noiseOpacity = opacity
            noiseLayer.opacity = Float(opacity)
        }
        if let scale = scale {
            self.noiseScale = scale
        }
        if let speed = speed {
            self.noiseSpeed = speed
        }
    }
    
    deinit {
        noiseTimer?.invalidate()
    }
    
    /// Create blobs and add to specified layer
    public func create(_ colors: [Color], layer: CALayer) {
        // Remove blobs at the end if colors are removed
        let count = layer.sublayers?.count ?? 0
        let removeCount = count - colors.count
        if removeCount > 0 {
            layer.sublayers?.removeLast(removeCount)
        }
        
        for (index, color) in colors.enumerated() {
            if index < count {
                if let existing = layer.sublayers?[index] as? BlobLayer {
                    existing.set(color: color)
                }
            } else {
                layer.addSublayer(BlobLayer(color: color))
            }
        }
    }
    
    /// Update sublayers and set speed and blur levels
    public func update(speed: CGFloat) {
        cancellables.removeAll()
        self.speed = speed
        guard speed > 0 else { return }
        
        let layers = (baseLayer.sublayers ?? []) + (highlightLayer.sublayers ?? [])
        for layer in layers {
            if let layer = layer as? BlobLayer {
                Timer.publish(every: .random(in: 0.8/speed...1.2/speed),
                              on: .main,
                              in: .common)
                    .autoconnect()
                    .sink { _ in
                        #if os(OSX)
                        let visible = self.window?.occlusionState.contains(.visible)
                        guard visible == true else { return }
                        #endif
                        layer.animate(speed: speed)
                    }
                    .store(in: &cancellables)
            }
        }
    }
    
    /// Compute and update new blur value
    private func updateBlur() {
        delegate?.updateBlur(min(frame.width, frame.height))
    }
    
    /// Functional methods
    #if os(OSX)
    public override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        let scale = window?.backingScaleFactor ?? 2
        layer?.contentsScale = scale
        baseLayer.contentsScale = scale
        highlightLayer.contentsScale = scale
        noiseLayer.contentsScale = scale
        
        updateBlur()
    }
    
    public override func resize(withOldSuperviewSize oldSize: NSSize) {
        updateBlur()
    }
    #else
    public override func layoutSubviews() {
        super.layoutSubviews()
        layer.frame = self.bounds
        baseLayer.frame = self.bounds
        highlightLayer.frame = self.bounds
        noiseLayer.frame = self.bounds
        
        updateBlur()
    }
    #endif
}

protocol FluidGradientDelegate: AnyObject {
    func updateBlur(_ value: CGFloat)
}

#if os(OSX)
extension FluidGradientView: CALayerDelegate, NSViewLayerContentScaleDelegate {
    public func layer(_ layer: CALayer,
                      shouldInheritContentsScale newScale: CGFloat,
                      from window: NSWindow) -> Bool {
        return true
    }
}
#endif
