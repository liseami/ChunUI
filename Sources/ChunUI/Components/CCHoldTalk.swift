/**
 * [INPUT]: 依赖 CoreGraphics 的框与点
 * [OUTPUT]: 提供 CCHoldZone、CCHoldSlab、CCHoldSpring。CCHoldSlab 给出板上沿、整板、凹屏、提示行、孔阵、左右垫、按进度下移的框，以及 zone 的迟滞和手指离垫的远近。CCHoldSpring 是临界阻尼弹簧，升起 0.26、落下 0.2
 * [POS]: Components 的按住说话几何。Chat0IM 录制时用它判松手落点。板高 252，回中 12，换边 12，与 Cromma chat.hold 同一组数
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import CoreGraphics

public enum CCHoldZone: Sendable, Equatable {
    case center
    case cancel
    case transcribe
}

public struct CCHoldSlab: Equatable, Sendable {
    public var size: CGSize
    public var origin: CGRect
    /// 提示一行的行高
    public var hintLine: CGFloat

    public init(size: CGSize, origin: CGRect, hintLine: CGFloat = 20) {
        self.size = size
        self.origin = origin
        self.hintLine = hintLine
    }

    /// 升起后板的上沿。按下处恒在中区
    public var top: CGFloat { min(size.height - 252, origin.minY - 12) }

    public var midX: CGFloat { size.width / 2 }

    /// 凹屏：离板边 14、高 108，圆角与板同心
    public var screen: CGRect {
        let board = full
        return CGRect(x: board.minX + 14, y: board.minY + 14, width: max(0, board.width - 28), height: 108)
    }

    public var screenRadius: CGFloat { max(0, 40 - 14) }

    /// 提示一行：屏下 12，与屏同宽
    public var hint: CGRect {
        let face = screen
        return CGRect(x: face.minX, y: face.maxY + 12, width: face.width, height: hintLine)
    }

    /// 孔阵：提示之下 12 到屏底，与屏同宽
    public var grille: CGRect {
        let row = hint
        let y = row.maxY + 12
        return CGRect(x: row.minX, y: y, width: row.width, height: max(0, size.height - y))
    }

    /// 升起后的板。左右各让 12，底沿再往屏外延 64
    public var full: CGRect {
        CGRect(x: 12, y: top, width: max(0, size.width - 24), height: size.height - top + 64)
    }

    /// 两垫在板上沿之上 14，高 64，中间留 12
    public var cancelPad: CGRect {
        let board = full
        let width = max(0, board.width - 12) / 2
        return CGRect(x: board.minX, y: top - 14 - 64, width: width, height: 64)
    }

    public var transcribePad: CGRect {
        let cancel = cancelPad
        return CGRect(x: cancel.maxX + 12, y: cancel.minY, width: cancel.width, height: cancel.height)
    }

    /// 未进垫时，近的那块垫按这个远近放大到 1.03。0 在按下处，1 在板上沿
    public func proximity(for point: CGPoint) -> (cancel: CGFloat, transcribe: CGFloat) {
        let span = max(1, origin.midY - top)
        let near = min(1, max(0, (origin.midY - point.y) / span))
        return point.x < midX ? (near, 0) : (0, near)
    }

    /// 升起的行程：屏底到板上沿
    public var travel: CGFloat { size.height - top }

    /// 进度 0 整块在屏底之下，1 到落定位置
    public func shifted(_ rect: CGRect, progress: CGFloat) -> CGRect {
        rect.offsetBy(dx: 0, dy: (1 - progress) * travel)
    }

    /// 中区里 y 小于板上沿才进垫。垫区里 y 回到 top+12 才回中。换边要越过中线 12
    public func zone(for p: CGPoint, from previous: CCHoldZone) -> CCHoldZone {
        let mid = midX
        switch previous {
        case .center:
            guard p.y < top else { return .center }
            return p.x < mid ? .cancel : .transcribe
        case .cancel:
            guard p.y < top + 12 else { return .center }
            return p.x >= mid + 12 ? .transcribe : .cancel
        case .transcribe:
            guard p.y < top + 12 else { return .center }
            return p.x < mid - 12 ? .cancel : .transcribe
        }
    }
}

/// 阻尼比 1、响应时长的弹簧。升起用 0.26，落下用 0.2
public struct CCHoldSpring: Equatable, Sendable {
    public var value: CGFloat
    public var velocity: CGFloat = 0
    public var target: CGFloat
    public var damping: Double
    public var response: Double

    public init(_ value: CGFloat, damping: Double = 1, response: Double = 0.26) {
        self.value = value
        self.target = value
        self.damping = damping
        self.response = response
    }

    public var settled: Bool { abs(value - target) < 0.001 && abs(velocity) < 0.01 }

    public mutating func aim(_ target: CGFloat, response: Double? = nil) {
        self.target = target
        if let response { self.response = response }
    }

    public mutating func snap(_ value: CGFloat) {
        self.value = value
        target = value
        velocity = 0
    }

    public mutating func step(_ dt: Double) {
        guard !settled else { return snap(target) }
        let k = pow(2 * Double.pi / max(response, 0.01), 2)
        let c = 4 * Double.pi * damping / max(response, 0.01)
        let n = max(1, Int((dt * 240).rounded(.up)))
        let h = dt / Double(n)
        var x = Double(value)
        var v = Double(velocity)
        let t = Double(target)
        for _ in 0..<n {
            v += (-k * (x - t) - c * v) * h
            x += v * h
        }
        value = CGFloat(x)
        velocity = CGFloat(v)
    }
}
