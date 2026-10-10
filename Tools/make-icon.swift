import AppKit

// A deterministic, seedable pseudo-random generator so the hand-drawn
// strokes below are reproducible across builds (xorshift32).
struct SeededRandom {
    private var state: UInt32
    init(seed: UInt32) { state = seed == 0 ? 1 : seed }
    private mutating func next() -> UInt32 {
        state ^= state << 13
        state ^= state >> 17
        state ^= state << 5
        return state
    }
    mutating func uniform(_ lo: Double, _ hi: Double) -> Double {
        lo + Double(next() % 1_000_000) / 1_000_000 * (hi - lo)
    }
    mutating func sign() -> Double {
        next() % 2 == 0 ? 1 : -1
    }
}

func rotated(_ x: Double, _ y: Double, degrees: Double) -> CGPoint {
    let a = degrees * .pi / 180
    return CGPoint(x: x * cos(a) - y * sin(a), y: x * sin(a) + y * cos(a))
}

struct Stroke {
    let start: CGPoint
    let control: CGPoint
    let end: CGPoint
    let width: CGFloat
    let opacity: CGFloat
}

var rng = SeededRandom(seed: 7)

func sketchyStroke(_ x1: Double, _ y1: Double, _ x2: Double, _ y2: Double, width: Double, passes: Int = 2, bowAmount: Double = 3) -> [Stroke] {
    var strokes: [Stroke] = []
    for _ in 0..<passes {
        let jx1 = x1 + rng.uniform(-1.2, 1.2), jy1 = y1 + rng.uniform(-1.2, 1.2)
        let jx2 = x2 + rng.uniform(-1.2, 1.2), jy2 = y2 + rng.uniform(-1.2, 1.2)
        let dx = jx2 - jx1, dy = jy2 - jy1
        let length = max(sqrt(dx * dx + dy * dy), 0.0001)
        let nx = -dy / length, ny = dx / length
        let bow = rng.uniform(bowAmount * 0.4, bowAmount * 1.6) * rng.sign()
        let mx = (jx1 + jx2) / 2 + nx * bow, my = (jy1 + jy2) / 2 + ny * bow
        let w = width * rng.uniform(0.85, 1.15)
        let o = rng.uniform(0.55, 1.0)
        strokes.append(Stroke(start: CGPoint(x: jx1, y: jy1), control: CGPoint(x: mx, y: my), end: CGPoint(x: jx2, y: jy2), width: w, opacity: o))
    }
    return strokes
}

