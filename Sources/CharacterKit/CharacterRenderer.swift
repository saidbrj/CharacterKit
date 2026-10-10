import SwiftUI

/// Draws the character in the webapp's exact SVG coordinate space (320 x 300).
/// Purely parametric: 100% derived from numeric values, with zero mood-name checks.
enum CharacterRenderer {

    static func rawBodyPath(
        spec: CharacterSpec,
        size: CGSize = CGSize(width: 320, height: 300),
        dy: Double = 0,
        scale: Double = 1,
        isFillMode: Bool = false,
        canvasHeight: Double = 300
    ) -> (path: Path, startY: Double, endY: Double, centerY: Double, halfH: Double, halfW: Double) {
        var bodyPath = Path()
        var bodyStartY = 50.0
        var bodyEndY = 265.0
        let bodyCenterY: Double
        let bodyHalfHeight: Double
        let bodyHalfWidth: Double

        if isFillMode {
            let canvasTopY = canvasHeight * spec.layout.topInset
            bodyCenterY = (canvasTopY + canvasHeight + 150.0) / 2.0
            bodyHalfHeight = (canvasHeight + 150.0 - canvasTopY) / 2.0
            bodyHalfWidth = 160.0
            bodyStartY = 0.0
            bodyEndY = canvasHeight

            bodyPath.move(to: CGPoint(x: -20, y: canvasTopY + 30))
            bodyPath.addQuadCurve(to: CGPoint(x: 60, y: canvasTopY + 10), control: CGPoint(x: 20, y: canvasTopY - 30))
            bodyPath.addQuadCurve(to: CGPoint(x: 160, y: canvasTopY), control: CGPoint(x: 110, y: canvasTopY - 40))
            bodyPath.addQuadCurve(to: CGPoint(x: 260, y: canvasTopY + 10), control: CGPoint(x: 210, y: canvasTopY - 40))
            bodyPath.addQuadCurve(to: CGPoint(x: 340, y: canvasTopY + 30), control: CGPoint(x: 300, y: canvasTopY - 30))
            bodyPath.addLine(to: CGPoint(x: 340, y: max(600, canvasHeight + 300)))
            bodyPath.addLine(to: CGPoint(x: -20, y: max(600, canvasHeight + 300)))
            bodyPath.closeSubpath()
        } else {
            switch spec.parts.bodyShape.lowercased() {
            case "blob":
                bodyCenterY = 153.0
                bodyHalfHeight = 101.0
                bodyHalfWidth = 116.0
                bodyPath.addRoundedRect(in: CGRect(x: 44, y: 52, width: 232, height: 202), cornerSize: CGSize(width: 82, height: 78))
                bodyStartY = 52.0
                bodyEndY = 254.0
            case "round":
                bodyCenterY = 164.75
                bodyHalfHeight = 73.25
                bodyHalfWidth = 89.25
                let rx = 89.25
                let ry = 73.25
                let cx = 160.0
                let cy = 164.75
                bodyPath.addEllipse(in: CGRect(x: cx - rx, y: cy - ry, width: rx * 2.0, height: ry * 2.0))
                bodyStartY = cy - ry
                bodyEndY = cy + ry
            default:
                bodyCenterY = 157.0
                bodyHalfHeight = 103.0
                bodyHalfWidth = 117.0
                bodyStartY = 50.0
                bodyEndY = 265.0
                // Cloud body
                bodyPath.move(to: CGPoint(x: 160, y: 54))
                bodyPath.addCurve(to: CGPoint(x: 94, y: 65), control1: CGPoint(x: 140, y: 29), control2: CGPoint(x: 107, y: 35))
                bodyPath.addCurve(to: CGPoint(x: 43, y: 113), control1: CGPoint(x: 61, y: 50), control2: CGPoint(x: 31, y: 75))
                bodyPath.addCurve(to: CGPoint(x: 42, y: 183), control1: CGPoint(x: 12, y: 128), control2: CGPoint(x: 11, y: 167))
                bodyPath.addCurve(to: CGPoint(x: 82, y: 250), control1: CGPoint(x: 24, y: 217), control2: CGPoint(x: 45, y: 254))
                bodyPath.addCurve(to: CGPoint(x: 238, y: 250), control1: CGPoint(x: 123, y: 269), control2: CGPoint(x: 197, y: 269))
                bodyPath.addCurve(to: CGPoint(x: 278, y: 183), control1: CGPoint(x: 275, y: 254), control2: CGPoint(x: 296, y: 217))
                bodyPath.addCurve(to: CGPoint(x: 277, y: 113), control1: CGPoint(x: 309, y: 167), control2: CGPoint(x: 308, y: 128))
                bodyPath.addCurve(to: CGPoint(x: 226, y: 65), control1: CGPoint(x: 289, y: 75), control2: CGPoint(x: 259, y: 50))
                bodyPath.addCurve(to: CGPoint(x: 160, y: 54), control1: CGPoint(x: 213, y: 35), control2: CGPoint(x: 180, y: 29))
                bodyPath.closeSubpath()
            }
        }
        return (bodyPath, bodyStartY, bodyEndY, bodyCenterY, bodyHalfHeight, bodyHalfWidth)
    }

