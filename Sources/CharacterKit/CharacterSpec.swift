import Foundation

// MARK: - Helpers

@inline(__always)
func clampValue(_ value: Double, _ lo: Double, _ hi: Double) -> Double {
    min(max(value, lo), hi)
}

public enum CharacterSpecError: LocalizedError {
    case fileNotFound(String)
    case unsupportedVersion(Int)

    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let name):
            return "CharacterKit: could not find \(name).json in the bundle."
        case .unsupportedVersion(let v):
            return "CharacterKit: spec version \(v) is newer than supported (version 3). Please update CharacterKit."
        }
    }
}

// MARK: - Layout

public struct LayoutConfig: Codable, Equatable {
    public var mode: String
    public var faceCenterY: Double
    public var faceScale: Double
    public var faceMaxHeight: Double?
    public var topInset: Double

    public init(
        mode: String = "contained",
        faceCenterY: Double = 0.38,
        faceScale: Double = 0.55,
        faceMaxHeight: Double? = nil,
        topInset: Double = 0.08
    ) {
        self.mode = mode
        self.faceCenterY = faceCenterY
        self.faceScale = faceScale
        self.faceMaxHeight = faceMaxHeight
        self.topInset = topInset
    }

    enum CodingKeys: String, CodingKey {
        case mode, faceCenterY, faceScale, faceMaxHeight, topInset
    }

    public init(from decoder: Decoder) throws {
        let d = LayoutConfig()
        guard let c = try? decoder.container(keyedBy: CodingKeys.self) else {
            self = d
            return
        }
        mode = (try? c.decodeIfPresent(String.self, forKey: .mode)) ?? d.mode
        faceCenterY = (try? c.decodeIfPresent(Double.self, forKey: .faceCenterY)) ?? d.faceCenterY
        faceScale = (try? c.decodeIfPresent(Double.self, forKey: .faceScale)) ?? d.faceScale
        faceMaxHeight = try? c.decodeIfPresent(Double.self, forKey: .faceMaxHeight)
        topInset = (try? c.decodeIfPresent(Double.self, forKey: .topInset)) ?? d.topInset
    }

    public func clamped() -> LayoutConfig {
        let m = (mode.lowercased() == "fill") ? "fill" : "contained"
        return LayoutConfig(
            mode: m,
            faceCenterY: clampValue(faceCenterY, 0.2, 0.7),
            faceScale: clampValue(faceScale, 0.3, 1.2),
            faceMaxHeight: faceMaxHeight.map { clampValue($0, 0.1, 0.8) },
            topInset: clampValue(topInset, 0.0, 0.4)
        )
    }
}

// MARK: - Ear springs and configuration

public struct EarSpringConfig: Codable, Equatable {
    public var stiffness: Double
    public var damping: Double
    public var follow: Double

    public init(
        stiffness: Double = 140,
        damping: Double = 9,
        follow: Double = 0.6
    ) {
        self.stiffness = stiffness
        self.damping = damping
        self.follow = follow
    }

    enum CodingKeys: String, CodingKey {
        case stiffness, damping, follow
    }

    public init(from decoder: Decoder) throws {
        let d = EarSpringConfig()
        guard let c = try? decoder.container(keyedBy: CodingKeys.self) else {
            self = d
            return
        }
        stiffness = (try? c.decodeIfPresent(Double.self, forKey: .stiffness)) ?? d.stiffness
        damping = (try? c.decodeIfPresent(Double.self, forKey: .damping)) ?? d.damping
        follow = (try? c.decodeIfPresent(Double.self, forKey: .follow)) ?? d.follow
    }

    public func clamped() -> EarSpringConfig {
        EarSpringConfig(
            stiffness: clampValue(stiffness, 20, 400),
            damping: clampValue(damping, 2, 40),
            follow: clampValue(follow, 0, 1)
        )
    }
}

public struct EarsConfig: Codable, Equatable {
    public var style: String
    public var anchor: String
    public var length: Double
    public var width: Double
    public var spread: Double
    public var baseY: Double
    public var baseAngle: Double
    public var tipRoundness: Double
    public var bend: Double
    public var innerScale: Double
    public var spring: EarSpringConfig

    public init(
        style: String = "none",
        anchor: String? = nil,
        length: Double? = nil,
        width: Double? = nil,
        spread: Double = 0.45,
        baseY: Double? = nil,
        baseAngle: Double = 12,
        tipRoundness: Double? = nil,
        bend: Double = 0,
        innerScale: Double = 0.6,
        spring: EarSpringConfig = EarSpringConfig()
    ) {
        self.style = style
        let d = EarsConfig.defaults(for: style)
        self.anchor = anchor ?? d.anchor
        self.length = length ?? d.length
        self.width = width ?? d.width
        self.spread = spread
        self.baseY = baseY ?? d.baseY
        self.baseAngle = baseAngle
        self.tipRoundness = tipRoundness ?? d.tipRoundness
        self.bend = bend
        self.innerScale = innerScale
        self.spring = spring
    }

    public static func defaults(for style: String) -> (anchor: String, length: Double, width: Double, tipRoundness: Double, baseY: Double) {
        switch style.lowercased() {
        case "tall":
            return ("top", 0.9, 0.2, 0.8, -0.85)
        case "pointed":
            return ("top", 0.45, 0.3, 0.1, -0.85)
        case "round":
            return ("top", 0.25, 0.3, 1.0, -0.85)
        case "floppy":
            return ("side", 0.5, 0.28, 0.9, -0.1)
        case "elf":
            return ("side", 0.4, 0.2, 0.1, -0.1)
        default:
            return ("top", 0.6, 0.22, 0.8, -0.85)
        }
    }

