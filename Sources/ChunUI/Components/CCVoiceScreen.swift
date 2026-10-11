/**
 * [INPUT]: 依赖 simd 的点表、CoreGraphics 的点心
 * [OUTPUT]: 提供 CCVoiceScreen。列式声纹、熄点呼吸、转文字的点阵字行、发送收拢、开关机光圈 CRT、3×5 点阵数字
 * [POS]: Components 的凹屏屏芯。CCVoiceScreenView 每帧调 step，把 dots 交给 CCVoiceDots.metal。颜色不在这里
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import CoreGraphics
import Foundation
import simd

public struct CCVoiceScreen: Sendable {
    public static let cancelSquash: Float = 0.4
    public static let headWhite: Float = 0.6
    public static let headSpan: Float = 2
    public static let textRows = 2
    public static let textGapRows = 1
    public static let textMargin = 2
    public static let textInk: Float = 0.55

    private static let pitch: CGFloat = 6
    private static let idle: Float = 0.08
    private static let breathAmp: Float = 0.05
    private static let scroll = 24
    private static let attack = 0.04
    private static let decay = 0.18
    private static let shimmer = 1.2
    private static let textLines = 3
    private static let screenOn = 0.2
    private static let screenOff = 0.2
    private static let digitPitch: CGFloat = 3
    private static let breatheHalf = 2.8
    private static let sweepStops: [(at: Double, light: Double)] = [(0.32, 0), (0.44, 0.4), (0.5, 1), (0.56, 0.4), (0.68, 0)]

    public let cols: Int
    public let rows: Int
    public let origin: CGPoint
    public private(set) var dots: [SIMD4<Float>]

    public var dangerTarget: Float = 0
    public var textTarget: Float = 0
    public private(set) var danger: Float = 0
    public private(set) var text: Float = 0
    public var still = false

    private var lit: [Float]
    private var breathPhase: [Float]
    private var textMask: [Float]
    private var columnLight: [Float]
    private var history: [Float]
    private var head = 0
    private var live: Float = 0
    private var latest: Float = 0
    private var clock: Double = 0

    public init(size: CGSize, seed: Int) {
        let pitch = Self.pitch
        let w = max(1, Int(size.width / pitch))
        let h = max(2, Int(size.height / pitch) / 2 * 2)
        let n = w * h
        cols = w
        rows = h
        origin = CGPoint(x: (size.width - CGFloat(w) * pitch) / 2 + pitch / 2, y: (size.height - CGFloat(h) * pitch) / 2 + pitch / 2)
        dots = Array(repeating: .zero, count: n)
        lit = Array(repeating: 0, count: n)
        history = Array(repeating: 0, count: w)
        columnLight = Array(repeating: 0, count: w)
        breathPhase = (0..<n).map { i in Self.hash(Float(i % w), Float(i / w)) * Float(Self.breatheHalf * 2) }
        textMask = Self.mask(cols: w, rows: h, seed: Float(seed % 997))
    }

    public mutating func push(_ level: Float) {
        latest = min(1, max(0, level))
        live = max(live, latest)
    }

    public mutating func step(_ dt: Double, time t: Double, wake: Float, collapse: Float = 0) {
        let slot = 1 / Double(Self.scroll)
        if still {
            clock = 0
            live = latest
        } else {
            clock += dt
            if clock > slot * Double(cols) { clock = slot * Double(cols) }
            while clock >= slot {
                clock -= slot
                head = (head + 1) % cols
                history[head] = live
                live = latest
            }
        }
        let fade = Float(1 - exp(-dt / Self.decay))
        danger += (dangerTarget - danger) * fade
        text += (textTarget - text) * fade
        let phase = Float((t / Self.shimmer).truncatingRemainder(dividingBy: 1))
        let center = -0.2 + 1.4 * phase
        for c in 0..<cols {
            let u = (Float(c) + 0.5) / Float(cols)
            columnLight[c] = still ? 0 : Float(Self.light(at: Double(0.5 + u - center)))
        }
        let up = Float(1 - exp(-dt / Self.attack))
        let down = fade
        let flash = sin(.pi * collapse)
        for i in lit.indices {
            let c = i % cols
            let k = cols - 1 - c
            let target = goal(i, wake: wake, collapse: collapse)
            lit[i] += (target - lit[i]) * (target > lit[i] ? up : down)
            let awake = Self.awake(c, cols: cols, wake: wake)
            let breath = Float(Self.breath(t + Double(breathPhase[i])))
            let idle = (Self.idle + Self.breathAmp * (2 * breath - 1)) * awake
            let headHeat = Self.headWhite * max(0, 1 - Float(k) / Self.headSpan)
            let heat = min(1, headHeat * (1 - text) + columnLight[c] * textMask[i] * text + flash)
            dots[i] = SIMD4(min(1, lit[i] * (1 + flash)), idle, heat, 0)
        }
    }

    private func goal(_ i: Int, wake: Float, collapse: Float) -> Float {
        let c = i % cols
        let r = i / cols
        let k = cols - 1 - c
        let volume = level(age: collapse > 0 ? Float(k) / max(1 - collapse, 0.001) : Float(k))
        let squash = 1 + (Self.cancelSquash - 1) * danger
        let n = volume * squash * Float(rows) / 2
        let d = abs(Float(r) + 0.5 - Float(rows) / 2)
        let voice = min(1, max(0, n - (d - 0.5)))
        let line = textMask[i] * (Self.textInk + (1 - Self.textInk) * columnLight[c])
        return (voice * (1 - text) + line * text) * Self.awake(c, cols: cols, wake: wake)
    }

    private func level(age: Float) -> Float {
        if still { return live }
        let a = Int(age)
        if a == 0 { return live }
        guard a < cols else { return 0 }
        return history[(head - (a - 1) + cols * 2) % cols]
    }

    private static func awake(_ c: Int, cols: Int, wake: Float) -> Float {
        min(1, max(0, wake * Float(cols) - Float(c)))
    }

    private static func mask(cols: Int, rows: Int, seed: Float) -> [Float] {
        var mask = Array(repeating: Float(0), count: cols * rows)
        let lines = textLines
        let band = lines * textRows + (lines - 1) * textGapRows
        let top = max(0, (rows - band) / 2)
        let span = max(0, cols - textMargin * 2)
        for line in 0..<lines {
            let h = hash(Float(line + 1), seed)
            let share: Float = line == lines - 1 ? 0.35 + 0.3 * h : 0.6 + 0.35 * h
            let length = Int(Float(span) * share)
            let y = top + line * (textRows + textGapRows)
            for c in textMargin..<(textMargin + length) {
                let gap = c > textMargin && c < textMargin + length - 1 && hash(Float(c), Float(line * 7) + seed) > 0.84
                guard !gap else { continue }
                for r in y..<min(rows, y + textRows) { mask[r * cols + c] = 1 }
            }
        }
        return mask
    }

    public struct CRT: Equatable, Sendable {
        public var openY: Float
        public var openX: Float
        public var beam: Float
        public var wake: Float

        public static let off = CRT(openY: 0, openX: 1, beam: 0, wake: 0)
        public static let on = CRT(openY: 1, openX: 1, beam: 0, wake: 1)

        public static func at(_ t: Double, on: Double?, off: Double?) -> CRT {
            guard let on, t >= on else { return .off }
            let a = Float(min(1, (t - on) / screenOn))
            let w = min(1, max(0, a * 2 - 1))
            var crt = CRT(openY: 1 - (1 - a) * (1 - a), openX: 1, beam: 1 - a, wake: w)
            guard let off, t >= off else { return crt }
            let b = Float(min(1, (t - off) / screenOff))
            if b < 0.5 {
                let s = b * 2
                crt.openY *= 1 - s * s
                crt.beam = max(crt.beam, s)
            } else {
                let s = (b - 0.5) * 2
                crt.openY = 0
                crt.openX = 1 - s * s
                crt.beam = 1
            }
            return crt
        }
    }

    private static let glyphs: [Character: [String]] = [
        "0": ["111", "101", "101", "101", "111"], "1": ["010", "110", "010", "010", "111"],
        "2": ["111", "001", "111", "100", "111"], "3": ["111", "001", "111", "001", "111"],
        "4": ["101", "101", "111", "001", "001"], "5": ["111", "100", "111", "001", "111"],
        "6": ["111", "100", "111", "101", "111"], "7": ["111", "001", "001", "001", "001"],
        "8": ["111", "101", "111", "101", "111"], "9": ["111", "101", "111", "001", "111"],
        ":": ["0", "1", "0", "1", "0"],
    ]

    public static func digits(_ text: String, at: CGPoint, right: Bool = false) -> [CGPoint] {
        let pitch = digitPitch
        let shapes = text.compactMap { glyphs[$0] }
        let width = shapes.reduce(0) { $0 + ($1.first?.count ?? 0) } + max(0, shapes.count - 1)
        var x = right ? at.x - CGFloat(width - 1) * pitch : at.x
        var out: [CGPoint] = []
        for shape in shapes {
            let w = shape.first?.count ?? 0
            for (r, row) in shape.enumerated() {
                for (c, bit) in row.enumerated() where bit == "1" {
                    out.append(CGPoint(x: x + CGFloat(c) * pitch, y: at.y + CGFloat(r) * pitch))
                }
            }
            x += CGFloat(w + 1) * pitch
        }
        return out
    }

    public static func clock(_ seconds: Int) -> String {
        "\(seconds / 60):" + String(format: "%02d", seconds % 60)
    }

    private static func hash(_ x: Float, _ y: Float) -> Float {
        func fract(_ v: Float) -> Float { v - v.rounded(.down) }
        var a = fract(x * 0.1031), b = fract(y * 0.1031), c = fract(x * 0.1031)
        let d = a * (b + 33.33) + b * (c + 33.33) + c * (a + 33.33)
        a += d; b += d; c += d
        return fract((a + b) * c)
    }

    private static func breath(_ t: Double) -> Double {
        let phase = (t / breatheHalf).truncatingRemainder(dividingBy: 2)
        let linear = phase <= 1 ? phase : 2 - phase
        return (1 - cos(linear * .pi)) / 2
    }

    private static func light(at g: Double) -> Double {
        guard let first = sweepStops.first, let last = sweepStops.last, g > first.at, g < last.at else { return 0 }
        for (a, b) in zip(sweepStops, sweepStops.dropFirst()) where g <= b.at {
            return a.light + (b.light - a.light) * (g - a.at) / (b.at - a.at)
        }
        return 0
    }
}