// A hand-drawn witch's broom: the handle points toward the upper right,
// the bristles fan out toward the lower left, built from many short
// jittered pencil strokes rather than clean vector shapes.
func broomStrokes() -> [Stroke] {
    var strokes: [Stroke] = []

    let handleAngle = -34.0
    let handleLength = 300.0
    let baseWidth = 13.0
    let tipWidth = baseWidth * 0.55
    let perp = handleAngle + 90

    let tip = rotated(handleLength, 0, degrees: handleAngle)
    let b1 = rotated(baseWidth / 2, 0, degrees: perp)
    let b2 = rotated(-baseWidth / 2, 0, degrees: perp)
    let tipOffset1 = rotated(tipWidth / 2, 0, degrees: perp)
    let tipOffset2 = rotated(-tipWidth / 2, 0, degrees: perp)
    let t1 = CGPoint(x: tip.x + tipOffset1.x, y: tip.y + tipOffset1.y)
    let t2 = CGPoint(x: tip.x + tipOffset2.x, y: tip.y + tipOffset2.y)

    strokes += sketchyStroke(b1.x, b1.y, t1.x, t1.y, width: 3.0, bowAmount: 4)
    strokes += sketchyStroke(b2.x, b2.y, t2.x, t2.y, width: 3.0, bowAmount: 4)
    strokes += sketchyStroke(t1.x, t1.y, t2.x, t2.y, width: 2.6, bowAmount: 2)

    let ticks = 7
    for i in 1..<ticks {
        let t = Double(i) / Double(ticks)
        let p = rotated(handleLength * t, 0, degrees: handleAngle)
        let w = baseWidth + (tipWidth - baseWidth) * t
        let h1 = rotated(w * 0.35, 0, degrees: perp)
        let h2 = rotated(-w * 0.35, 0, degrees: perp)
        strokes += sketchyStroke(p.x + h1.x, p.y + h1.y, p.x + h2.x, p.y + h2.y, width: 1.6, passes: 1, bowAmount: 1.5)
    }

    for (i, r) in [10.0, 16.0, 22.0].enumerated() {
        let c = rotated(r * 0.4, 0, degrees: handleAngle)
        let bw = 15.0 - Double(i) * 1.5
        let w1 = rotated(bw, 0, degrees: perp)
        let w2 = rotated(-bw, 0, degrees: perp)
        strokes += sketchyStroke(c.x + w1.x, c.y + w1.y, c.x + w2.x, c.y + w2.y, width: 3.4, bowAmount: 5)
    }

    let bristleAngle = handleAngle + 180
    let bristleSpread = 44.0
    let bristleCount = 31
    for i in 0..<bristleCount {
        let t = Double(i) / Double(bristleCount - 1)
        var angle = bristleAngle - bristleSpread / 2 + bristleSpread * t
        angle += rng.uniform(-3, 3)
        let length = rng.uniform(150, 210)
        let startRadius = rng.uniform(16, 26)
        let start = rotated(startRadius, 0, degrees: handleAngle)
        let end = rotated(length, 0, degrees: angle)
        let width = rng.uniform(1.8, 3.2)
        strokes += sketchyStroke(start.x, start.y, end.x, end.y, width: width, bowAmount: rng.uniform(3, 9))
    }

    return strokes
}

let size: CGFloat = 1024
let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
    let inset = rect.insetBy(dx: size * 0.06, dy: size * 0.06)
    let card = NSBezierPath(roundedRect: inset, xRadius: size * 0.22, yRadius: size * 0.22)
    NSColor(calibratedWhite: 0.99, alpha: 1).setFill()
    card.fill()

    let strokes = broomStrokes()
    var minX = Double.greatestFiniteMagnitude, maxX = -Double.greatestFiniteMagnitude
    var minY = Double.greatestFiniteMagnitude, maxY = -Double.greatestFiniteMagnitude
    for s in strokes {
        for p in [s.start, s.control, s.end] {
            minX = min(minX, Double(p.x)); maxX = max(maxX, Double(p.x))
            minY = min(minY, Double(p.y)); maxY = max(maxY, Double(p.y))
        }
    }
    let drawW = maxX - minX, drawH = maxY - minY
    let margin = size * 0.17
    let scale = min((Double(size) - 2 * margin) / drawW, (Double(size) - 2 * margin) / drawH)
    let cx = (minX + maxX) / 2, cy = (minY + maxY) / 2
    let tx = Double(size) / 2 - cx * scale
    let ty = Double(size) / 2 - cy * scale

    for s in strokes {
        let path = NSBezierPath()
        let start = CGPoint(x: s.start.x * scale + tx, y: s.start.y * scale + ty)
        let control = CGPoint(x: s.control.x * scale + tx, y: s.control.y * scale + ty)
        let end = CGPoint(x: s.end.x * scale + tx, y: s.end.y * scale + ty)
        path.move(to: start)
        path.curve(to: end, controlPoint1: control, controlPoint2: control)
        path.lineWidth = s.width * scale
        path.lineCapStyle = .round
        NSColor(calibratedWhite: 0.08, alpha: s.opacity).setStroke()
        path.stroke()
    }
    return true
}

let tiff = image.tiffRepresentation!
let png = NSBitmapImageRep(data: tiff)!.representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