    enum CodingKeys: String, CodingKey {
        case style, anchor, length, width, spread, baseY, baseAngle
        case tipRoundness, bend, innerScale, spring
    }

    public init(from decoder: Decoder) throws {
        let c = try? decoder.container(keyedBy: CodingKeys.self)
        let s = (try? c?.decodeIfPresent(String.self, forKey: .style)) ?? "none"
        self.style = s
        let d = EarsConfig.defaults(for: s)
        self.anchor = (try? c?.decodeIfPresent(String.self, forKey: .anchor)) ?? d.anchor
        self.length = (try? c?.decodeIfPresent(Double.self, forKey: .length)) ?? d.length
        self.width = (try? c?.decodeIfPresent(Double.self, forKey: .width)) ?? d.width
        self.spread = (try? c?.decodeIfPresent(Double.self, forKey: .spread)) ?? 0.45
        self.baseY = (try? c?.decodeIfPresent(Double.self, forKey: .baseY)) ?? d.baseY
        self.baseAngle = (try? c?.decodeIfPresent(Double.self, forKey: .baseAngle)) ?? 12
        self.tipRoundness = (try? c?.decodeIfPresent(Double.self, forKey: .tipRoundness)) ?? d.tipRoundness
        self.bend = (try? c?.decodeIfPresent(Double.self, forKey: .bend)) ?? 0
        self.innerScale = (try? c?.decodeIfPresent(Double.self, forKey: .innerScale)) ?? 0.6
        self.spring = (try? c?.decodeIfPresent(EarSpringConfig.self, forKey: .spring)) ?? EarSpringConfig()
    }

    public func clamped() -> EarsConfig {
        let validStyles = ["none", "tall", "pointed", "round", "floppy", "elf"]
        let st = validStyles.contains(style.lowercased()) ? style.lowercased() : "none"
        let anc = (anchor.lowercased() == "side") ? "side" : "top"
        return EarsConfig(
            style: st,
            anchor: anc,
            length: clampValue(length, 0.1, 1.5),
            width: clampValue(width, 0.05, 0.6),
            spread: clampValue(spread, 0, 1),
            baseY: clampValue(baseY, -1, 1),
            baseAngle: clampValue(baseAngle, -60, 60),
            tipRoundness: clampValue(tipRoundness, 0, 1),
            bend: clampValue(bend, -1, 1),
            innerScale: clampValue(innerScale, 0, 1),
            spring: spring.clamped()
        )
    }
}

// MARK: - Expression parameters (also used as the live pose)

/// The numbers that drive a face and ears. An "expression" is just a named set of these.
public struct ExpressionParams: Codable, Equatable {
    /// 0 = lids fully closed, 1 = fully open. The lid comes down from the top of the eye.
    public var eyeOpen: Double
    /// -1...1. Slant of the lids. Negative = inner corners lowered (angry/annoyed),
    /// positive = inner corners raised (worried/sad).
    public var lidTilt: Double
    /// -1...1. Bend of the mouth. Negative = frown/arch, positive = smile.
    public var mouthCurve: Double
    /// 0...1. How far the mouth opens. Above 0 the mouth gets a dark outline.
    public var mouthOpen: Double
    /// 0...1. Narrow to wide (0.5 = the character's base width).
    public var mouthWidth: Double
    /// -1...1. Positive = wider and shorter, negative = taller and thinner.
    public var bodySquash: Double

    // V3 extended attributes
    public var browAmount: Double
    public var browTilt: Double
    public var browArch: Double
    public var browY: Double
    public var sparkle: Double
    public var eyeSquint: Double
    public var teeth: Double
    public var tongue: Double
    public var pad: Double
    public var eyeStyle: Int
    public var eyeStyleBlend: Double
    public var tear: Double

    // Ears modifiers per expression
    public var earsPerk: Double
    public var earsTilt: Double
    public var earsSplay: Double

    // V3 eye overrides per expression
    public var eyeY: Double?
    public var eyePupil: Double?
    public var eyeSize: Double?
    public var eyeSpacing: Double?

    public init(
        eyeOpen: Double = 1,
        lidTilt: Double = 0,
        mouthCurve: Double = 0,
        mouthOpen: Double = 0,
        mouthWidth: Double = 0.5,
        bodySquash: Double = 0,
        browAmount: Double = 0,
        browTilt: Double = 0,
        browArch: Double = 0,
        browY: Double = 0,
        sparkle: Double = 0,
        eyeSquint: Double = 0,
        teeth: Double = 0,
        tongue: Double = 0,
        pad: Double = 0,
        eyeStyle: Int = 0,
        eyeStyleBlend: Double? = nil,
        tear: Double = 0,
        earsPerk: Double = 0,
        earsTilt: Double = 0,
        earsSplay: Double = 0,
        eyeY: Double? = nil,
        eyePupil: Double? = nil,
        eyeSize: Double? = nil,
        eyeSpacing: Double? = nil
    ) {
        self.eyeOpen = eyeOpen
        self.lidTilt = lidTilt
        self.mouthCurve = mouthCurve
        self.mouthOpen = mouthOpen
        self.mouthWidth = mouthWidth
        self.bodySquash = bodySquash
        self.browAmount = browAmount
        self.browTilt = browTilt
        self.browArch = browArch
        self.browY = browY
        self.sparkle = sparkle
        self.eyeSquint = eyeSquint
        self.teeth = teeth
        self.tongue = tongue
        self.pad = pad
        self.eyeStyle = eyeStyle
        self.eyeStyleBlend = eyeStyleBlend ?? Double(eyeStyle)
        self.tear = tear
        self.earsPerk = earsPerk
        self.earsTilt = earsTilt
        self.earsSplay = earsSplay
        self.eyeY = eyeY
        self.eyePupil = eyePupil
        self.eyeSize = eyeSize
        self.eyeSpacing = eyeSpacing
    }