    static func bodyPath(spec: CharacterSpec, squash: Double = 0) -> Path {
        let (raw, _, _, _, _, _) = rawBodyPath(spec: spec)
        if abs(squash) > 0.0001 {
            let sx = 1.0 + 0.12 * squash * 0.8
            let sy = 1.0 - 0.12 * squash * 0.8
            let squashAnchorY: Double = (spec.parts.bodyShape.lowercased() == "round") ? 208.0 : 260.0
            var t = CGAffineTransform(translationX: 160.0, y: squashAnchorY)
            t = t.scaledBy(x: sx, y: sy)
            t = t.translatedBy(x: -160.0, y: -squashAnchorY)
            return raw.applying(t)
        }
        return raw
    }

    static func sampleTopOutline(path: Path, x: Double, minY: Double = 10, maxY: Double = 260) -> Double {
        var firstInsideY = maxY
        var found = false
        for y in stride(from: minY, through: maxY, by: 2.0) {
            if path.contains(CGPoint(x: x, y: y)) { firstInsideY = y; found = true; break }
        }
        guard found else { return minY }
        var lo = max(minY, firstInsideY - 2.0), hi = firstInsideY
        for _ in 0..<14 {
            let mid = (lo + hi) / 2.0
            if path.contains(CGPoint(x: x, y: mid)) { hi = mid } else { lo = mid }
        }
        return (lo + hi) / 2.0
    }

    static func sampleSideOutline(path: Path, y: Double, isLeft: Bool) -> Double {
        let minX = 0.0, maxX = 320.0, midX = 160.0
        if isLeft {
            var firstInsideX = midX, found = false
            for x in stride(from: minX, through: midX, by: 2.0) {
                if path.contains(CGPoint(x: x, y: y)) { firstInsideX = x; found = true; break }
            }
            guard found else { return minX }
            var lo = max(minX, firstInsideX - 2.0), hi = firstInsideX
            for _ in 0..<14 {
                let mid = (lo + hi) / 2.0
                if path.contains(CGPoint(x: mid, y: y)) { hi = mid } else { lo = mid }
            }
            return (lo + hi) / 2.0
        } else {
            var firstInsideX = midX, found = false
            for x in stride(from: maxX, through: midX, by: -2.0) {
                if path.contains(CGPoint(x: x, y: y)) { firstInsideX = x; found = true; break }
            }
            guard found else { return maxX }
            var lo = firstInsideX, hi = min(maxX, firstInsideX + 2.0)
            for _ in 0..<14 {
                let mid = (lo + hi) / 2.0
                if path.contains(CGPoint(x: mid, y: y)) { hi = mid } else { lo = mid }
            }
            return (lo + hi) / 2.0
        }
    }

