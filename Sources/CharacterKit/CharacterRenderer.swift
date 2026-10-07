import SwiftUI

/// Draws the character in the webapp's exact SVG coordinate space (320 x 300).
/// Integrates 100% of the webapp's SVG eye, mouth, and body designs for all 7 emotions,
/// with full spring physics, interactive finger-tracking pupils, blinking, and breathing.
enum CharacterRenderer {

    static func draw(_ context: GraphicsContext, size: CGSize, spec: CharacterSpec, rig: RigState) {
        let scale = min(size.width / 320.0, size.height / 300.0)
        guard scale > 0 else { return }

        var ctx = context
        // Center the 320x300 canvas in the view
        let dx = (size.width - 320.0 * scale) / 2.0
        let dy = (size.height - 300.0 * scale) / 2.0
        ctx.translateBy(x: dx, y: dy)
        ctx.scaleBy(x: scale, y: scale)

        let pose = rig.pose
        let palette = spec.palette

        let eyeWhite = Color(characterHex: palette.eyeWhite)
        let pupilColor = Color(characterHex: palette.pupil)
        let mouthColor = Color(characterHex: palette.mouth)
        let mouthOutline = Color(characterHex: palette.mouthOutline)

        // Squash & stretch plus breathing, anchored at (160, 260) matching the SVG transform
        let squashAmount = pose.bodySquash * 0.8 + rig.squash
        let sx = 1.0 + 0.12 * squashAmount - 0.008 * rig.breath
        let sy = 1.0 - 0.12 * squashAmount + 0.015 * rig.breath
        ctx.translateBy(x: 160.0, y: 260.0)
        ctx.scaleBy(x: sx, y: sy)
        ctx.translateBy(x: -160.0, y: -260.0)

        // 1. BODY: Support cloud, blob, and round shapes
        var bodyPath = Path()
        switch spec.parts.bodyShape.lowercased() {
        case "blob":
            // Smooth superellipse organic cactus/blob body
            bodyPath.addRoundedRect(in: CGRect(x: 44, y: 52, width: 232, height: 202), cornerSize: CGSize(width: 82, height: 78))
        case "round":
            // Circular round body
            bodyPath.addEllipse(in: CGRect(x: 46, y: 46, width: 228, height: 228))
        default:
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

        let bodyGradient = GraphicsContext.Shading.linearGradient(
            Gradient(colors: [Color(characterHex: palette.body), Color(characterHex: palette.bodyShade)]),
            startPoint: CGPoint(x: 160, y: 50),
            endPoint: CGPoint(x: 160, y: 265)
        )
        ctx.fill(bodyPath, with: bodyGradient)

        // Emotion Flags derived from rig.activeMood (so tap & hold reactions trigger immediately!)
        let currentMood = rig.activeMood
        let isCalm = (currentMood == "calm")
        let isExcited = (currentMood == "excited")
        let isSad = (currentMood == "sad")
        let isAnxious = (currentMood == "anxious")
        let isAnnoyed = (currentMood == "annoyed")


        // Interactive look offset for pupils (16px travel so moving finger noticeably tracks across the eyes)
        let lookDx = Double(rig.look.x) * 16.0
        let lookDy = Double(rig.look.y) * 16.0

        // 2. EYES: Exact SVG Geometry for each emotion
        if isCalm && rig.blink > 0.4 {
            // Calm: closed smiling eye arcs (blobby-calm.svg)
            if spec.parts.eyeCount == 1 {
                var eye = Path()
                eye.move(to: CGPoint(x: 141.5, y: 134))
                eye.addQuadCurve(to: CGPoint(x: 178.5, y: 134), control: CGPoint(x: 160, y: 148.9))
                ctx.stroke(eye, with: .color(.white), style: StrokeStyle(lineWidth: 11, lineCap: .round))
            } else {
                var eyeL = Path()
                eyeL.move(to: CGPoint(x: 107.9275, y: 134))
                eyeL.addQuadCurve(to: CGPoint(x: 144.6475, y: 134), control: CGPoint(x: 126.2875, y: 148.9))
                ctx.stroke(eyeL, with: .color(.white), style: StrokeStyle(lineWidth: 11, lineCap: .round))

                var eyeR = Path()
                eyeR.move(to: CGPoint(x: 175.3525, y: 134))
                eyeR.addQuadCurve(to: CGPoint(x: 212.0725, y: 134), control: CGPoint(x: 193.7125, y: 148.9))
                ctx.stroke(eyeR, with: .color(.white), style: StrokeStyle(lineWidth: 11, lineCap: .round))
            }

        } else if isSad {
            // Sad: drooping tilted eyelids with bottom pupils (blobby-sad.svg)
            let eyeR_val: Double = 22.95
            let eyeL_center = CGPoint(x: 138.25, y: 125.0)
            let eyeR_center = CGPoint(x: 181.75, y: 125.0)

            let eyeCircleL = Path(ellipseIn: CGRect(x: eyeL_center.x - eyeR_val, y: eyeL_center.y - eyeR_val, width: eyeR_val * 2, height: eyeR_val * 2))
            let eyeCircleR = Path(ellipseIn: CGRect(x: eyeR_center.x - eyeR_val, y: eyeR_center.y - eyeR_val, width: eyeR_val * 2, height: eyeR_val * 2))

            let blinkDrop = (1.0 - clampValue(rig.blink, 0, 1)) * 30.0

            // Left lid clip path
            var lidL = Path()
            lidL.move(to: CGPoint(x: 115.3, y: 118.3445 + blinkDrop))
            lidL.addQuadCurve(to: CGPoint(x: 161.2, y: 94.9355 + blinkDrop), control: CGPoint(x: 138.25, y: 114.64 + blinkDrop))
            lidL.addLine(to: CGPoint(x: 162.2, y: 148.95))
            lidL.addLine(to: CGPoint(x: 114.3, y: 148.95))
            lidL.closeSubpath()

            // Right lid clip path
            var lidR = Path()
            lidR.move(to: CGPoint(x: 158.8, y: 94.9355 + blinkDrop))
            lidR.addQuadCurve(to: CGPoint(x: 204.7, y: 118.3445 + blinkDrop), control: CGPoint(x: 181.75, y: 114.64 + blinkDrop))
            lidR.addLine(to: CGPoint(x: 205.7, y: 148.95))
            lidR.addLine(to: CGPoint(x: 157.8, y: 148.95))
            lidR.closeSubpath()

            // Left Eye
            let pr: Double = 6.885
            let maxTravel = eyeR_val - pr - 1.5
            let lDx = clampValue(3.0 + lookDx, -maxTravel, maxTravel)
            let lDy = clampValue(11.0 + lookDy, -maxTravel, maxTravel)
            let pupilL = Path(ellipseIn: CGRect(x: eyeL_center.x + lDx - pr, y: eyeL_center.y + lDy - pr, width: pr * 2, height: pr * 2))
            ctx.drawLayer { layer in
                layer.clip(to: eyeCircleL)
                layer.clip(to: lidL)
                layer.fill(eyeCircleL, with: .color(eyeWhite))
                layer.fill(pupilL, with: .color(pupilColor))
            }

            // Right Eye
            let rDx = clampValue(-3.0 + lookDx, -maxTravel, maxTravel)
            let rDy = clampValue(11.0 + lookDy, -maxTravel, maxTravel)
            let pupilR = Path(ellipseIn: CGRect(x: eyeR_center.x + rDx - pr, y: eyeR_center.y + rDy - pr, width: pr * 2, height: pr * 2))
            ctx.drawLayer { layer in
                layer.clip(to: eyeCircleR)
                layer.clip(to: lidR)
                layer.fill(eyeCircleR, with: .color(eyeWhite))
                layer.fill(pupilR, with: .color(pupilColor))
            }

        } else if isExcited {
            // Excited: wide starry eyes with 4-pointed sparkle stars (blobby-excited.svg)
            let eyeR_val: Double = 27.0
            let eyeL_center = CGPoint(x: 131.725, y: 128.0)
            let eyeR_center = CGPoint(x: 188.275, y: 128.0)

            let eyeCircleL = Path(ellipseIn: CGRect(x: eyeL_center.x - eyeR_val, y: eyeL_center.y - eyeR_val, width: eyeR_val * 2, height: eyeR_val * 2))
            let eyeCircleR = Path(ellipseIn: CGRect(x: eyeR_center.x - eyeR_val, y: eyeR_center.y - eyeR_val, width: eyeR_val * 2, height: eyeR_val * 2))

            let blinkDrop = (1.0 - clampValue(rig.blink, 0, 1)) * 40.0

            var lidL = Path()
            lidL.move(to: CGPoint(x: 104.725, y: 101.0 + blinkDrop))
            lidL.addQuadCurve(to: CGPoint(x: 158.725, y: 101.0 + blinkDrop), control: CGPoint(x: 131.725, y: 101.0 + blinkDrop))
            lidL.addLine(to: CGPoint(x: 159.725, y: 156.0))
            lidL.addLine(to: CGPoint(x: 103.725, y: 156.0))
            lidL.closeSubpath()

            var lidR = Path()
            lidR.move(to: CGPoint(x: 161.275, y: 101.0 + blinkDrop))
            lidR.addQuadCurve(to: CGPoint(x: 215.275, y: 101.0 + blinkDrop), control: CGPoint(x: 188.275, y: 101.0 + blinkDrop))
            lidR.addLine(to: CGPoint(x: 216.275, y: 156.0))
            lidR.addLine(to: CGPoint(x: 160.275, y: 156.0))
            lidR.closeSubpath()

            let pr: Double = 20.79
            let maxTravel = eyeR_val - pr - 1.0
            let pDx = clampValue(lookDx, -maxTravel, maxTravel)
            let pDy = clampValue(lookDy, -maxTravel, maxTravel)

            // Left Eye + Star Sparkles
            let pupilL = Path(ellipseIn: CGRect(x: eyeL_center.x + pDx - pr, y: eyeL_center.y + pDy - pr, width: pr * 2, height: pr * 2))
            var starsL = Path()
            // Star 1 (large)
            starsL.move(to: CGPoint(x: 126.725 + pDx, y: 110.0 + pDy))
            starsL.addQuadCurve(to: CGPoint(x: 141.725 + pDx, y: 125.0 + pDy), control: CGPoint(x: 128.725 + pDx, y: 123.0 + pDy))
            starsL.addQuadCurve(to: CGPoint(x: 126.725 + pDx, y: 140.0 + pDy), control: CGPoint(x: 128.725 + pDx, y: 127.0 + pDy))
            starsL.addQuadCurve(to: CGPoint(x: 111.725 + pDx, y: 125.0 + pDy), control: CGPoint(x: 124.725 + pDx, y: 127.0 + pDy))
            starsL.addQuadCurve(to: CGPoint(x: 126.725 + pDx, y: 110.0 + pDy), control: CGPoint(x: 124.725 + pDx, y: 123.0 + pDy))
            starsL.closeSubpath()
            // Star 2 (small)
            starsL.move(to: CGPoint(x: 142.725 + pDx, y: 130.0 + pDy))
            starsL.addQuadCurve(to: CGPoint(x: 150.725 + pDx, y: 138.0 + pDy), control: CGPoint(x: 143.725 + pDx, y: 137.0 + pDy))
            starsL.addQuadCurve(to: CGPoint(x: 142.725 + pDx, y: 146.0 + pDy), control: CGPoint(x: 143.725 + pDx, y: 139.0 + pDy))
            starsL.addQuadCurve(to: CGPoint(x: 134.725 + pDx, y: 138.0 + pDy), control: CGPoint(x: 141.725 + pDx, y: 139.0 + pDy))
            starsL.addQuadCurve(to: CGPoint(x: 142.725 + pDx, y: 130.0 + pDy), control: CGPoint(x: 141.725 + pDx, y: 137.0 + pDy))
            starsL.closeSubpath()

            ctx.drawLayer { layer in
                layer.clip(to: eyeCircleL)
                layer.clip(to: lidL)
                layer.fill(eyeCircleL, with: .color(eyeWhite))
                layer.fill(pupilL, with: .color(pupilColor))
                layer.fill(starsL, with: .color(.white))
            }

            // Right Eye + Star Sparkles
            let pupilR = Path(ellipseIn: CGRect(x: eyeR_center.x + pDx - pr, y: eyeR_center.y + pDy - pr, width: pr * 2, height: pr * 2))
            var starsR = Path()
            // Star 1 (large)
            starsR.move(to: CGPoint(x: 183.275 + pDx, y: 110.0 + pDy))
            starsR.addQuadCurve(to: CGPoint(x: 198.275 + pDx, y: 125.0 + pDy), control: CGPoint(x: 185.275 + pDx, y: 123.0 + pDy))
            starsR.addQuadCurve(to: CGPoint(x: 183.275 + pDx, y: 140.0 + pDy), control: CGPoint(x: 185.275 + pDx, y: 127.0 + pDy))
            starsR.addQuadCurve(to: CGPoint(x: 168.275 + pDx, y: 125.0 + pDy), control: CGPoint(x: 181.275 + pDx, y: 127.0 + pDy))
            starsR.addQuadCurve(to: CGPoint(x: 183.275 + pDx, y: 110.0 + pDy), control: CGPoint(x: 181.275 + pDx, y: 123.0 + pDy))
            starsR.closeSubpath()
            // Star 2 (small)
            starsR.move(to: CGPoint(x: 199.275 + pDx, y: 130.0 + pDy))
            starsR.addQuadCurve(to: CGPoint(x: 207.275 + pDx, y: 138.0 + pDy), control: CGPoint(x: 200.275 + pDx, y: 137.0 + pDy))
            starsR.addQuadCurve(to: CGPoint(x: 199.275 + pDx, y: 146.0 + pDy), control: CGPoint(x: 200.275 + pDx, y: 139.0 + pDy))
            starsR.addQuadCurve(to: CGPoint(x: 191.275 + pDx, y: 138.0 + pDy), control: CGPoint(x: 198.275 + pDx, y: 139.0 + pDy))
            starsR.addQuadCurve(to: CGPoint(x: 199.275 + pDx, y: 130.0 + pDy), control: CGPoint(x: 198.275 + pDx, y: 137.0 + pDy))
            starsR.closeSubpath()

            ctx.drawLayer { layer in
                layer.clip(to: eyeCircleR)
                layer.clip(to: lidR)
                layer.fill(eyeCircleR, with: .color(eyeWhite))
                layer.fill(pupilR, with: .color(pupilColor))
                layer.fill(starsR, with: .color(.white))
            }

        } else {
            // Neutral, Happy, Annoyed, Anxious, Grumpy, etc: circular eyes with dynamic lids & pupil tracking
            let happyLift = clampValue(pose.mouthCurve, 0, 1)
            let eyeY: Double = 132.0 - 13.0 * happyLift + (spec.parts.eyeY * 20.0)
            let baseEyeRadius: Double = 27.0 * spec.parts.eyeSize
            let eyeR_val: Double = clampValue(baseEyeRadius, 12, 45)

            let eyeCenters: [(x: Double, isLeft: Bool)]
            if spec.parts.eyeCount == 1 {
                eyeCenters = [(160.0, true)]
            } else {
                let spacingOffset = spec.parts.eyeSpacing * 145.0
                eyeCenters = [(160.0 - spacingOffset, true), (160.0 + spacingOffset, false)]
            }

            let pupilRadius: Double = isAnxious ? (eyeR_val * 0.22) : (eyeR_val * clampValue(spec.parts.pupilSize, 0.2, 0.6))
            let openFactor = clampValue(pose.eyeOpen * rig.blink, 0, 1)
            let maxTravel = eyeR_val - pupilRadius - 2.0

            for eye in eyeCenters {
                let ex = eye.x
                let ey = eyeY

                let eyeCircle = Path(ellipseIn: CGRect(x: ex - eyeR_val, y: ey - eyeR_val, width: eyeR_val * 2, height: eyeR_val * 2))

                var lidPath = Path()
                if happyLift > 0.4 {
                    // Curved happy squint lid
                    let lx = ex - eyeR_val - 2.0
                    let rx = ex + eyeR_val + 2.0
                    let midY = (ey + 3.74) - (1.0 - happyLift) * 8.0
                    let ctrlMidY = (ey - 6.26) - (1.0 - happyLift) * 8.0
                    lidPath.move(to: CGPoint(x: lx, y: ey - eyeR_val - 15))
                    lidPath.addLine(to: CGPoint(x: rx, y: ey - eyeR_val - 15))
                    lidPath.addLine(to: CGPoint(x: rx, y: midY))
                    lidPath.addQuadCurve(to: CGPoint(x: lx, y: midY), control: CGPoint(x: ex, y: ctrlMidY))
                    lidPath.closeSubpath()
                } else {
                    let lidDrop = (1.0 - openFactor) * (eyeR_val * 2.0)
                    let baseLidY = (ey - eyeR_val) + (isAnnoyed ? (eyeR_val) : 0.0) + lidDrop
                    let tiltOffset = pose.lidTilt * (eye.isLeft ? 10.0 : -10.0)

                    lidPath.move(to: CGPoint(x: ex - eyeR_val - 5, y: baseLidY - tiltOffset))
                    lidPath.addLine(to: CGPoint(x: ex + eyeR_val + 5, y: baseLidY + tiltOffset))
                    lidPath.addLine(to: CGPoint(x: ex + eyeR_val + 10, y: ey + eyeR_val + 15))
                    lidPath.addLine(to: CGPoint(x: ex - eyeR_val - 10, y: ey + eyeR_val + 15))
                    lidPath.closeSubpath()
                }

                let neutralOffsetX = (spec.parts.eyeCount == 1) ? 0.0 : (eye.isLeft ? 6.09 : -6.09)
                let happyOffsetX = (spec.parts.eyeCount == 1) ? 0.0 : -9.0
                let baseOffsetX = neutralOffsetX * (1.0 - happyLift) + happyOffsetX * happyLift
                let baseOffsetY = happyLift * 6.0
                let pDx = clampValue(baseOffsetX + lookDx, -maxTravel, maxTravel)
                let pDy = clampValue(baseOffsetY + lookDy, -maxTravel, maxTravel)

                let pupilCircle = Path(ellipseIn: CGRect(
                    x: ex + pDx - pupilRadius,
                    y: ey + pDy - pupilRadius,
                    width: pupilRadius * 2,
                    height: pupilRadius * 2
                ))

                ctx.drawLayer { layer in
                    layer.clip(to: eyeCircle)
                    layer.clip(to: lidPath)
                    layer.fill(eyeCircle, with: .color(eyeWhite))
                    layer.fill(pupilCircle, with: .color(pupilColor))
                }
            }
        }

        // 3. BROWS & EMOTION EXTRAS
        let browHex = palette.brow ?? (isExcited || isAnxious ? "#FFFFFF" : "#283D22")
        let browColor = Color(characterHex: browHex)

        if pose.browAmount > 0.05 {
            // Procedural eyebrows (driven by pose.browTilt, pose.browArch, pose.browY)
            let bY = 96.0 + pose.browY * 18.0
            let tilt = pose.browTilt * 14.0
            let arch = pose.browArch * 10.0

            if spec.parts.eyeCount == 1 {
                // Single wide expressive brow for Cyclops
                var brow = Path()
                brow.move(to: CGPoint(x: 132, y: bY))
                brow.addQuadCurve(to: CGPoint(x: 188, y: bY), control: CGPoint(x: 160, y: bY - arch))
                ctx.stroke(brow, with: .color(browColor), style: StrokeStyle(lineWidth: 6 * pose.browAmount, lineCap: .round))
            } else {
                let spacingOffset = spec.parts.eyeSpacing * 145.0
                let browL_center = 160.0 - spacingOffset
                let browR_center = 160.0 + spacingOffset

                var browL = Path()
                browL.move(to: CGPoint(x: browL_center - 21, y: bY + tilt))
                browL.addQuadCurve(to: CGPoint(x: browL_center + 21, y: bY - tilt), control: CGPoint(x: browL_center, y: bY - arch))
                ctx.stroke(browL, with: .color(browColor), style: StrokeStyle(lineWidth: 6 * pose.browAmount, lineCap: .round))

                var browR = Path()
                browR.move(to: CGPoint(x: browR_center - 21, y: bY - tilt))
                browR.addQuadCurve(to: CGPoint(x: browR_center + 21, y: bY + tilt), control: CGPoint(x: browR_center, y: bY - arch))
                ctx.stroke(browR, with: .color(browColor), style: StrokeStyle(lineWidth: 6 * pose.browAmount, lineCap: .round))
            }

        } else if isAnxious {
            // Worried brows from blobby-anxious.svg
            var browL = Path()
            browL.move(to: CGPoint(x: 120.9875, y: 90))
            browL.addQuadCurve(to: CGPoint(x: 148.9875, y: 80), control: CGPoint(x: 134.9875, y: 92))
            ctx.stroke(browL, with: .color(.white), style: StrokeStyle(lineWidth: 8, lineCap: .round))

            var browR = Path()
            browR.move(to: CGPoint(x: 171.0125, y: 80))
            browR.addQuadCurve(to: CGPoint(x: 199.0125, y: 90), control: CGPoint(x: 185.0125, y: 92))
            ctx.stroke(browR, with: .color(.white), style: StrokeStyle(lineWidth: 8, lineCap: .round))

        } else if isExcited {
            // Arched brows from blobby-excited.svg
            var browL = Path()
            browL.move(to: CGPoint(x: 145.725, y: 76))
            browL.addQuadCurve(to: CGPoint(x: 113.725, y: 90), control: CGPoint(x: 125.725, y: 76))
            ctx.stroke(browL, with: .color(.white), style: StrokeStyle(lineWidth: 8, lineCap: .round))

            var browR = Path()
            browR.move(to: CGPoint(x: 174.275, y: 76))
            browR.addQuadCurve(to: CGPoint(x: 206.275, y: 90), control: CGPoint(x: 194.275, y: 76))
            ctx.stroke(browR, with: .color(.white), style: StrokeStyle(lineWidth: 8, lineCap: .round))
        }

        if isSad {
            // Teardrop from blobby-sad.svg
            var tear = Path()
            tear.move(to: CGPoint(x: 219, y: 153))
            tear.addCurve(to: CGPoint(x: 211, y: 178), control1: CGPoint(x: 216, y: 162), control2: CGPoint(x: 207, y: 170))
            tear.addCurve(to: CGPoint(x: 231, y: 176), control1: CGPoint(x: 215, y: 187), control2: CGPoint(x: 230, y: 185))
            tear.addCurve(to: CGPoint(x: 219, y: 153), control1: CGPoint(x: 232, y: 169), control2: CGPoint(x: 223, y: 161))
            tear.closeSubpath()
            ctx.fill(tear, with: .color(Color(characterHex: palette.tear ?? "#78D9F4")))
        }

        // Blush cheek pads (e.g. Grumbleprick smitten / cactus crush)
        if pose.pad > 0.05 {
            let padColor = Color(characterHex: palette.pad ?? "#EBA081").opacity(pose.pad)
            let spacingOffset = (spec.parts.eyeCount == 1) ? 52.0 : (spec.parts.eyeSpacing * 145.0 + 26.0)
            let padL = Path(ellipseIn: CGRect(x: 160 - spacingOffset - 12, y: 166, width: 24, height: 14))
            let padR = Path(ellipseIn: CGRect(x: 160 + spacingOffset - 12, y: 166, width: 24, height: 14))
            ctx.fill(padL, with: .color(padColor))
            ctx.fill(padR, with: .color(padColor))
        }

        // 4. MOUTH: Continuous Spring-Driven Parametric Rig
        let curve = pose.mouthCurve                         // -1...1
        let open = clampValue(pose.mouthOpen, 0, 1)         // 0...1
        let widthParam = clampValue(pose.mouthWidth, 0, 1)  // 0...1

        let halfWidth = 25.6 + widthParam * 36.5
        let leftX = 160.0 - halfWidth
        let rightX = 160.0 + halfWidth

        let endY: Double
        let ctrlY: Double
        if curve >= 0 {
            endY = 193.0 - 15.0 * curve
            ctrlY = 193.0 + 26.5 * curve + 5.0 * open
        } else {
            endY = 193.0 - 12.0 * curve
            ctrlY = 193.0 + 36.0 * curve
        }

        var mouthPath = Path()
        mouthPath.move(to: CGPoint(x: leftX, y: endY))
        mouthPath.addQuadCurve(to: CGPoint(x: rightX, y: endY), control: CGPoint(x: 160.0, y: ctrlY))

        let strokeOuter = 35.0 + 34.0 * open
        let strokeInner = 8.0 + 29.0 * open

        if isCalm {
            // Calm: single gentle white stroke
            ctx.stroke(mouthPath, with: .color(mouthColor), style: StrokeStyle(lineWidth: 11, lineCap: .round))
        } else if isExcited || ((pose.teeth > 0.05 || pose.tongue > 0.05) && open > 0.15) {
            // Open cavity with tongue and teeth
            let teethColor = Color(characterHex: palette.teeth ?? "#FFFFFF")
            let tongueColor = Color(characterHex: palette.tongue ?? palette.body)
            let cavityColor = Color(characterHex: palette.cavity ?? "#050505")

            ctx.stroke(mouthPath, with: .color(mouthOutline), style: StrokeStyle(lineWidth: strokeOuter, lineCap: .round))
            ctx.stroke(mouthPath, with: .color(cavityColor), style: StrokeStyle(lineWidth: strokeInner, lineCap: .round))

            let cavityMask = mouthPath.strokedPath(StrokeStyle(lineWidth: strokeInner, lineCap: .round))
            ctx.drawLayer { layer in
                layer.clip(to: cavityMask)
                var tongue = Path()
                tongue.addEllipse(in: CGRect(x: 160 - 38, y: 228 - 18, width: 76, height: 36))
                layer.fill(tongue, with: .color(tongueColor))

                var teeth = Path()
                teeth.move(to: CGPoint(x: leftX + 4, y: endY - 12))
                teeth.addQuadCurve(to: CGPoint(x: rightX - 4, y: endY - 12), control: CGPoint(x: 160, y: endY + 14))
                layer.stroke(teeth, with: .color(teethColor), style: StrokeStyle(lineWidth: 13, lineCap: .round))
            }
        } else {
            // Neutral, Happy, Annoyed, Anxious, Sad, Grumpy, Prickly:
            // Continuous double-stroke pill that smoothly bends, stretches, and opens!
            ctx.stroke(mouthPath, with: .color(mouthOutline), style: StrokeStyle(lineWidth: strokeOuter, lineCap: .round))
            ctx.stroke(mouthPath, with: .color(mouthColor), style: StrokeStyle(lineWidth: strokeInner, lineCap: .round))
        }
    }
}