    enum CodingKeys: String, CodingKey {
        case eyeOpen, lidTilt, mouthCurve, mouthOpen, mouthWidth, bodySquash
        case browAmount, browTilt, browArch, browY, sparkle, eyeSquint
        case teeth, tongue, pad, eyeStyle, eyeStyleBlend, tear
        case earsPerk, earsTilt, earsSplay
        case eyeY, eyePupil, eyeSize, eyeSpacing
    }

    private enum V3RootKeys: String, CodingKey {
        case eye, brow, mouth, body, sparkle, tear, ears
    }

    private enum V3EyeKeys: String, CodingKey {
        case open, lidTilt, squint, pupil, size, spacing, y, style
    }

    private enum V3BrowKeys: String, CodingKey {
        case amount, tilt, arch, y
    }

    private enum V3MouthKeys: String, CodingKey {
        case curve, open, width, pad, teeth, tongue
    }

    private enum V3BodyKeys: String, CodingKey {
        case squash
    }

    private enum V3EarsKeys: String, CodingKey {
        case perk, tilt, splay
    }

    public init(from decoder: Decoder) throws {
        let c = try? decoder.container(keyedBy: CodingKeys.self)
        var eOpen = try? c?.decodeIfPresent(Double.self, forKey: .eyeOpen)
        var lTilt = try? c?.decodeIfPresent(Double.self, forKey: .lidTilt)
        var mCurve = try? c?.decodeIfPresent(Double.self, forKey: .mouthCurve)
        var mOpen = try? c?.decodeIfPresent(Double.self, forKey: .mouthOpen)
        var mWidth = try? c?.decodeIfPresent(Double.self, forKey: .mouthWidth)
        var bSquash = try? c?.decodeIfPresent(Double.self, forKey: .bodySquash)

        var bAmt: Double = (try? c?.decodeIfPresent(Double.self, forKey: .browAmount)) ?? 0
        var bTlt: Double = (try? c?.decodeIfPresent(Double.self, forKey: .browTilt)) ?? 0
        var bArc: Double = (try? c?.decodeIfPresent(Double.self, forKey: .browArch)) ?? 0
        var bY: Double = (try? c?.decodeIfPresent(Double.self, forKey: .browY)) ?? 0
        var spk: Double = (try? c?.decodeIfPresent(Double.self, forKey: .sparkle)) ?? 0
        var sqnt: Double = (try? c?.decodeIfPresent(Double.self, forKey: .eyeSquint)) ?? 0
        var tth: Double = (try? c?.decodeIfPresent(Double.self, forKey: .teeth)) ?? 0
        var tng: Double = (try? c?.decodeIfPresent(Double.self, forKey: .tongue)) ?? 0
        var pd: Double = (try? c?.decodeIfPresent(Double.self, forKey: .pad)) ?? 0
        var eStyle: Int = (try? c?.decodeIfPresent(Int.self, forKey: .eyeStyle)) ?? 0
        let eStyleBlend: Double? = try? c?.decodeIfPresent(Double.self, forKey: .eyeStyleBlend)
        var tr: Double = (try? c?.decodeIfPresent(Double.self, forKey: .tear)) ?? 0
        var ePerk: Double = (try? c?.decodeIfPresent(Double.self, forKey: .earsPerk)) ?? 0
        var eTilt: Double = (try? c?.decodeIfPresent(Double.self, forKey: .earsTilt)) ?? 0
        var eSplay: Double = (try? c?.decodeIfPresent(Double.self, forKey: .earsSplay)) ?? 0
        var eY = try? c?.decodeIfPresent(Double.self, forKey: .eyeY)
        var ePupil = try? c?.decodeIfPresent(Double.self, forKey: .eyePupil)
        var eSize = try? c?.decodeIfPresent(Double.self, forKey: .eyeSize)
        var eSpacing = try? c?.decodeIfPresent(Double.self, forKey: .eyeSpacing)

        if let v3 = try? decoder.container(keyedBy: V3RootKeys.self) {
            if let eye = try? v3.nestedContainer(keyedBy: V3EyeKeys.self, forKey: .eye) {
                if eOpen == nil { eOpen = try? eye.decodeIfPresent(Double.self, forKey: .open) }
                if lTilt == nil { lTilt = try? eye.decodeIfPresent(Double.self, forKey: .lidTilt) }
                sqnt = (try? eye.decodeIfPresent(Double.self, forKey: .squint)) ?? sqnt
                eStyle = (try? eye.decodeIfPresent(Int.self, forKey: .style)) ?? eStyle
                if eY == nil { eY = try? eye.decodeIfPresent(Double.self, forKey: .y) }
                if ePupil == nil { ePupil = try? eye.decodeIfPresent(Double.self, forKey: .pupil) }
                if eSize == nil { eSize = try? eye.decodeIfPresent(Double.self, forKey: .size) }
                if eSpacing == nil { eSpacing = try? eye.decodeIfPresent(Double.self, forKey: .spacing) }
            }
            if let mouth = try? v3.nestedContainer(keyedBy: V3MouthKeys.self, forKey: .mouth) {
                if mCurve == nil { mCurve = try? mouth.decodeIfPresent(Double.self, forKey: .curve) }
                if mOpen == nil { mOpen = try? mouth.decodeIfPresent(Double.self, forKey: .open) }
                if mWidth == nil { mWidth = try? mouth.decodeIfPresent(Double.self, forKey: .width) }
                tth = (try? mouth.decodeIfPresent(Double.self, forKey: .teeth)) ?? tth
                tng = (try? mouth.decodeIfPresent(Double.self, forKey: .tongue)) ?? tng
                pd = (try? mouth.decodeIfPresent(Double.self, forKey: .pad)) ?? pd
            }
            if let body = try? v3.nestedContainer(keyedBy: V3BodyKeys.self, forKey: .body) {
                if bSquash == nil { bSquash = try? body.decodeIfPresent(Double.self, forKey: .squash) }
            }
            if let brow = try? v3.nestedContainer(keyedBy: V3BrowKeys.self, forKey: .brow) {
                bAmt = (try? brow.decodeIfPresent(Double.self, forKey: .amount)) ?? bAmt
                bTlt = (try? brow.decodeIfPresent(Double.self, forKey: .tilt)) ?? bTlt
                bArc = (try? brow.decodeIfPresent(Double.self, forKey: .arch)) ?? bArc
                bY = (try? brow.decodeIfPresent(Double.self, forKey: .y)) ?? bY
            }
            if let ears = try? v3.nestedContainer(keyedBy: V3EarsKeys.self, forKey: .ears) {
                ePerk = (try? ears.decodeIfPresent(Double.self, forKey: .perk)) ?? ePerk
                eTilt = (try? ears.decodeIfPresent(Double.self, forKey: .tilt)) ?? eTilt
                eSplay = (try? ears.decodeIfPresent(Double.self, forKey: .splay)) ?? eSplay
            }
            spk = (try? v3.decodeIfPresent(Double.self, forKey: .sparkle)) ?? spk
            tr = (try? v3.decodeIfPresent(Double.self, forKey: .tear)) ?? tr
        }

        eyeOpen = eOpen ?? 1
        lidTilt = lTilt ?? 0
        mouthCurve = mCurve ?? 0
        mouthOpen = mOpen ?? 0
        mouthWidth = mWidth ?? 0.5
        bodySquash = bSquash ?? 0
        browAmount = bAmt
        browTilt = bTlt
        browArch = bArc
        browY = bY
        sparkle = spk
        eyeSquint = sqnt
        teeth = tth
        tongue = tng
        pad = pd
        eyeStyle = eStyle
        eyeStyleBlend = eStyleBlend ?? Double(eStyle)
        tear = tr
        earsPerk = ePerk
        earsTilt = eTilt
        earsSplay = eSplay
        eyeY = eY
        eyePupil = ePupil
        eyeSize = eSize
        eyeSpacing = eSpacing
    }

