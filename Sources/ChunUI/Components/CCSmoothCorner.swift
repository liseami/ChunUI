/**
 * [INPUT]: 依赖 CoreGraphics 的 CGMutablePath、SwiftUI 的 Shape。
 * [OUTPUT]: 提供 CCSmoothCorner、CCSmoothCornerShape。CCSmoothCorner是平滑圆角的纯几何：一角的参数 corner、右上角的关键点与采样点、闭合轮廓 path。CCSmoothCornerShape是SwiftUI 外壳。
 * [POS]: Components 的连续曲率圆角。平滑度 0 是普通圆角，1 是完整超椭圆。Chat0IM 气泡以平滑度 0.6 作体，再在底边接尾巴。Android 同名件与这条曲线逐点相同
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import CoreGraphics
import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Figma corner smoothing 构造（公开算法，参照 figma-squircle，MIT；此处为 Swift 自写）
// 一角 = 直边 → 三次贝塞尔从零曲率爬升 → 一段半径 r 的圆弧 → 对称的贝塞尔回落到另一条直边。
// 平滑度 s ∈ [0, 1]：圆弧张角 90°(1 − s)，曲线从角点沿每条边延伸 p = (1 + s) r；s = 0 即普通圆角，s = 1 弧段缩成一点、整角是完整超椭圆。
// 收敛（preserveSmoothing，与 Figma 编辑器同）：半径先夹到短边一半；p 超出这个预算时保住平滑度与圆弧，只压缩贝塞尔的 a / b，p 夹到预算。
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

nonisolated public enum CCSmoothCorner {
    /// 一角的参数（四角同值）：p 曲线沿边的总长；a、b、c、d 是贝塞尔的分段（见 figma 博文图 11.1）；arc 是圆弧在每个轴上的投影长
    public struct Corner: Equatable, Sendable {
        public let radius: CGFloat
        public let smoothing: CGFloat
        public let p: CGFloat
        public let a: CGFloat
        public let b: CGFloat
        public let c: CGFloat
        public let d: CGFloat
        public let arc: CGFloat
    }

    public static func corner(width: CGFloat, height: CGFloat, radius: CGFloat, smoothing: CGFloat) -> Corner {
        let budget = max(0, min(width, height) / 2)
        let s = min(1, max(0, smoothing))
        let r = min(max(0, radius), budget)
        var p = (1 + s) * r
        let deg = CGFloat.pi / 180
        let arcMeasure = 90 * (1 - s)
        let arc = sin(arcMeasure / 2 * deg) * r * 2.squareRoot()
        let alpha = (90 - arcMeasure) / 2
        let p3ToP4 = r * tan(alpha / 2 * deg)
        let beta = 45 * s
        let c = p3ToP4 * cos(beta * deg)
        let d = c * tan(beta * deg)
        var b = (p - arc - c - d) / 3
        var a = 2 * b
        // ── 预算不够：保平滑度，压贝塞尔（a 至少留 1/6，免得曲线打折）
        if p > budget {
            let room = budget - d - arc - c
            b = min(b, room - room / 6)
            a = room - b
            p = budget
        }
        return Corner(radius: r, smoothing: s, p: p, a: a, b: b, c: c, d: d, arc: arc)
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 一角的点：沿行进方向 u 进角、转向 v 出角（顶点 V）；右上角 u = (1, 0)、v = (0, 1)，y 朝下
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    /// 一角的八个关键点：进角切点、两个控制点、弧起点、弧终点、两个控制点、出角切点；外加圆心
    struct Points {
        let keys: [CGPoint]
        let center: CGPoint
    }

    static func points(_ k: Corner, vertex v0: CGPoint, u: CGVector, v: CGVector) -> Points {
        func at(_ du: CGFloat, _ dv: CGFloat) -> CGPoint { CGPoint(x: v0.x + u.dx * du + v.dx * dv, y: v0.y + u.dy * du + v.dy * dv) }
        let lead = k.a + k.b + k.c
        return Points(keys: [
            at(-k.p, 0), at(-k.p + k.a, 0), at(-k.p + k.a + k.b, 0), at(-k.p + lead, k.d),
            at(-k.d, k.p - lead), at(0, k.p - k.a - k.b), at(0, k.p - k.a), at(0, k.p),
        ], center: at(-k.radius, k.radius))
    }

    /// 右上角的八个关键点（用例表）
    public static func topRightKeys(width: CGFloat, height: CGFloat, radius: CGFloat, smoothing: CGFloat) -> [CGPoint] {
        points(corner(width: width, height: height, radius: radius, smoothing: smoothing), vertex: CGPoint(x: width, y: 0), u: CGVector(dx: 1, dy: 0), v: CGVector(dx: 0, dy: 1)).keys
    }

    /// 右上角弧段的起止角（度，y 朝下、从 +x 量起）：−90 + 45s 到 −45s
    public static func topRightArcAngles(smoothing: CGFloat) -> (CGFloat, CGFloat) {
        let s = min(1, max(0, smoothing))
        return (-90 + 45 * s, -45 * s)
    }

    /// 右上角曲线上的三个采样点：爬升贝塞尔 t = 0.5、圆弧中点（45° 对角线上）、回落贝塞尔 t = 0.5
    public static func topRightSamples(width: CGFloat, height: CGFloat, radius: CGFloat, smoothing: CGFloat) -> [CGPoint] {
        let k = corner(width: width, height: height, radius: radius, smoothing: smoothing)
        let q = points(k, vertex: CGPoint(x: width, y: 0), u: CGVector(dx: 1, dy: 0), v: CGVector(dx: 0, dy: 1))
        let r = k.radius / 2.squareRoot()
        return [cubic(q.keys[0], q.keys[1], q.keys[2], q.keys[3], 0.5), CGPoint(x: q.center.x + r, y: q.center.y - r),
                cubic(q.keys[4], q.keys[5], q.keys[6], q.keys[7], 0.5)]
    }

    public static func cubic(_ p0: CGPoint, _ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint, _ t: CGFloat) -> CGPoint {
        let m = 1 - t
        let w = (m * m * m, 3 * m * m * t, 3 * m * t * t, t * t * t)
        return CGPoint(x: w.0 * p0.x + w.1 * p1.x + w.2 * p2.x + w.3 * p3.x, y: w.0 * p0.y + w.1 * p1.y + w.2 * p2.y + w.3 * p3.y)
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 闭合轮廓：从上边左切点起顺时针（y 朝下）走四角；弧用 addArc 按圆心与两端点的角画
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    public static func path(in rect: CGRect, radius: CGFloat, smoothing: CGFloat) -> CGPath {
        let path = CGMutablePath()
        guard rect.width > 0, rect.height > 0 else { return path }
        let k = corner(width: rect.width, height: rect.height, radius: radius, smoothing: smoothing)
        guard k.radius > 0 else {
            path.addRect(rect)
            return path
        }
        let corners: [(CGPoint, CGVector, CGVector)] = [
            (CGPoint(x: rect.maxX, y: rect.minY), CGVector(dx: 1, dy: 0), CGVector(dx: 0, dy: 1)),
            (CGPoint(x: rect.maxX, y: rect.maxY), CGVector(dx: 0, dy: 1), CGVector(dx: -1, dy: 0)),
            (CGPoint(x: rect.minX, y: rect.maxY), CGVector(dx: -1, dy: 0), CGVector(dx: 0, dy: -1)),
            (CGPoint(x: rect.minX, y: rect.minY), CGVector(dx: 0, dy: -1), CGVector(dx: 1, dy: 0)),
        ]
        for (i, (vertex, u, v)) in corners.enumerated() {
            if i == 0 { path.move(to: points(k, vertex: vertex, u: u, v: v).keys[0]) }
            append(k, vertex: vertex, u: u, v: v, to: path)
        }
        path.closeSubpath()
        return path
    }

    /// 把一角接进路径：直线到进角切点 → 爬升贝塞尔 → 圆弧 → 回落贝塞尔，停在出角切点；trim 给了就在回落贝塞尔的参数 trim 处停（气泡在这里接尾巴的倒角）。
    public static func append(_ k: Corner, vertex: CGPoint, u: CGVector, v: CGVector, to path: CGMutablePath, trim: CGFloat = 1) {
        let q = points(k, vertex: vertex, u: u, v: v)
        let p = q.keys
        path.addLine(to: p[0])
        guard k.radius > 0 else { return }
        path.addCurve(to: p[3], control1: p[1], control2: p[2])
        let start = atan2(p[3].y - q.center.y, p[3].x - q.center.x)
        let end = atan2(p[4].y - q.center.y, p[4].x - q.center.x)
        // 角度沿行进方向递增（y 朝下的顺时针）；跨 ±π 时把终角补一圈
        path.addArc(center: q.center, radius: k.radius, startAngle: start, endAngle: end < start ? end + 2 * .pi : end, clockwise: false)
        guard trim < 1 else { return path.addCurve(to: p[7], control1: p[5], control2: p[6]) }
        let head = split([p[4], p[5], p[6], p[7]], at: trim).head
        path.addCurve(to: head[3], control1: head[1], control2: head[2])
    }

    /// 一角回落贝塞尔的四个控制点（终点即出角切点）：气泡按它找尾巴倒角的起点
    public static func tail(_ k: Corner, vertex: CGPoint, u: CGVector, v: CGVector) -> [CGPoint] {
        Array(points(k, vertex: vertex, u: u, v: v).keys[4...7])
    }

    /// 一角的三段三次（爬升贝塞尔 · 圆弧的三次近似 · 回落贝塞尔），每段四个控制点、首段起于进角切点、末段止于出角切点；
    /// 圆弧的控制柄 r · 4/3 · tan(θ/4) 沿两端切线——与 Android 的 CCSmoothCorner.cubics 同一组数。群聊气泡在尾巴那只角上按它找凹口、截断续画
    static func cubics(_ k: Corner, vertex: CGPoint, u: CGVector, v: CGVector) -> [[CGPoint]] {
        guard k.radius > 0 else { return [] }
        let q = points(k, vertex: vertex, u: u, v: v)
        let p = q.keys
        let a0 = atan2(p[3].y - q.center.y, p[3].x - q.center.x)
        let theta = 90 * (1 - k.smoothing) * .pi / 180
        let a1 = a0 + theta
        let h = k.radius * 4 / 3 * tan(theta / 4)
        return [
            [p[0], p[1], p[2], p[3]],
            [p[3], CGPoint(x: p[3].x - h * sin(a0), y: p[3].y + h * cos(a0)), CGPoint(x: p[4].x + h * sin(a1), y: p[4].y - h * cos(a1)), p[4]],
            [p[4], p[5], p[6], p[7]],
        ]
    }

    /// de Casteljau：三次贝塞尔（四个控制点）在 t 处一分为二
    public static func split(_ c: [CGPoint], at t: CGFloat) -> (head: [CGPoint], tail: [CGPoint]) {
        func lerp(_ a: CGPoint, _ b: CGPoint) -> CGPoint { CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t) }
        let a = lerp(c[0], c[1]), b = lerp(c[1], c[2]), e = lerp(c[2], c[3])
        let d = lerp(a, b), f = lerp(b, e)
        let m = lerp(d, f)
        return ([c[0], a, d, m], [m, f, e, c[3]])
    }

    /// 单调的量 value(t) 在 [0, 1] 上取到 target 的参数（二分，value 须单调）
    public static func solve(_ target: CGFloat, _ value: (CGFloat) -> CGFloat) -> CGFloat {
        var lo: CGFloat = 0, hi: CGFloat = 1
        let rising = value(1) >= value(0)
        for _ in 0 ..< 24 {
            let mid = (lo + hi) / 2
            if (value(mid) < target) == rising { lo = mid } else { hi = mid }
        }
        return (lo + hi) / 2
    }
}

/// SwiftUI 外壳：半径与平滑度给定的平滑圆角矩形
public struct CCSmoothCornerShape: Shape {
    public let radius: CGFloat
    public let smoothing: CGFloat

    public init(radius: CGFloat, smoothing: CGFloat) {
        self.radius = radius
        self.smoothing = smoothing
    }

    public func path(in rect: CGRect) -> Path { Path(CCSmoothCorner.path(in: rect, radius: radius, smoothing: smoothing)) }
}