    static func earBases(spec: CharacterSpec, bodyPath: Path) -> (left: CGPoint, right: CGPoint)? {
        guard let ears = spec.parts.ears, ears.style.lowercased() != "none" else { return nil }
        if spec.layout.mode.lowercased() == "fill" {
            let spreadBase = 117.0
            let targetXL = 160.0 - ears.spread * spreadBase
            let targetXR = 160.0 + ears.spread * spreadBase
            let targetY = 157.0 + ears.baseY * 103.0
            return (CGPoint(x: targetXL, y: targetY), CGPoint(x: targetXR, y: targetY))
        }
        let isSide = (ears.anchor.lowercased() == "side")
        let isRound = (spec.parts.bodyShape.lowercased() == "round")
        let bodyHalfWidth = isRound ? 89.25 : 117.0
        let bodyCenterY = isRound ? 164.75 : 157.0
        let bodyHalfHeight = isRound ? 73.25 : 103.0

        let earScale = isSide ? 117.0 : 122.0
        let earWidth = ears.width * earScale
        let inwardOffset = 0.30 * earWidth

        if isSide {
            let targetY = bodyCenterY + ears.baseY * bodyHalfHeight
            let spreadBase = 130.0
            let defaultXL = 160.0 - ears.spread * spreadBase
            let defaultXR = 160.0 + ears.spread * spreadBase

            let ptL = CGPoint(x: defaultXL, y: targetY)
            let ptR = CGPoint(x: defaultXR, y: targetY)
            if bodyPath.contains(ptL) && bodyPath.contains(ptR) {
                return (ptL, ptR)
            }

            let xl = sampleSideOutline(path: bodyPath, y: targetY, isLeft: true)
            let xl1 = sampleSideOutline(path: bodyPath, y: targetY - 1.0, isLeft: true)
            let xl2 = sampleSideOutline(path: bodyPath, y: targetY + 1.0, isLeft: true)
            let dxl = xl2 - xl1, dyl = 2.0
            let lenl = hypot(dxl, dyl)
            let nxl = dyl / lenl, nyl = -dxl / lenl
            let baseLeft = CGPoint(x: xl + nxl * inwardOffset, y: targetY + nyl * inwardOffset)

            let xr = sampleSideOutline(path: bodyPath, y: targetY, isLeft: false)
            let xr1 = sampleSideOutline(path: bodyPath, y: targetY - 1.0, isLeft: false)
            let xr2 = sampleSideOutline(path: bodyPath, y: targetY + 1.0, isLeft: false)
            let dxr = xr2 - xr1, dyr = 2.0
            let lenr = hypot(dxr, dyr)
            let nxr = -dyr / lenr, nyr = dxr / lenr
            let baseRight = CGPoint(x: xr + nxr * inwardOffset, y: targetY + nyr * inwardOffset)
            return (baseLeft, baseRight)
        } else {
            let spreadBase = bodyHalfWidth
            let targetXL = 160.0 - ears.spread * spreadBase
            let targetXR = 160.0 + ears.spread * spreadBase

            let yl = sampleTopOutline(path: bodyPath, x: targetXL)
            let yl1 = sampleTopOutline(path: bodyPath, x: targetXL - 1.0)
            let yl2 = sampleTopOutline(path: bodyPath, x: targetXL + 1.0)
            let dxl = 2.0, dyl = yl2 - yl1
            let lenl = hypot(dxl, dyl)
            let nxl = -dyl / lenl, nyl = dxl / lenl
            let baseLeft = CGPoint(x: targetXL + nxl * inwardOffset, y: yl + nyl * inwardOffset)

            let yr = sampleTopOutline(path: bodyPath, x: targetXR)
            let yr1 = sampleTopOutline(path: bodyPath, x: targetXR - 1.0)
            let yr2 = sampleTopOutline(path: bodyPath, x: targetXR + 1.0)
            let dxr = 2.0, dyr = yr2 - yr1
            let lenr = hypot(dxr, dyr)
            let nxr = -dyr / lenr, nyr = dxr / lenr
            let baseRight = CGPoint(x: targetXR + nxr * inwardOffset, y: yr + nyr * inwardOffset)
            return (baseLeft, baseRight)
        }
    }

    static func mouthPath(spec: CharacterSpec, rig: RigState) -> Path {
        let isFillMode = (spec.layout.mode.lowercased() == "fill")
        let baseMouthY = isFillMode ? 198.0 : 196.5
        let pose = rig.pose
        let curve = pose.mouthCurve
        let widthParam = clampValue(pose.mouthWidth, 0, 1)

        let halfWidth = 32.0 + 45.0 * widthParam
        let leftX = 160.0 - halfWidth
        let rightX = 160.0 + halfWidth

        let endY = baseMouthY - 15.0 * curve
        let ctrlY = baseMouthY + 29.0 * curve

        var path = Path()
        path.move(to: CGPoint(x: leftX, y: endY))
        path.addQuadCurve(to: CGPoint(x: rightX, y: endY), control: CGPoint(x: 160.0, y: ctrlY))
        return path
    }

    public static func browEndpoints(spec: CharacterSpec, rig: RigState) -> (leftOuter: CGPoint, leftInner: CGPoint, rightInner: CGPoint, rightOuter: CGPoint)? {
        let pose = rig.pose
        guard pose.browAmount > 0.05 else { return nil }

        let isRound = (spec.parts.bodyShape.lowercased() == "round")
        let effectiveEyeY = pose.eyeY ?? spec.parts.eyeY
        let eyeY: Double = isRound ? (154.0 + (effectiveEyeY + 0.1) * 46.5) : (142.0 + effectiveEyeY * 100.0)

        let effectiveSpacing = pose.eyeSpacing ?? spec.parts.eyeSpacing
        let spacingOffset: Double = isRound ? (spec.parts.eyeSpacing * 99.0) : (effectiveSpacing * 145.0)
        guard spec.parts.eyeCount == 2 else { return nil }
        let eyeL = 160.0 - spacingOffset
        let eyeR = 160.0 + spacingOffset

        let browHW = 14.0
        let baseBY = eyeY - 43.46 + pose.browY * 25.0
        let tilt = pose.browTilt * 18.0
        return (
            leftOuter: CGPoint(x: eyeL - browHW, y: baseBY + tilt),
            leftInner: CGPoint(x: eyeL + browHW, y: baseBY - tilt),
            rightInner: CGPoint(x: eyeR - browHW, y: baseBY - tilt),
            rightOuter: CGPoint(x: eyeR + browHW, y: baseBY + tilt)
        )
    }

    public enum CharacterLayer: String, CaseIterable {
        case ears
        case body
        case pads
        case eyes
        case brows
        case mouth
        case overlays
    }