    public func clamped() -> ExpressionParams {
        ExpressionParams(
            eyeOpen: clampValue(eyeOpen, 0, 1),
            lidTilt: clampValue(lidTilt, -1, 1),
            mouthCurve: clampValue(mouthCurve, -1, 1),
            mouthOpen: clampValue(mouthOpen, 0, 1),
            mouthWidth: clampValue(mouthWidth, 0, 1),
            bodySquash: clampValue(bodySquash, -1, 1),
            browAmount: clampValue(browAmount, 0, 1),
            browTilt: clampValue(browTilt, -1, 1),
            browArch: clampValue(browArch, -1, 1),
            browY: clampValue(browY, -1, 1),
            sparkle: clampValue(sparkle, 0, 1),
            eyeSquint: clampValue(eyeSquint, 0, 1),
            teeth: clampValue(teeth, 0, 1),
            tongue: clampValue(tongue, 0, 1),
            pad: clampValue(pad, 0, 1),
            eyeStyle: (eyeStyle == 1) ? 1 : 0,
            eyeStyleBlend: clampValue(eyeStyleBlend, 0, 1),
            tear: clampValue(tear, 0, 1),
            earsPerk: clampValue(earsPerk, -1, 1),
            earsTilt: clampValue(earsTilt, -1, 1),
            earsSplay: clampValue(earsSplay, -1, 1),
            eyeY: eyeY.map { clampValue($0, -1, 1) },
            eyePupil: eyePupil.map { clampValue($0, 0.1, 1) },
            eyeSize: eyeSize.map { clampValue($0, 0.1, 2) },
            eyeSpacing: eyeSpacing.map { clampValue($0, 0.05, 1.0) }
        )
    }

    /// Channel order used by the spring simulation in RigState (24 channels).
    public func values(parts: Parts? = nil) -> [Double] {
        let p = parts ?? Parts()
        return [
            eyeOpen,                                     // 0
            eyeSize ?? p.eyeSize,                       // 1
            eyeSpacing ?? p.eyeSpacing,                 // 2
            eyeY ?? p.eyeY,                             // 3
            eyePupil ?? p.pupilSize,                    // 4
            eyeSquint,                                   // 5
            lidTilt,                                     // 6
            eyeStyleBlend,                               // 7
            browAmount,                                  // 8
            browTilt,                                    // 9
            browArch,                                    // 10
            browY,                                       // 11
            mouthCurve,                                  // 12
            mouthOpen,                                   // 13
            mouthWidth,                                  // 14
            pad,                                         // 15
            teeth,                                       // 16
            tongue,                                      // 17
            tear,                                        // 18
            sparkle,                                     // 19
            earsPerk,                                    // 20
            earsTilt,                                    // 21
            earsSplay,                                   // 22
            bodySquash                                   // 23
        ]
    }

