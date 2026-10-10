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

    // Ear spring simulation (angles in degrees: negative = counter-clockwise, positive = clockwise)
    private(set) var earAngles: (left: Double, right: Double) = (0, 0)
    private var earVelocity: (left: Double, right: Double) = (0, 0)
    private var startedEars = false
    private var nextEarTwitch: TimeInterval = 0

    // Spring channels, in the order of ExpressionParams.values (24 channels):
    // 0: eyeOpen, 1: eyeSize, 2: eyeSpacing, 3: eyeY, 4: eyePupil, 5: eyeSquint, 6: lidTilt, 7: eyeStyleBlend
    // 8-11: browAmount, browTilt, browArch, browY
    // 12-14: mouthCurve, mouthOpen, mouthWidth
    // 15-17: pad, teeth, tongue
    // 18-19: tear, sparkle
    // 20-22: earsPerk, earsTilt, earsSplay
    // 23: bodySquash
    private static let stiffness: [Double] = [
        260, 180, 180, 180, 200, 200, 200, 180,
        170, 170, 170, 170,
        170, 150, 150,
        150, 150, 150,
        150, 150,
        140, 140, 140,
        120
    ]
    private static let dampingRatio: [Double] = [
        0.75, 0.65, 0.65, 0.65, 0.65, 0.60, 0.60, 0.65,
        0.55, 0.55, 0.55, 0.55,
        0.50, 0.50, 0.50,
        0.55, 0.55, 0.55,
        0.60, 0.60,
        0.60, 0.60, 0.60,
        0.45
    ]

    private var poseValues = [Double](repeating: 0, count: 24)
    private var poseVelocity = [Double](repeating: 0, count: 24)

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

    func bump(_ amount: Double, earFlick: Double = 1.0) {
        squashVelocity += amount
        earVelocity.left -= amount * 15.0 * earFlick
        earVelocity.right += amount * 15.0 * earFlick
    }

    func updateTouchHold(touchStart: TimeInterval, currentTime: TimeInterval, holdSeconds: Double) -> Bool {
        guard touching, !moved else { return false }
        return (currentTime - touchStart) >= holdSeconds
    }

    // MARK: Per-frame update

    func step(now: TimeInterval, spec: CharacterSpec, reduceMotion: Bool) {
        let dt = (lastTime == nil) ? 0 : min(max(now - lastTime!, 0), 1.0 / 20.0)
        lastTime = now
        time = now
        self.reduceMotion = reduceMotion

        if !started {
            started = true
            nextBlink = now + 1.5
            nextDrift = now + 1.0
            nextEarTwitch = now + 2.5
            let start = spec.expressions[baseMood] ?? spec.expressions["neutral"] ?? ExpressionParams()
            poseValues = start.values(parts: spec.parts)
            poseVelocity = [Double](repeating: 0, count: 24)
            pose = ExpressionParams(values: poseValues, base: start)
        }

        // 1. Expression target (a reaction override wins while it is active)
        var name = baseMood
        if let override = overrideName, now < overrideUntil {
            name = override
        }
        let targetParams = (spec.expressions[name] ?? spec.expressions["neutral"] ?? ExpressionParams())
        let target = targetParams.values(parts: spec.parts)

        // 2. Damped springs, integrated in small fixed sub-steps so stiff springs stay stable
        if dt > 0 {
            let substeps = max(1, Int(ceil(dt / (1.0 / 120.0))))
            let h = dt / Double(substeps)
            for _ in 0..<substeps {
                for i in 0..<24 {
                    let k = RigState.stiffness[i]
                    let c = 2 * RigState.dampingRatio[i] * k.squareRoot()
                    let acceleration = -k * (poseValues[i] - target[i]) - c * poseVelocity[i]
                    poseVelocity[i] += acceleration * h
                    poseValues[i] += poseVelocity[i] * h
                }
            }
            for i in 0..<24 {
                if abs(poseValues[i] - target[i]) < 0.0005 && abs(poseVelocity[i]) < 0.0005 {
                    poseValues[i] = target[i]
                    poseVelocity[i] = 0
                }
            }
            pose = ExpressionParams(values: poseValues, base: targetParams)
        } else {
            poseValues = target
            pose = ExpressionParams(values: poseValues, base: targetParams)
        }

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
        if dt > 0 {
            let trackingSpeed: Double = (lookTarget != nil) ? 36.0 : 16.0
            let a = CGFloat(1 - exp(-trackingSpeed * dt))
            look.x += (desired.x - look.x) * a
            look.y += (desired.y - look.y) * a
        } else {
            look = desired
        }

        // 4. Blink (the lid sweeps down and back up: 1 = open, 0 = closed)
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
        if dt > 0 {
            let stiffness = 140.0
            let damping = 10.0
            squashVelocity += (-stiffness * squash - damping * squashVelocity) * dt
            squash += squashVelocity * dt
        } else {
            squash = 0
            squashVelocity = 0
        }

        // 6. Breathing
        if spec.idle.breathe && !reduceMotion {
            breath = sin(now * 2.2)
        } else {
            breath = 0
        }

        // 7. Ears physics & target angles
        if let ears = spec.parts.ears, ears.style != "none" {
            let isSide = (ears.anchor.lowercased() == "side")
            let baseLeft = isSide ? -(65.0 + ears.baseAngle) : -ears.baseAngle * 0.95
            let baseRight = isSide ? (65.0 + ears.baseAngle) : ears.baseAngle * 0.95

            let perk = pose.earsPerk
            let tilt = pose.earsTilt
            let splay = pose.earsSplay

            let perkOffsetL = isSide ? (perk * 15.0) : (-perk * ears.baseAngle)
            let perkOffsetR = isSide ? (-perk * 15.0) : (perk * ears.baseAngle)
            let splayOffsetL = -splay * 25.0
            let splayOffsetR = splay * 25.0
            let tiltOffset = tilt * 20.0

            let dragLean = Double(look.x) * 20.0 * spec.touch.earLean

            let followSquash = squash * 30.0 * ears.spring.follow
            let followBreath = breath * 3.0 * ears.spring.follow

            // Idle ear twitch
            if spec.idle.earTwitch && !reduceMotion && dt > 0 {
                if now >= nextEarTwitch {
                    let flick = Double.random(in: 12.0...22.0)
                    if Bool.random() {
                        earVelocity.left += flick * 10.0
                    } else {
                        earVelocity.right -= flick * 10.0
                    }
                    nextEarTwitch = now + Double.random(in: 2.5...6.0)
                }
            }

            let targetL = baseLeft + perkOffsetL + splayOffsetL + tiltOffset + dragLean + followSquash + followBreath
            let targetR = baseRight + perkOffsetR + splayOffsetR + tiltOffset + dragLean - followSquash - followBreath

            if !startedEars || dt <= 0 {
                startedEars = true
                earAngles = (targetL, targetR)
                earVelocity = (0, 0)
            } else {
                let k = ears.spring.stiffness
                let c = ears.spring.damping
                let accelL = -k * (earAngles.left - targetL) - c * earVelocity.left
                let accelR = -k * (earAngles.right - targetR) - c * earVelocity.right
                earVelocity.left += accelL * dt
                earVelocity.right += accelR * dt
                earAngles.left += earVelocity.left * dt
                earAngles.right += earVelocity.right * dt
            }
        } else {
            earAngles = (0, 0)
            earVelocity = (0, 0)
        }
    }
}