    public static func eyeGeometry(spec: CharacterSpec, rig: RigState, isFillMode: Bool = false) -> (centers: [(x: Double, y: Double)], radius: Double) {
        let pose = rig.pose
        let isRound = (spec.parts.bodyShape.lowercased() == "round")
        let effectiveEyeSize = pose.eyeSize ?? spec.parts.eyeSize
        let baseEyeRadius: Double = (isRound && !isFillMode ? 16.36 : 27.0) * effectiveEyeSize
        let eyeR_val: Double = clampValue(baseEyeRadius, 12, 45)
        let effectiveEyeY = pose.eyeY ?? spec.parts.eyeY
        let eyeY: Double = isRound ? (154.0 + (effectiveEyeY + 0.1) * 46.5) : (142.0 + effectiveEyeY * 100.0)

        let effectiveSpacing = pose.eyeSpacing ?? spec.parts.eyeSpacing
        let spacingOffset: Double
        if isFillMode {
            spacingOffset = effectiveSpacing * 145.0
        } else if isRound {
            spacingOffset = spec.parts.eyeSpacing * 99.0
        } else {
            spacingOffset = spec.parts.eyeSpacing * 145.0
        }
        let centers: [(x: Double, y: Double)]
        if spec.parts.eyeCount == 1 {
            centers = [(160.0, eyeY)]
        } else {
            centers = [(160.0 - spacingOffset, eyeY), (160.0 + spacingOffset, eyeY)]
        }
        return (centers, eyeR_val)
    }

    public static func groupTransform(spec: CharacterSpec, rig: RigState, canvasHeight: Double = 300.0) -> CGAffineTransform {
        let isFillMode = (spec.layout.mode.lowercased() == "fill")
        let pose = rig.pose
        let squashAnchorY: Double = isFillMode ? canvasHeight : ((spec.parts.bodyShape.lowercased() == "round") ? 208.0 : 260.0)
        let groupAnchor = CGPoint(x: 160.0, y: squashAnchorY)

        let sx = 1.0 + 0.08 * pose.bodySquash + 0.12 * rig.squash
        let sy = 1.0 - 0.08 * pose.bodySquash - 0.12 * rig.squash
        let breathSx = 1.0 - 0.008 * rig.breath
        let breathSy = 1.0 + 0.015 * rig.breath

        let groupSx = sx * breathSx
        let groupSy = sy * breathSy

        var t = CGAffineTransform(translationX: groupAnchor.x, y: groupAnchor.y)
        t = t.scaledBy(x: groupSx, y: groupSy)
        t = t.translatedBy(x: -groupAnchor.x, y: -groupAnchor.y)
        return t
    }