    public var values: [Double] {
        let p = Parts()
        return values(parts: p)
    }

    public init(values v: [Double], base: ExpressionParams = ExpressionParams()) {
        self.init(
            eyeOpen: v.count > 0 ? v[0] : base.eyeOpen,
            lidTilt: v.count > 6 ? v[6] : base.lidTilt,
            mouthCurve: v.count > 12 ? v[12] : base.mouthCurve,
            mouthOpen: v.count > 13 ? v[13] : base.mouthOpen,
            mouthWidth: v.count > 14 ? v[14] : base.mouthWidth,
            bodySquash: v.count > 23 ? v[23] : base.bodySquash,
            browAmount: v.count > 8 ? v[8] : base.browAmount,
            browTilt: v.count > 9 ? v[9] : base.browTilt,
            browArch: v.count > 10 ? v[10] : base.browArch,
            browY: v.count > 11 ? v[11] : base.browY,
            sparkle: v.count > 19 ? v[19] : base.sparkle,
            eyeSquint: v.count > 5 ? v[5] : base.eyeSquint,
            teeth: v.count > 16 ? v[16] : base.teeth,
            tongue: v.count > 17 ? v[17] : base.tongue,
            pad: v.count > 15 ? v[15] : base.pad,
            eyeStyle: v.count > 7 ? (v[7] >= 0.5 ? 1 : 0) : base.eyeStyle,
            eyeStyleBlend: v.count > 7 ? v[7] : base.eyeStyleBlend,
            tear: v.count > 18 ? v[18] : base.tear,
            earsPerk: v.count > 20 ? v[20] : base.earsPerk,
            earsTilt: v.count > 21 ? v[21] : base.earsTilt,
            earsSplay: v.count > 22 ? v[22] : base.earsSplay,
            eyeY: v.count > 3 ? v[3] : base.eyeY,
            eyePupil: v.count > 4 ? v[4] : base.eyePupil,
            eyeSize: v.count > 1 ? v[1] : base.eyeSize,
            eyeSpacing: v.count > 2 ? v[2] : base.eyeSpacing
        )
    }
}

// MARK: - Palette

public struct Palette: Codable, Equatable {
    public var body: String
    public var bodyShade: String
    public var eyeWhite: String
    public var pupil: String
    /// Mouth fill and the closed-mouth pill
    public var mouth: String
    /// Dark outline that fades in around an open mouth
    public var mouthOutline: String
    public var brow: String?
    public var sparkle: String?
    public var pad: String?
    public var cavity: String?
    public var tongue: String?
    public var tear: String?
    public var teeth: String?
    public var ear: String?
    public var earInner: String?

    public var effectiveEar: String { ear ?? body }
    public var effectiveEarInner: String { earInner ?? bodyShade.lightenedHex(factor: 0.25) }

    public init(
        body: String = "#7C5CF5",
        bodyShade: String = "#6A4AE6",
        eyeWhite: String = "#FFFFFF",
        pupil: String = "#14122B",
        mouth: String = "#FFFFFF",
        mouthOutline: String = "#2D1A8C",
        brow: String? = nil,
        sparkle: String? = nil,
        pad: String? = nil,
        cavity: String? = nil,
        tongue: String? = nil,
        tear: String? = nil,
        teeth: String? = nil,
        ear: String? = nil,
        earInner: String? = nil
    ) {
        self.body = body
        self.bodyShade = bodyShade
        self.eyeWhite = eyeWhite
        self.pupil = pupil
        self.mouth = mouth
        self.mouthOutline = mouthOutline
        self.brow = brow
        self.sparkle = sparkle
        self.pad = pad
        self.cavity = cavity
        self.tongue = tongue
        self.tear = tear
        self.teeth = teeth
        self.ear = ear
        self.earInner = earInner
    }

    enum CodingKeys: String, CodingKey {
        case body, bodyShade, eyeWhite, pupil, mouth, mouthOutline
        case brow, sparkle, pad, cavity, tongue, tear, teeth
        case ear, earInner
    }

    public init(from decoder: Decoder) throws {
        let d = Palette()
        guard let c = try? decoder.container(keyedBy: CodingKeys.self) else {
            self = d
            return
        }
        body = (try? c.decodeIfPresent(String.self, forKey: .body)) ?? d.body
        bodyShade = (try? c.decodeIfPresent(String.self, forKey: .bodyShade)) ?? d.bodyShade
        eyeWhite = (try? c.decodeIfPresent(String.self, forKey: .eyeWhite)) ?? d.eyeWhite
        pupil = (try? c.decodeIfPresent(String.self, forKey: .pupil)) ?? d.pupil
        mouth = (try? c.decodeIfPresent(String.self, forKey: .mouth)) ?? d.mouth
        mouthOutline = (try? c.decodeIfPresent(String.self, forKey: .mouthOutline)) ?? d.mouthOutline
        brow = try? c.decodeIfPresent(String.self, forKey: .brow)
        sparkle = try? c.decodeIfPresent(String.self, forKey: .sparkle)
        pad = try? c.decodeIfPresent(String.self, forKey: .pad)
        cavity = try? c.decodeIfPresent(String.self, forKey: .cavity)
        tongue = try? c.decodeIfPresent(String.self, forKey: .tongue)
        tear = try? c.decodeIfPresent(String.self, forKey: .tear)
        teeth = try? c.decodeIfPresent(String.self, forKey: .teeth)
        ear = try? c.decodeIfPresent(String.self, forKey: .ear)
        earInner = try? c.decodeIfPresent(String.self, forKey: .earInner)
    }
}

