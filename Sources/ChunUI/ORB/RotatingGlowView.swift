/**
 * [INPUT]: 依赖 SwiftUI 的 Shape 与动画
 * [OUTPUT]: 对外提供 RotationDirection 与 RotatingGlowView（旋转发光环）
 * [POS]: ORB 的发光层；OrbView 按 OrbConfiguration 叠进球体
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

public enum RotationDirection {
    /// 顺时针
    case clockwise
    /// 逆时针
    case counterClockwise
    
    /// 旋转方向乘数
    /// - Returns: 顺时针返回1，逆时针返回-1
    var multiplier: Double {
        switch self {
        case .clockwise: return 1
        case .counterClockwise: return -1
        }
    }
}

/// 旋转发光视图组件
/// 创建一个带有发光效果并可以旋转的圆形视图
public struct RotatingGlowView: View {
    // MARK: - 属性
    
    /// 当前旋转角度
    @State private var rotation: Double = 0
    
    /// 发光颜色
    private let color: Color
    /// 旋转速度(每分钟旋转圈数)
    private let rotationSpeed: Double
    /// 旋转方向
    private let direction: RotationDirection
    
    // MARK: - 初始化方法
    
    /// 建旋转发光视图：color 为发光色，rotationSpeed 缺省 30 圈/分钟，direction 为旋转方向
    public init(color: Color,
         rotationSpeed: Double = 30,
         direction: RotationDirection)
    {
        self.color = color
        self.rotationSpeed = rotationSpeed
        self.direction = direction
    }
    
    // MARK: - 视图构建
    
    public var body: some View {
        GeometryReader { geometry in
            // 取宽高的最小值作为视图大小，确保视图为正圆形
            let size = min(geometry.size.width, geometry.size.height)
            
            Circle()
                .fill(color)
                .mask {
                    // 使用ZStack创建发光效果的遮罩
                    ZStack {
                        // 内层圆形
                        Circle()
                            .frame(width: size, height: size)
                            .blur(radius: size * 0.16)
                        // 外层圆形，用于创建渐变边缘
                        Circle()
                            .frame(width: size * 1.31, height: size * 1.31)
                            .offset(y: size * 0.31)
                            .blur(radius: size * 0.16)
                            .blendMode(.destinationOut)
                    }
                }
                .rotationEffect(.degrees(rotation))
                .onAppear {
                    // 创建永续旋转动画
                    withAnimation(.linear(duration: 360 / rotationSpeed).repeatForever(autoreverses: false)) {
                        rotation = 360 * direction.multiplier
                    }
                }
        }
    }
}

// MARK: - 预览

#Preview {
    RotatingGlowView(color: Color.cc.primary,
                   rotationSpeed: 30,
                   direction: .counterClockwise)
        .frame(width: 128, height: 128)
}
