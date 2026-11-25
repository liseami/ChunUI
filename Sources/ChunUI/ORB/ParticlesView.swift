/**
 * [INPUT]: 依赖 SpriteKit 的 SKScene / SKEmitterNode 与 SwiftUI 的 SpriteView
 * [OUTPUT]: 对外提供 ParticleScene（粒子场景）与 ParticlesView（SwiftUI 包装）
 * [POS]: ORB 的粒子层；OrbView 按 OrbConfiguration 叠进球体
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI
import SpriteKit

/// 粒子场景类,负责生成和管理粒子效果
public class ParticleScene: SKScene {
    // 粒子基本属性
    let color: UIColor           // 粒子颜色
    let speedRange: ClosedRange<Double>    // 粒子速度范围
    let sizeRange: ClosedRange<CGFloat>    // 粒子大小范围  
    let particleCount: Int       // 粒子数量
    let opacityRange: ClosedRange<Double>  // 粒子透明度范围
    
    /// 按场景尺寸、粒子色、速度 / 大小 / 透明度范围与粒子数建粒子场景
    public init(
        size: CGSize,
        color: UIColor,
        speedRange: ClosedRange<Double>,
        sizeRange: ClosedRange<CGFloat>,
        particleCount: Int,
        opacityRange: ClosedRange<Double>
    ) {
        self.color = color
        self.speedRange = speedRange
        self.sizeRange = sizeRange
        self.particleCount = particleCount
        self.opacityRange = opacityRange
        super.init(size: size)
        
        backgroundColor = .clear
        setupParticleEmitter()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 配置粒子发射器
    private func setupParticleEmitter() {
        let emitter = SKEmitterNode()
        
        // 创建白色粒子纹理
        emitter.particleTexture = createParticleTexture()
        
        // 设置粒子颜色属性
        emitter.particleColorSequence = nil
        emitter.particleColor = color
        emitter.particleColorBlendFactor = 1.0
        
        // 设置基本发射器属性
        emitter.particleSpeed = CGFloat(speedRange.lowerBound)
        emitter.particleSpeedRange = CGFloat(speedRange.upperBound - speedRange.lowerBound)
        emitter.particleScale = sizeRange.lowerBound
        emitter.particleScaleRange = sizeRange.upperBound - sizeRange.lowerBound
        
        // 设置透明度和渐变属性
        emitter.particleAlpha = 0 // 初始不可见
        emitter.particleAlphaSpeed = CGFloat(opacityRange.upperBound) / 0.5 // 0.5秒内渐入
        emitter.particleAlphaRange = CGFloat(opacityRange.upperBound - opacityRange.lowerBound)
        
        // 创建透明度关键帧序列实现渐入渐出效果
        let alphaSequence = SKKeyframeSequence(keyframeValues: [
            0,                              // 开始时不可见
            Double.random(in: opacityRange),        // 渐入到最大透明度
            Double.random(in: opacityRange),        // 保持最大透明度
            Double.random(in: opacityRange)         // 渐出到最小透明度
        ], times: [
            0,      // 开始时刻
            0.2,    // 20%生命周期达到最大
            0.8,    // 80%生命周期保持最大
            1.0     // 结束时刻
        ])
        emitter.particleAlphaSequence = alphaSequence
        
        // 创建缩放关键帧序列实现大小动画
        let scaleSequence = SKKeyframeSequence(keyframeValues: [
            sizeRange.lowerBound * 0.7,    // 初始为最小尺寸的70%
            sizeRange.upperBound * 0.9,    // 增长到最大尺寸的90%
            sizeRange.upperBound,          // 达到最大尺寸
            sizeRange.lowerBound * 0.8     // 缩小到最小尺寸的80%
        ], times: [
            0,      // 开始时刻
            0.4,    // 40%生命周期
            0.7,    // 70%生命周期
            1.0     // 结束时刻
        ])
        emitter.particleScaleSequence = scaleSequence
        
        // 设置混合模式
        emitter.particleBlendMode = .add
        
        // 设置发射器位置和发射区域
        emitter.position = CGPoint(x: size.width/2, y: size.height/2)
        emitter.particlePositionRange = CGVector(dx: size.width, dy: size.height)
        
        // 设置粒子生命周期相关属性
        emitter.particleBirthRate = CGFloat(particleCount) / 2.0
        emitter.numParticlesToEmit = 0
        emitter.particleLifetime = 2.0
        emitter.particleLifetimeRange = 1.0
        
        // 设置运动属性
        emitter.emissionAngle = CGFloat.pi / 2  // 向上发射(90度)
        emitter.emissionAngleRange = CGFloat.pi / 6  // 左右30度变化范围
        
        // 设置加速度
        emitter.xAcceleration = 0  // 水平无加速度
        emitter.yAcceleration = 20 // 轻微向上加速
        
        addChild(emitter)
    }
    
    /// 画一张粒子纹理
    private func createParticleTexture() -> SKTexture {
        let size = CGSize(width: 8, height: 8)  // 使用较小尺寸提高性能
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { context in
            // 创建简单的白色填充圆形
            UIColor.white.setFill()
            let circlePath = UIBezierPath(ovalIn: CGRect(origin: .zero, size: size))
            circlePath.fill()
        }
        
        return SKTexture(image: image)
    }
}

/// 粒子视图组件
public struct ParticlesView: View {
    let color: Color             // 粒子颜色
    let speedRange: ClosedRange<Double>    // 速度范围
    let sizeRange: ClosedRange<CGFloat>    // 大小范围
    let particleCount: Int       // 粒子数量
    let opacityRange: ClosedRange<Double>  // 透明度范围
    
    /// 创建场景
    var scene: SKScene {
        let scene = ParticleScene(
            size: CGSize(width: 300, height: 300), // 使用固定尺寸
            color: UIColor(color),
            speedRange: speedRange,
            sizeRange: sizeRange,
            particleCount: particleCount,
            opacityRange: opacityRange
        )
        scene.scaleMode = .aspectFit
        return scene
    }
    
    public var body: some View {
        GeometryReader { geometry in
            SpriteView(scene: scene, options: [.allowsTransparency])
                .frame(width: geometry.size.width, height: geometry.size.height)
                .ignoresSafeArea()
        }
    }
}

/// 预览
#Preview {
    ParticlesView(
        color: Color.cc.chartCarbs,
        speedRange: 30...60,
        sizeRange: 0.2...1,
        particleCount: 100,
        opacityRange: 0.5...1
    )
    .background(Color.cc.foreground)
}