// MARK: - Parts

public struct Parts: Codable, Equatable {
    /// "cloud" (rounded body with scalloped top), "blob" (soft squircle) or "round"
    public var bodyShape: String
    /// 3...6 scallops on top of a cloud body
    public var bumps: Int
    /// 0...0.15 how far the cloud scallops stick out
    public var bumpiness: Double
    /// 1 or 2
    public var eyeCount: Int
    /// 0.5...1.6
    public var eyeSize: Double
    /// 0.15...0.6, distance of each eye from the centre line
    public var eyeSpacing: Double
    /// -0.5...0.2, vertical eye position (negative is higher)
    public var eyeY: Double
    /// 0.2...0.9
    public var pupilSize: Double
    /// 0.2...0.9, base mouth width (an expression's mouthWidth scales this)
    public var mouthWidth: Double
    /// 0.1...0.6, vertical mouth position (larger is lower)
    public var mouthY: Double
    /// 0.5...2
    public var mouthThickness: Double
    /// Optional ears configuration
    public var ears: EarsConfig?

    public init(
        bodyShape: String = "cloud",
        bumps: Int = 3,
        bumpiness: Double = 0.09,
        eyeCount: Int = 2,
        eyeSize: Double = 1.2,
        eyeSpacing: Double = 0.31,
        eyeY: Double = -0.10,
        pupilSize: Double = 0.45,
        mouthWidth: Double = 0.42,
        mouthY: Double = 0.30,
        mouthThickness: Double = 1.2,
        ears: EarsConfig? = nil
    ) {
        self.bodyShape = bodyShape
        self.bumps = bumps
        self.bumpiness = bumpiness
        self.eyeCount = eyeCount
        self.eyeSize = eyeSize
        self.eyeSpacing = eyeSpacing
        self.eyeY = eyeY
        self.pupilSize = pupilSize
        self.mouthWidth = mouthWidth
        self.mouthY = mouthY
        self.mouthThickness = mouthThickness
        self.ears = ears
    }

    enum CodingKeys: String, CodingKey {
        case bodyShape, bumps, bumpiness, eyeCount, eyeSize, eyeSpacing, eyeY
        case pupilSize, mouthWidth, mouthY, mouthThickness, ears
    }

    public init(from decoder: Decoder) throws {
        let d = Parts()
        guard let c = try? decoder.container(keyedBy: CodingKeys.self) else {
            self = d
            return
        }
        bodyShape = (try? c.decodeIfPresent(String.self, forKey: .bodyShape)) ?? d.bodyShape
        bumps = (try? c.decodeIfPresent(Int.self, forKey: .bumps)) ?? d.bumps
        bumpiness = (try? c.decodeIfPresent(Double.self, forKey: .bumpiness)) ?? d.bumpiness
        eyeCount = (try? c.decodeIfPresent(Int.self, forKey: .eyeCount)) ?? d.eyeCount
        eyeSize = (try? c.decodeIfPresent(Double.self, forKey: .eyeSize)) ?? d.eyeSize
        eyeSpacing = (try? c.decodeIfPresent(Double.self, forKey: .eyeSpacing)) ?? d.eyeSpacing
        eyeY = (try? c.decodeIfPresent(Double.self, forKey: .eyeY)) ?? d.eyeY
        pupilSize = (try? c.decodeIfPresent(Double.self, forKey: .pupilSize)) ?? d.pupilSize
        mouthWidth = (try? c.decodeIfPresent(Double.self, forKey: .mouthWidth)) ?? d.mouthWidth
        mouthY = (try? c.decodeIfPresent(Double.self, forKey: .mouthY)) ?? d.mouthY
        mouthThickness = (try? c.decodeIfPresent(Double.self, forKey: .mouthThickness)) ?? d.mouthThickness
        ears = try? c.decodeIfPresent(EarsConfig.self, forKey: .ears)
    }

    public func clamped() -> Parts {
        let validShapes = ["cloud", "blob", "round"]
        let shape = validShapes.contains(bodyShape.lowercased()) ? bodyShape.lowercased() : "cloud"
        return Parts(
            bodyShape: shape,
            bumps: min(max(bumps, 3), 6),
            bumpiness: clampValue(bumpiness, 0, 0.15),
            eyeCount: min(max(eyeCount, 1), 2),
            eyeSize: clampValue(eyeSize, 0.5, 1.6),
            eyeSpacing: clampValue(eyeSpacing, 0.15, 0.6),
            eyeY: clampValue(eyeY, -0.5, 0.2),
            pupilSize: clampValue(pupilSize, 0.2, 0.9),
            mouthWidth: clampValue(mouthWidth, 0.2, 0.9),
            mouthY: clampValue(mouthY, 0.1, 0.6),
            mouthThickness: clampValue(mouthThickness, 0.5, 2),
            ears: ears?.clamped()
        )
    }
}

// MARK: - Touch and idle behaviour