    static func draw(_ context: GraphicsContext, size: CGSize, spec: CharacterSpec, rig: RigState) {
        let isFillMode = (spec.layout.mode.lowercased() == "fill")

        let scale: Double
        let dx: Double
        let dy: Double
        let canvasHeight: Double

        if isFillMode {
            scale = size.width / 320.0
            guard scale > 0 else { return }
            dx = 0
            dy = 0
            canvasHeight = size.height / scale
        } else {
            scale = min(size.width / 320.0, size.height / 300.0)
            guard scale > 0 else { return }
            dx = (size.width - 320.0 * scale) / 2.0
            dy = (size.height - 300.0 * scale) / 2.0
            canvasHeight = 300.0
        }

        var ctx = context
        ctx.translateBy(x: dx, y: dy)
        ctx.scaleBy(x: scale, y: scale)

        let pose = rig.pose
        let palette = spec.palette

        let eyeWhite = Color(characterHex: palette.eyeWhite)
        let pupilColor = Color(characterHex: palette.pupil)
        let mouthColor = Color(characterHex: palette.mouth)

        // Squash & stretch and breathing transform applied to the whole character group,
        // anchored at the body's base point (bottom center in fill mode, 208 for round, 260 for other in contained mode).
        let squashAnchorY: Double = isFillMode ? canvasHeight : ((spec.parts.bodyShape.lowercased() == "round") ? 208.0 : 260.0)
        let groupAnchor = CGPoint(x: 160.0, y: squashAnchorY)

        let sx = 1.0 + 0.08 * pose.bodySquash + 0.12 * rig.squash
        let sy = 1.0 - 0.08 * pose.bodySquash - 0.12 * rig.squash
        let breathSx = 1.0 - 0.008 * rig.breath
        let breathSy = 1.0 + 0.015 * rig.breath

        let groupSx = sx * breathSx
        let groupSy = sy * breathSy

        ctx.translateBy(x: groupAnchor.x, y: groupAnchor.y)
        ctx.scaleBy(x: groupSx, y: groupSy)
        ctx.translateBy(x: -groupAnchor.x, y: -groupAnchor.y)

        let (bodyPath, bodyStartY, bodyEndY, _, _, _) = rawBodyPath(
            spec: spec,
            size: size,
            dy: dy,
            scale: scale,
            isFillMode: isFillMode,
            canvasHeight: canvasHeight
        )

        // FIXED LAYER ORDER: ears, body, pads, eyes, brows, mouth, overlays (tear)

        // 1. EARS: Generic appendage drawn BEHIND the body; follows group transform and adds its own spring lag
        if let ears = spec.parts.ears, ears.style.lowercased() != "none",
           let bases = earBases(spec: spec, bodyPath: bodyPath) {
            let earColor = Color(characterHex: palette.effectiveEar)
            let earInnerColor = Color(characterHex: palette.effectiveEarInner)

            let isSide = (ears.anchor.lowercased() == "side")
            let earScale = isFillMode ? 234.0 : (isSide ? 117.0 : 122.0)
            let w = ears.width * earScale
            let hw = w / 2.0
            let len = ears.length * earScale
            let r = ears.tipRoundness
            let bend = ears.bend
            let tipX = bend * len * 0.35
            let tipOffset = hw * r * 0.65

            var earPath = Path()
            earPath.move(to: CGPoint(x: -hw, y: 0))
            earPath.addCurve(
                to: CGPoint(x: tipX, y: -len),
                control1: CGPoint(x: -hw, y: -0.45 * len),
                control2: CGPoint(x: tipX - tipOffset, y: -len)
            )
            earPath.addCurve(
                to: CGPoint(x: hw, y: 0),
                control1: CGPoint(x: tipX + tipOffset, y: -len),
                control2: CGPoint(x: hw, y: -0.45 * len)
            )
            earPath.addQuadCurve(
                to: CGPoint(x: -hw, y: 0),
                control: CGPoint(x: 0, y: hw * 0.3)
            )
            earPath.closeSubpath()

            // Left Ear
            ctx.drawLayer { layer in
                layer.translateBy(x: bases.left.x, y: bases.left.y)
                layer.rotate(by: .degrees(rig.earAngles.left))
                layer.fill(earPath, with: .color(earColor))
                if ears.innerScale > 0.01 {
                    layer.scaleBy(x: ears.innerScale, y: ears.innerScale)
                    layer.fill(earPath, with: .color(earInnerColor))
                }
            }

            // Right Ear
            ctx.drawLayer { layer in
                layer.translateBy(x: bases.right.x, y: bases.right.y)
                layer.rotate(by: .degrees(rig.earAngles.right))
                layer.fill(earPath, with: .color(earColor))
                if ears.innerScale > 0.01 {
                    layer.scaleBy(x: ears.innerScale, y: ears.innerScale)
                    layer.fill(earPath, with: .color(earInnerColor))
                }
            }
        }

        // 2. BODY
        let canvasTopY = canvasHeight * spec.layout.topInset
        let bodyGradient = GraphicsContext.Shading.linearGradient(
            Gradient(colors: [Color(characterHex: palette.body), Color(characterHex: palette.bodyShade)]),
            startPoint: CGPoint(x: 160, y: isFillMode ? (canvasTopY - 40) : bodyStartY),
            endPoint: CGPoint(x: 160, y: isFillMode ? (canvasHeight + 300) : bodyEndY)
        )
        ctx.drawLayer { bodyLayer in
            bodyLayer.fill(bodyPath, with: bodyGradient)
        }

        if isFillMode {
            let targetFaceY = canvasHeight * spec.layout.faceCenterY
            let widthFaceScale = (spec.layout.faceScale / 0.5) * 1.3
            let maxFaceScale = (canvasHeight * (spec.layout.faceMaxHeight ?? 0.32)) / 100.0
            let faceScale = min(widthFaceScale, maxFaceScale)
            ctx.translateBy(x: 160.0, y: targetFaceY)
            ctx.scaleBy(x: faceScale, y: faceScale)
            ctx.translateBy(x: -160.0, y: -150.0)
        }

        // Interactive look offset for pupils
        let lookDx = Double(rig.look.x) * 16.0
        let lookDy = Double(rig.look.y) * 16.0

        // 3. PADS: Cheek / muzzle pad drawn below eyes and mouth
        if pose.pad > 0.001 {
            let open = clampValue(pose.mouthOpen, 0, 1)
            let mPath = mouthPath(spec: spec, rig: rig)
            let mouthLineWidth = 8.0 * spec.parts.mouthThickness + 30.0 * open
            let padColor = Color(characterHex: palette.pad ?? palette.mouthOutline).opacity(pose.pad)
            let padLineWidth = mouthLineWidth + 34.0 * pose.pad
            ctx.stroke(mPath, with: .color(padColor), style: StrokeStyle(lineWidth: padLineWidth, lineCap: .round))
        }

        // 4. EYES: Purely parametric with continuous crossfade blend
        let isRound = (spec.parts.bodyShape.lowercased() == "round")
        let effectiveEyeSize = pose.eyeSize ?? spec.parts.eyeSize
        let baseEyeRadius: Double = (isRound && !isFillMode ? 16.36 : 27.0) * effectiveEyeSize
        let eyeR_val: Double = clampValue(baseEyeRadius, 12, 45)
        let effectiveEyeY = pose.eyeY ?? spec.parts.eyeY
        let eyeY: Double = isRound ? (154.0 + (effectiveEyeY + 0.1) * 46.5) : (142.0 + effectiveEyeY * 100.0)

        let effectiveSpacing = pose.eyeSpacing ?? spec.parts.eyeSpacing
        let eyeCenters: [(x: Double, isLeft: Bool)]
        if spec.parts.eyeCount == 1 {
            eyeCenters = [(160.0, true)]
        } else {
            let spacingOffset: Double
            if isFillMode {
                spacingOffset = effectiveSpacing * 145.0
            } else if isRound {
                spacingOffset = spec.parts.eyeSpacing * 99.0
            } else {
                spacingOffset = spec.parts.eyeSpacing * 145.0
            }
            eyeCenters = [(160.0 - spacingOffset, true), (160.0 + spacingOffset, false)]
        }

        let effectivePupil = pose.eyePupil ?? spec.parts.pupilSize
        let pupilRadius: Double = eyeR_val * clampValue(effectivePupil, 0.18, 0.85)
        let openFactor = clampValue(pose.eyeOpen * rig.blink, 0, 1)

        let styleBlend = clampValue(pose.eyeStyleBlend, 0, 1)

        // Circular eyes (crossfaded by 1.0 - styleBlend)
        if styleBlend < 0.999 {
            ctx.drawLayer { eyesLayer in
                if styleBlend > 0.001 {
                    eyesLayer.opacity = 1.0 - styleBlend
                }
                for eye in eyeCenters {
                    let ex = eye.x
                    let ey = eyeY

                    let eyeCircle = Path(ellipseIn: CGRect(x: ex - eyeR_val, y: ey - eyeR_val, width: eyeR_val * 2, height: eyeR_val * 2))

                    var lidPath = Path()
                    let op = openFactor
                    let lt = pose.lidTilt
                    let sq = clampValue(pose.eyeSquint, 0, 1)

                    let xl = ex - (eyeR_val + 1.0)
                    let xr = ex + (eyeR_val + 1.0)

                    let ytl = ey + eyeR_val * (1.0 - 2.0 * op + (eye.isLeft ? 0.6 * lt : -0.6 * lt))
                    let ytr = ey + eyeR_val * (1.0 - 2.0 * op - (eye.isLeft ? 0.6 * lt : -0.6 * lt))
                    let midRel = eyeR_val * (1.0 - 2.0 * op)
                    let effectiveLt = eye.isLeft ? lt : -lt
                    let ytm = (effectiveLt < -0.15) ? (ey + midRel - 16.0 * (effectiveLt + 0.15)) : (ey + midRel)

                    let ybe = ey + eyeR_val * (1.0 - sq)
                    let ybc = ey + eyeR_val * (1.0 - 2.0 * sq)

                    lidPath.move(to: CGPoint(x: xl, y: ytl))
                    lidPath.addQuadCurve(to: CGPoint(x: xr, y: ytr), control: CGPoint(x: ex, y: ytm))
                    lidPath.addLine(to: CGPoint(x: xr, y: ybe))
                    lidPath.addQuadCurve(to: CGPoint(x: xl, y: ybe), control: CGPoint(x: ex, y: ybc))
                    lidPath.closeSubpath()

                    let baseShift = (spec.parts.eyeCount == 1) ? 0.0 : (effectiveSpacing * 40.6)
                    let maxLook = max(2.0, min(eyeR_val - pupilRadius - 1.5 - baseShift, 8.0))
                    let pDx = (eye.isLeft ? baseShift : -baseShift) + clampValue(lookDx, -maxLook, maxLook)
                    let dy = (1.0 - openFactor) * 10.0 + sq * 14.0 - pose.lidTilt * 8.0
                    let pDy = dy + clampValue(lookDy, -maxLook, maxLook)

                    let pupilCircle = Path(ellipseIn: CGRect(
                        x: ex + pDx - pupilRadius,
                        y: ey + pDy - pupilRadius,
                        width: pupilRadius * 2,
                        height: pupilRadius * 2
                    ))

                    eyesLayer.drawLayer { layer in
                        layer.clip(to: eyeCircle)
                        layer.clip(to: lidPath)
                        layer.fill(eyeCircle, with: .color(eyeWhite))
                        layer.fill(pupilCircle, with: .color(pupilColor))

                        // Star sparkles
                        if pose.sparkle > 0.001 {
                            let spk = pose.sparkle
                            let sparkleColor = Color(characterHex: palette.sparkle ?? "#FFE58A").opacity(spk)
                            let starScale = eyeR_val / 27.0
                            var stars = Path()
                            // Large star
                            stars.move(to: CGPoint(x: ex - 5.0 * starScale + pDx, y: ey - 18.0 * starScale + pDy))
                            stars.addQuadCurve(to: CGPoint(x: ex + 10.0 * starScale + pDx, y: ey - 3.0 * starScale + pDy), control: CGPoint(x: ex - 3.0 * starScale + pDx, y: ey - 5.0 * starScale + pDy))
                            stars.addQuadCurve(to: CGPoint(x: ex - 5.0 * starScale + pDx, y: ey + 12.0 * starScale + pDy), control: CGPoint(x: ex - 3.0 * starScale + pDx, y: ey - 1.0 * starScale + pDy))
                            stars.addQuadCurve(to: CGPoint(x: ex - 20.0 * starScale + pDx, y: ey - 3.0 * starScale + pDy), control: CGPoint(x: ex - 7.0 * starScale + pDx, y: ey - 1.0 * starScale + pDy))
                            stars.addQuadCurve(to: CGPoint(x: ex - 5.0 * starScale + pDx, y: ey - 18.0 * starScale + pDy), control: CGPoint(x: ex - 7.0 * starScale + pDx, y: ey - 5.0 * starScale + pDy))
                            stars.closeSubpath()

                            // Small star
                            stars.move(to: CGPoint(x: ex + 11.0 * starScale + pDx, y: ey + 2.0 * starScale + pDy))
                            stars.addQuadCurve(to: CGPoint(x: ex + 19.0 * starScale + pDx, y: ey + 10.0 * starScale + pDy), control: CGPoint(x: ex + 12.0 * starScale + pDx, y: ey + 9.0 * starScale + pDy))
                            stars.addQuadCurve(to: CGPoint(x: ex + 11.0 * starScale + pDx, y: ey + 18.0 * starScale + pDy), control: CGPoint(x: ex + 12.0 * starScale + pDx, y: ey + 11.0 * starScale + pDy))
                            stars.addQuadCurve(to: CGPoint(x: ex + 3.0 * starScale + pDx, y: ey + 10.0 * starScale + pDy), control: CGPoint(x: ex + 10.0 * starScale + pDx, y: ey + 11.0 * starScale + pDy))
                            stars.addQuadCurve(to: CGPoint(x: ex + 11.0 * starScale + pDx, y: ey + 2.0 * starScale + pDy), control: CGPoint(x: ex + 10.0 * starScale + pDx, y: ey + 9.0 * starScale + pDy))
                            stars.closeSubpath()

                            layer.fill(stars, with: .color(sparkleColor))
                        }
                    }
                }
            }
        }

        // Arc eyes (crossfaded by styleBlend)
        if styleBlend > 0.001 {
            ctx.drawLayer { arcEyesLayer in
                if styleBlend < 0.999 {
                    arcEyesLayer.opacity = styleBlend
                }
                for eye in eyeCenters {
                    var eyeArc = Path()
                    let arcHalfW = eyeR_val * 0.68
                    eyeArc.move(to: CGPoint(x: eye.x - arcHalfW, y: eyeY + 2.0))
                    eyeArc.addQuadCurve(
                        to: CGPoint(x: eye.x + arcHalfW, y: eyeY + 2.0),
                        control: CGPoint(x: eye.x, y: eyeY + 18.9 * (eyeR_val / 28.89))
                    )
                    arcEyesLayer.stroke(eyeArc, with: .color(eyeWhite), style: StrokeStyle(lineWidth: 11.0, lineCap: .round))
                }
            }
        }

        // 5. BROWS: Eyebrows
        if pose.browAmount > 0.001 {
            let browHex = palette.brow ?? "#FFFFFF"
            let browColor = Color(characterHex: browHex).opacity(pose.browAmount)

            let browHW = 14.0
            let baseBY = eyeY - 43.46 + pose.browY * 25.0
            let tilt = pose.browTilt * 18.0
            let arch = pose.browArch * 28.0
            let lineWidth = 8.0 * pose.browAmount

            for eye in eyeCenters {
                var brow = Path()
                if eye.isLeft {
                    brow.move(to: CGPoint(x: eye.x - browHW, y: baseBY + tilt))
                    brow.addQuadCurve(to: CGPoint(x: eye.x + browHW, y: baseBY - tilt), control: CGPoint(x: eye.x, y: baseBY - arch))
                } else {
                    brow.move(to: CGPoint(x: eye.x - browHW, y: baseBY - tilt))
                    brow.addQuadCurve(to: CGPoint(x: eye.x + browHW, y: baseBY + tilt), control: CGPoint(x: eye.x, y: baseBY - arch))
                }
                ctx.stroke(brow, with: .color(browColor), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            }
        }

        // 6. MOUTH: Mouth line, outline, cavity, teeth and tongue
        ctx.drawLayer { mouthLayer in
            let curve = pose.mouthCurve                         // -1...1
            let open = clampValue(pose.mouthOpen, 0, 1)         // 0...1
            let widthParam = clampValue(pose.mouthWidth, 0, 1)  // 0...1

            let mouthPath = mouthPath(spec: spec, rig: rig)
            let mouthLineWidth = 8.0 * spec.parts.mouthThickness + 30.0 * open

            // Outline
            let outlineColor = Color(characterHex: palette.mouthOutline)
            let outlineLineWidth = mouthLineWidth + 2.0 * pose.pad
            mouthLayer.stroke(mouthPath, with: .color(outlineColor), style: StrokeStyle(lineWidth: outlineLineWidth, lineCap: .round))

            // Mouth line
            mouthLayer.stroke(mouthPath, with: .color(mouthColor), style: StrokeStyle(lineWidth: mouthLineWidth, lineCap: .round))

            // Cavity
            let cavityOpacity = max(pose.teeth, pose.tongue)
            if cavityOpacity > 0.001 {
                let cavityColor = Color(characterHex: palette.cavity ?? palette.pupil).opacity(cavityOpacity)
                mouthLayer.stroke(mouthPath, with: .color(cavityColor), style: StrokeStyle(lineWidth: mouthLineWidth, lineCap: .round))
            }

            // Teeth & Tongue (masked by mouthPath stroke)
            if pose.teeth > 0.001 || pose.tongue > 0.001 {
                let cavityMask = mouthPath.strokedPath(StrokeStyle(lineWidth: mouthLineWidth, lineCap: .round))
                let baseMouthY = isFillMode ? 198.0 : 196.5
                mouthLayer.drawLayer { layer in
                    layer.clip(to: cavityMask)

                    if pose.tongue > 0.001 {
                        let tongueColor = Color(characterHex: palette.tongue ?? "#ED877D").opacity(pose.tongue)
                        let halfW = 32.0 + 45.0 * widthParam
                        let rx = 0.6 * halfW * pose.tongue
                        let ry = 0.43 * mouthLineWidth * pose.tongue
                        let endY = baseMouthY - 15.0 * curve
                        let ctrlY = baseMouthY + 29.0 * curve
                        let cy = (ctrlY + endY) / 2.0 + 0.48 * mouthLineWidth
                        let tongueRect = CGRect(x: 160.0 - rx, y: cy - ry, width: rx * 2.0, height: ry * 2.0)
                        layer.fill(Path(ellipseIn: tongueRect), with: .color(tongueColor))
                    }

                    if pose.teeth > 0.001 {
                        let teethColor = Color(characterHex: palette.teeth ?? "#FFF9E8").opacity(pose.teeth)
                        let halfW = 32.0 + 45.0 * widthParam
                        let leftX = 160.0 - halfW + 4.0
                        let rightX = 160.0 + halfW - 4.0
                        let endY = baseMouthY - 15.0 * curve
                        let ctrlY = baseMouthY + 29.0 * curve
                        let teethEndY = endY - 0.32 * mouthLineWidth
                        let teethCtrlY = teethEndY + 0.75 * (ctrlY - endY)

                        var teethPath = Path()
                        teethPath.move(to: CGPoint(x: leftX, y: teethEndY))
                        teethPath.addQuadCurve(to: CGPoint(x: rightX, y: teethEndY), control: CGPoint(x: 160.0, y: teethCtrlY))
                        layer.stroke(teethPath, with: .color(teethColor), style: StrokeStyle(lineWidth: 13.0 * pose.teeth, lineCap: .round))
                    }
                }
            }
        }

        // 7. OVERLAYS: Tear drawn LAST, above eyes, brows, and mouth, outside eye clipping
        if pose.tear > 0.001 {
            var tear = Path()
            let tearColor = Color(characterHex: palette.tear ?? "#78D9F4").opacity(pose.tear)
            let rx = eyeCenters.last?.x ?? (160.0 + (pose.eyeSpacing ?? spec.parts.eyeSpacing) * 145.0)
            let tearOrigin = CGPoint(x: rx + 0.65 * eyeR_val, y: eyeY + (isFillMode ? 0.60 : 0.70) * eyeR_val)
            tear.move(to: CGPoint(x: 0, y: 0))
            tear.addCurve(to: CGPoint(x: -8, y: 25), control1: CGPoint(x: -3, y: 9), control2: CGPoint(x: -12, y: 17))
            tear.addCurve(to: CGPoint(x: 12, y: 23), control1: CGPoint(x: -4, y: 34), control2: CGPoint(x: 11, y: 32))
            tear.addCurve(to: CGPoint(x: 0, y: 0), control1: CGPoint(x: 13, y: 16), control2: CGPoint(x: 4, y: 8))
            tear.closeSubpath()

            ctx.drawLayer { tLayer in
                tLayer.translateBy(x: tearOrigin.x, y: tearOrigin.y)
                tLayer.scaleBy(x: pose.tear, y: pose.tear)
                tLayer.fill(tear, with: .color(tearColor))
            }
        }
    }
}
