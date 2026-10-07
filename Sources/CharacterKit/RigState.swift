import Foundation
import CoreGraphics

/// Per-view animation state. It is a plain class (not ObservableObject) on purpose:
/// it is mutated inside the Canvas draw pass every frame, and that must not
/// trigger SwiftUI invalidation.
final class RigState {

    // Inputs set by the view
    var baseMood: String = "neutral"
    var touching = false
    var moved = false
    var touchStart: TimeInterval = 0
    var lookTarget: CGPoint? = nil
    var heldReaction: String? = nil

    // Reaction override (tap / long press)
    private var overrideName: String? = nil
    private var overrideUntil: TimeInterval = 0

    var activeMood: String {
        if let override = overrideName, RigState.now < overrideUntil {
            return override
        }
        return baseMood
    }

    // Live outputs read by the renderer
    private(set) var pose = ExpressionParams()    // spring-driven, may overshoot slightly
    private(set) var look = CGPoint.zero          // -1...1 on both axes
    private(set) var blink: Double = 1            // 1 = open, 0 = closed (multiplier)
    private(set) var breath: Double = 0           // -1...1
    private(set) var squash: Double = 0           // spring-driven tap bounce
    private(set) var time: TimeInterval = 0
    private(set) var reduceMotion = false

    // Spring channels, in the order of ExpressionParams.values:
    // eyeOpen, lidTilt, mouthCurve, mouthOpen, mouthWidth, bodySquash
    // Eyes are snappy and barely overshoot; the mouth lags a beat and overshoots a little;
    // the body is the loosest. That staggering is what makes the face feel alive.
    private static let stiffness: [Double]    = [260, 200, 170, 150, 150, 120]
    private static let dampingRatio: [Double] = [0.75, 0.6, 0.5, 0.5, 0.5, 0.45]

    private var poseValues = [Double](repeating: 0, count: 6)
    private var poseVelocity = [Double](repeating: 0, count: 6)

    // Internals
    private var squashVelocity: Double = 0
    private var lastTime: TimeInterval? = nil
    private var nextBlink: TimeInterval = 0
    private var blinkStart: TimeInterval = -1
    private var driftTarget = CGPoint.zero
    private var nextDrift: TimeInterval = 0
    private var started = false

    static var now: TimeInterval { Date().timeIntervalSinceReferenceDate }

    // MARK: Triggers (called from gesture handlers on the main thread)

    func react(_ expression: String, seconds: Double) {
        overrideName = expression
        overrideUntil = RigState.now + seconds
    }

    func bump(_ amount: Double) {
        squashVelocity += amount
    }

    // MARK: Per-frame update

    func step(now: TimeInterval, spec: CharacterSpec, reduceMotion: Bool) {
        if !started {
            started = true
            nextBlink = now + 1.5
            nextDrift = now + 1.0
            let start = spec.expressions[baseMood] ?? spec.expressions["neutral"] ?? ExpressionParams()
            poseValues = start.values
            poseVelocity = [Double](repeating: 0, count: 6)
            pose = start
        }

        let dt = min(max(now - (lastTime ?? now), 0), 1.0 / 20.0)
        lastTime = now
        time = now
        self.reduceMotion = reduceMotion

        // 1. Expression target (a reaction override wins while it is active)
        var name = baseMood
        if let override = overrideName, now < overrideUntil {
            name = override
        }
        let target = (spec.expressions[name] ?? spec.expressions["neutral"] ?? ExpressionParams()).values

        // 2. Damped springs, integrated in small fixed sub-steps so stiff springs stay stable
        let substeps = max(1, Int(ceil(dt / (1.0 / 120.0))))
        let h = dt / Double(substeps)
        for _ in 0..<substeps {
            for i in 0..<6 {
                let k = RigState.stiffness[i]
                let c = 2 * RigState.dampingRatio[i] * k.squareRoot()
                let acceleration = -k * (poseValues[i] - target[i]) - c * poseVelocity[i]
                poseVelocity[i] += acceleration * h
                poseValues[i] += poseVelocity[i] * h
            }
        }
        pose = ExpressionParams(values: poseValues)

        // 3. Where the pupils look
        var desired = CGPoint.zero
        if let t = lookTarget {
            desired = t
        } else if spec.idle.lookAround && !reduceMotion {
            if now >= nextDrift {
                driftTarget = CGPoint(
                    x: Double.random(in: -0.6...0.6),
                    y: Double.random(in: -0.3...0.3)
                )
                nextDrift = now + Double.random(in: 1.5...3.5)
            }
            desired = driftTarget
        }
        let trackingSpeed: Double = (lookTarget != nil) ? 36.0 : 16.0
        let a = CGFloat(1 - exp(-trackingSpeed * dt))
        look.x += (desired.x - look.x) * a
        look.y += (desired.y - look.y) * a

        // 4. Blink (the lid sweeps down and back up)
        if spec.idle.blink && !reduceMotion {
            if blinkStart < 0 && now >= nextBlink {
                blinkStart = now
            }
            if blinkStart >= 0 {
                let p = (now - blinkStart) / 0.18
                if p >= 1 {
                    blinkStart = -1
                    blink = 1
                    nextBlink = now + Double.random(in: 2.2...5.0)
                } else {
                    blink = abs(1 - 2 * p)   // 1 -> 0 -> 1
                }
            }
        } else {
            blink = 1
        }

        // 5. Squash spring (tap bounce)
        let stiffness = 140.0
        let damping = 10.0
        squashVelocity += (-stiffness * squash - damping * squashVelocity) * dt
        squash += squashVelocity * dt

        // 6. Breathing
        if spec.idle.breathe && !reduceMotion {
            breath = sin(now * 2.2)
        } else {
            breath = 0
        }
    }
}