public struct TouchConfig: Codable, Equatable {
    /// Expression name to show briefly on tap (nil = no reaction)
    public var tap: String?
    /// Expression name to hold while long-pressing (nil = no reaction)
    public var longPress: String?
    /// Pupils follow the finger while touching
    public var dragLooksAt: Bool
    /// How long a tap/long-press reaction lasts before returning to the base mood
    public var reactSeconds: Double
    /// 0...2. Strength of the squash-and-stretch bounce on tap
    public var tapBounce: Double
    /// Light haptic tap on iOS
    public var haptics: Bool
    /// Hold threshold in seconds before longPress fires (0.2...5, default 1.0)
    public var holdSeconds: Double
    /// Ear flick strength on tap (0...1, default 1.0)
    public var earFlick: Double
    /// How far ears lean toward the finger while dragging (0...1, default 0.6)
    public var earLean: Double

    public init(
        tap: String? = nil,
        longPress: String? = nil,
        dragLooksAt: Bool = true,
        reactSeconds: Double = 1.2,
        tapBounce: Double = 1,
        haptics: Bool = true,
        holdSeconds: Double = 1.0,
        earFlick: Double = 1.0,
        earLean: Double = 0.6
    ) {
        self.tap = tap
        self.longPress = longPress
        self.dragLooksAt = dragLooksAt
        self.reactSeconds = reactSeconds
        self.tapBounce = tapBounce
        self.haptics = haptics
        self.holdSeconds = holdSeconds
        self.earFlick = earFlick
        self.earLean = earLean
    }

    enum CodingKeys: String, CodingKey {
        case tap, longPress, dragLooksAt, reactSeconds, tapBounce, haptics
        case holdSeconds, earFlick, earLean
    }

    public init(from decoder: Decoder) throws {
        let d = TouchConfig()
        guard let c = try? decoder.container(keyedBy: CodingKeys.self) else {
            self = d
            return
        }
        tap = try? c.decodeIfPresent(String.self, forKey: .tap)
        longPress = try? c.decodeIfPresent(String.self, forKey: .longPress)
        dragLooksAt = (try? c.decodeIfPresent(Bool.self, forKey: .dragLooksAt)) ?? d.dragLooksAt
        reactSeconds = (try? c.decodeIfPresent(Double.self, forKey: .reactSeconds)) ?? d.reactSeconds
        tapBounce = (try? c.decodeIfPresent(Double.self, forKey: .tapBounce)) ?? d.tapBounce
        haptics = (try? c.decodeIfPresent(Bool.self, forKey: .haptics)) ?? d.haptics
        holdSeconds = (try? c.decodeIfPresent(Double.self, forKey: .holdSeconds)) ?? d.holdSeconds
        earFlick = (try? c.decodeIfPresent(Double.self, forKey: .earFlick)) ?? d.earFlick
        earLean = (try? c.decodeIfPresent(Double.self, forKey: .earLean)) ?? d.earLean
    }
}

public struct IdleConfig: Codable, Equatable {
    public var blink: Bool
    public var breathe: Bool
    public var lookAround: Bool
    public var earTwitch: Bool

    public init(
        blink: Bool = true,
        breathe: Bool = true,
        lookAround: Bool = true,
        earTwitch: Bool = false
    ) {
        self.blink = blink
        self.breathe = breathe
        self.lookAround = lookAround
        self.earTwitch = earTwitch
    }

    enum CodingKeys: String, CodingKey {
        case blink, breathe, lookAround, earTwitch
    }

    public init(from decoder: Decoder) throws {
        if let c = try? decoder.container(keyedBy: CodingKeys.self) {
            blink = (try? c.decodeIfPresent(Bool.self, forKey: .blink)) ?? true
            breathe = (try? c.decodeIfPresent(Bool.self, forKey: .breathe)) ?? true
            lookAround = (try? c.decodeIfPresent(Bool.self, forKey: .lookAround)) ?? true
            earTwitch = (try? c.decodeIfPresent(Bool.self, forKey: .earTwitch)) ?? false
        } else {
            blink = true
            breathe = true
            lookAround = true
            earTwitch = false
        }
    }
}

// MARK: - CharacterSpec

public struct CharacterSpec: Codable, Equatable {
    public var name: String
    public var version: Int
    public var schemaMinor: Int?
    public var layout: LayoutConfig
    public var palette: Palette
    public var parts: Parts
    /// Named expressions. "neutral" is required and is added automatically if missing.
    public var expressions: [String: ExpressionParams]
    /// Display and cycling order for expressions
    public var expressionOrder: [String]
    /// Base starting expression
    public var defaultMood: String
    public var touch: TouchConfig
    public var idle: IdleConfig

    public init(
        name: String = "Character",
        version: Int = 3,
        schemaMinor: Int? = 1,
        layout: LayoutConfig = LayoutConfig(),
        palette: Palette = Palette(),
        parts: Parts = Parts(),
        expressions: [String: ExpressionParams] = ["neutral": ExpressionParams()],
        expressionOrder: [String]? = nil,
        defaultMood: String? = nil,
        touch: TouchConfig = TouchConfig(),
        idle: IdleConfig = IdleConfig()
    ) {
        self.name = name
        self.version = version
        self.schemaMinor = schemaMinor
        self.layout = layout
        self.palette = palette
        self.parts = parts
        self.expressions = expressions
        let order = expressionOrder ?? (expressions.keys.contains("neutral")
            ? (["neutral"] + expressions.keys.filter { $0 != "neutral" }.sorted())
            : expressions.keys.sorted())
        self.expressionOrder = order.isEmpty ? ["neutral"] : order
        self.defaultMood = defaultMood ?? self.expressionOrder.first ?? "neutral"
        self.touch = touch
        self.idle = idle
    }

