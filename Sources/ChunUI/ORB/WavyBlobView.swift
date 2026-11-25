/**
 * [INPUT]: 依赖 SwiftUI 的 Path 与 TimelineView 式循环动画
 * [OUTPUT]: 对外提供 WavyBlobView（六控制点平滑波浪 blob，可作背景装饰或交互反馈）
 * [POS]: ORB 的波浪层；OrbView 按 OrbConfiguration 叠进球体
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI

/// 波浪状的动态 Blob 视图
/// 作者: zhaochunxiang
/// 创建时间: 2024-01-20
/// 功能描述: 创建一个平滑动画的波浪状 blob 效果,可用于背景装饰或交互反馈
public struct WavyBlobView: View {
    // 定义 6 个控制点,均匀分布在圆周上
    @State private var points: [CGPoint] = (0 ..< 6).map { index in
        let angle = (Double(index) / 6) * 2 * .pi
        return CGPoint(
            x: 0.5 + cos(angle) * 0.9, // 控制点 x 坐标
            y: 0.5 + sin(angle) * 0.9  // 控制点 y 坐标
        )
    }

    private let color: Color        // blob 的填充颜色
    private let loopDuration: Double // 动画循环周期
 
    /// color 为 blob 颜色；loopDuration 为一次动画循环的时长，缺省 1 秒
    public init(color: Color, loopDuration: Double = 1) {
        self.color = color
        self.loopDuration = loopDuration
    }

    public var body: some View {
        // 使用 TimelineView 创建连续动画
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                // 计算当前动画时间和角度
                let timeNow = timeline.date.timeIntervalSinceReferenceDate
                let angle = (timeNow.remainder(dividingBy: loopDuration) / loopDuration) * 2 * .pi

                var path = Path()
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = min(size.width, size.height) * 0.45 // blob 的基础半径

                // 根据时间调整控制点位置,创造波动效果
                let adjustedPoints = points.enumerated().map { index, point in
                    let phaseOffset = Double(index) * .pi / 3  // 每个点的相位偏移
                    let xOffset = sin(angle + phaseOffset) * 0.15  // x 方向的波动
                    let yOffset = cos(angle + phaseOffset) * 0.15  // y 方向的波动
                    return CGPoint(
                        x: (point.x - 0.5 + xOffset) * radius + center.x,
                        y: (point.y - 0.5 + yOffset) * radius + center.y
                    )
                }

                // 开始绘制路径
                path.move(to: adjustedPoints[0])

                // 在控制点之间创建平滑的贝塞尔曲线
                for i in 0 ..< adjustedPoints.count {
                    let next = (i + 1) % adjustedPoints.count

                    // 计算相邻点之间的角度
                    let currentAngle = atan2(
                        adjustedPoints[i].y - center.y,
                        adjustedPoints[i].x - center.x
                    )
                    let nextAngle = atan2(
                        adjustedPoints[next].y - center.y,
                        adjustedPoints[next].x - center.x
                    )

                    // 创建垂直于路径的控制柄
                    let handleLength = radius * 0.33  // 控制柄长度影响曲线的弯曲程度

                    // 计算第一个控制点
                    let control1 = CGPoint(
                        x: adjustedPoints[i].x + cos(currentAngle + .pi / 2) * handleLength,
                        y: adjustedPoints[i].y + sin(currentAngle + .pi / 2) * handleLength
                    )

                    // 计算第二个控制点
                    let control2 = CGPoint(
                        x: adjustedPoints[next].x + cos(nextAngle - .pi / 2) * handleLength,
                        y: adjustedPoints[next].y + sin(nextAngle - .pi / 2) * handleLength
                    )

                    // 添加三次贝塞尔曲线
                    path.addCurve(
                        to: adjustedPoints[next],
                        control1: control1,
                        control2: control2
                    )
                }

                // 使用指定颜色填充路径
                context.fill(path, with: .color(color))
            }
        }
        .animation(.spring(), value: points) // 添加弹性动画效果
    }
}

/// 预览视图
#Preview {
    WavyBlobView(color: .cc.primary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.cc.foreground)
}