    enum CodingKeys: String, CodingKey {
        case name, version, schemaMinor, layout, palette, parts, expressions, expressionOrder, defaultMood, touch, idle
    }

    public init(from decoder: Decoder) throws {
        let d = CharacterSpec()
        guard let c = try? decoder.container(keyedBy: CodingKeys.self) else {
            self = d
            return
        }
        let decodedVersion = (try? c.decodeIfPresent(Int.self, forKey: .version)) ?? 3
        if decodedVersion > 3 {
            throw CharacterSpecError.unsupportedVersion(decodedVersion)
        }
        version = decodedVersion
        schemaMinor = try? c.decodeIfPresent(Int.self, forKey: .schemaMinor)
        layout = (try? c.decodeIfPresent(LayoutConfig.self, forKey: .layout)) ?? LayoutConfig()
        name = (try? c.decodeIfPresent(String.self, forKey: .name)) ?? "Character"
        palette = (try? c.decodeIfPresent(Palette.self, forKey: .palette)) ?? Palette()
        parts = (try? c.decodeIfPresent(Parts.self, forKey: .parts)) ?? Parts()
        expressions = (try? c.decodeIfPresent([String: ExpressionParams].self, forKey: .expressions)) ?? [:]
        let decodedOrder = try? c.decodeIfPresent([String].self, forKey: .expressionOrder)
        let decodedDefaultMood = try? c.decodeIfPresent(String.self, forKey: .defaultMood)
        touch = (try? c.decodeIfPresent(TouchConfig.self, forKey: .touch)) ?? TouchConfig()
        idle = (try? c.decodeIfPresent(IdleConfig.self, forKey: .idle)) ?? IdleConfig()

        if let decodedOrder, !decodedOrder.isEmpty {
            expressionOrder = decodedOrder
        } else if expressions.keys.contains("neutral") {
            expressionOrder = ["neutral"] + expressions.keys.filter { $0 != "neutral" }.sorted()
        } else {
            expressionOrder = expressions.keys.sorted()
        }
        if expressionOrder.isEmpty {
            expressionOrder = ["neutral"]
        }
        defaultMood = decodedDefaultMood ?? expressionOrder.first ?? "neutral"
    }

    /// Returns a safe copy: values clamped, "neutral" guaranteed, touch fallbacks resolved, missing fields defaulted.
    public func sanitized() -> CharacterSpec {
        var copy = self
        copy.layout = layout.clamped()
        copy.parts = parts.clamped()
        var cleaned: [String: ExpressionParams] = [:]
        for (key, value) in expressions {
            cleaned[key] = value.clamped()
        }
        if cleaned["neutral"] == nil {
            cleaned["neutral"] = ExpressionParams()
        }
        copy.expressions = cleaned

        // Synchronize and clean expressionOrder
        var orderedList: [String] = []
        for item in copy.expressionOrder where cleaned[item] != nil && !orderedList.contains(item) {
            orderedList.append(item)
        }
        for key in cleaned.keys.sorted() where !orderedList.contains(key) {
            if key == "neutral" {
                orderedList.insert(key, at: 0)
            } else {
                orderedList.append(key)
            }
        }
        if orderedList.isEmpty {
            orderedList = ["neutral"]
        }
        copy.expressionOrder = orderedList

        let firstExpr = orderedList.first ?? "neutral"

        // defaultMood fallback
        if cleaned[copy.defaultMood] == nil {
            copy.defaultMood = firstExpr
        }

        // Touch tap / longPress fall back to first expression if missing or unknown
        if let tap = copy.touch.tap, cleaned[tap] != nil {
            // Keep valid tap
        } else {
            copy.touch.tap = firstExpr
        }

        if let hold = copy.touch.longPress, cleaned[hold] != nil {
            // Keep valid longPress
        } else {
            copy.touch.longPress = firstExpr
        }

        copy.touch.reactSeconds = clampValue(copy.touch.reactSeconds, 0.2, 5)
        copy.touch.tapBounce = clampValue(copy.touch.tapBounce, 0, 2)
        copy.touch.holdSeconds = clampValue(copy.touch.holdSeconds, 0.2, 5)
        copy.touch.earFlick = clampValue(copy.touch.earFlick, 0, 1)
        copy.touch.earLean = clampValue(copy.touch.earLean, 0, 1)
        return copy
    }

    // MARK: Loading

    /// Decode and sanitize a spec exported from the editor.
    public static func load(from data: Data) throws -> CharacterSpec {
        try JSONDecoder().decode(CharacterSpec.self, from: data).sanitized()
    }

    /// Load `<name>.json` from a bundle (your app bundle by default, falling back to CharacterKit module).
    public static func load(named name: String, in bundle: Bundle = .main) throws -> CharacterSpec {
        if name.lowercased() == "current" {
            return CharacterSpec.current
        }
        let url = bundle.url(forResource: name, withExtension: "json")
            ?? Bundle.module.url(forResource: name, withExtension: "json")
        guard let url else {
            throw CharacterSpecError.fileNotFound(name)
        }
        return try load(from: Data(contentsOf: url))
    }

    /// The bundled sample character.
    public static var blobby: CharacterSpec {
        (try? load(named: "blobby", in: .module)) ?? CharacterSpec(name: "Blobby")
    }
}
