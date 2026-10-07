import Foundation

// MARK: - Helpers

@inline(__always)
func clampValue(_ value: Double, _ lo: Double, _ hi: Double) -> Double {
    min(max(value, lo), hi)
}

public enum CharacterSpecError: LocalizedError {
    case fileNotFound(String)

    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let name):
            return "CharacterKit: could not find \(name).json in the bundle."
        }
    }
}

// MARK: - Expression parameters (also used as the live pose)

/// The six numbers that drive a face. An "expression" is just a named set of these.
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
        pad: Double = 0
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
    }

    enum CodingKeys: String, CodingKey {
        case eyeOpen, lidTilt, mouthCurve, mouthOpen, mouthWidth, bodySquash
    }

    private enum V3RootKeys: String, CodingKey {
        case eye, brow, mouth, body, sparkle, tear
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

    public init(from decoder: Decoder) throws {
        let c = try? decoder.container(keyedBy: CodingKeys.self)
        var eOpen = try? c?.decodeIfPresent(Double.self, forKey: .eyeOpen)
        var lTilt = try? c?.decodeIfPresent(Double.self, forKey: .lidTilt)
        var mCurve = try? c?.decodeIfPresent(Double.self, forKey: .mouthCurve)
        var mOpen = try? c?.decodeIfPresent(Double.self, forKey: .mouthOpen)
        var mWidth = try? c?.decodeIfPresent(Double.self, forKey: .mouthWidth)
        var bSquash = try? c?.decodeIfPresent(Double.self, forKey: .bodySquash)

        var bAmt: Double = 0
        var bTlt: Double = 0
        var bArc: Double = 0
        var bY: Double = 0
        var spk: Double = 0
        var sqnt: Double = 0
        var tth: Double = 0
        var tng: Double = 0
        var pd: Double = 0

        if let v3 = try? decoder.container(keyedBy: V3RootKeys.self) {
            if let eye = try? v3.nestedContainer(keyedBy: V3EyeKeys.self, forKey: .eye) {
                if eOpen == nil { eOpen = try? eye.decodeIfPresent(Double.self, forKey: .open) }
                if lTilt == nil { lTilt = try? eye.decodeIfPresent(Double.self, forKey: .lidTilt) }
                sqnt = (try? eye.decodeIfPresent(Double.self, forKey: .squint)) ?? 0
            }
            if let mouth = try? v3.nestedContainer(keyedBy: V3MouthKeys.self, forKey: .mouth) {
                if mCurve == nil { mCurve = try? mouth.decodeIfPresent(Double.self, forKey: .curve) }
                if mOpen == nil { mOpen = try? mouth.decodeIfPresent(Double.self, forKey: .open) }
                if mWidth == nil { mWidth = try? mouth.decodeIfPresent(Double.self, forKey: .width) }
                tth = (try? mouth.decodeIfPresent(Double.self, forKey: .teeth)) ?? 0
                tng = (try? mouth.decodeIfPresent(Double.self, forKey: .tongue)) ?? 0
                pd = (try? mouth.decodeIfPresent(Double.self, forKey: .pad)) ?? 0
            }
            if let body = try? v3.nestedContainer(keyedBy: V3BodyKeys.self, forKey: .body) {
                if bSquash == nil { bSquash = try? body.decodeIfPresent(Double.self, forKey: .squash) }
            }
            if let brow = try? v3.nestedContainer(keyedBy: V3BrowKeys.self, forKey: .brow) {
                bAmt = (try? brow.decodeIfPresent(Double.self, forKey: .amount)) ?? 0
                bTlt = (try? brow.decodeIfPresent(Double.self, forKey: .tilt)) ?? 0
                bArc = (try? brow.decodeIfPresent(Double.self, forKey: .arch)) ?? 0
                bY = (try? brow.decodeIfPresent(Double.self, forKey: .y)) ?? 0
            }
            spk = (try? v3.decodeIfPresent(Double.self, forKey: .sparkle)) ?? 0
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
    }

    func clamped() -> ExpressionParams {
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
            eyeSquint: clampValue(eyeSquint, -1, 1),
            teeth: clampValue(teeth, 0, 1),
            tongue: clampValue(tongue, 0, 1),
            pad: clampValue(pad, 0, 1)
        )
    }

    /// Channel order used by the spring simulation in RigState.
    var values: [Double] {
        [eyeOpen, lidTilt, mouthCurve, mouthOpen, mouthWidth, bodySquash]
    }

    init(values v: [Double]) {
        self.init(
            eyeOpen: v[0],
            lidTilt: v[1],
            mouthCurve: v[2],
            mouthOpen: v[3],
            mouthWidth: v[4],
            bodySquash: v[5]
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
        teeth: String? = nil
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
    }

    enum CodingKeys: String, CodingKey {
        case body, bodyShade, eyeWhite, pupil, mouth, mouthOutline
        case brow, sparkle, pad, cavity, tongue, tear, teeth
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
        mouthThickness: Double = 1.2
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
    }

    enum CodingKeys: String, CodingKey {
        case bodyShape, bumps, bumpiness, eyeCount, eyeSize, eyeSpacing, eyeY
        case pupilSize, mouthWidth, mouthY, mouthThickness
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
    }

    func clamped() -> Parts {
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
            mouthThickness: clampValue(mouthThickness, 0.5, 2)
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

    public init(
        tap: String? = nil,
        longPress: String? = nil,
        dragLooksAt: Bool = true,
        reactSeconds: Double = 1.2,
        tapBounce: Double = 1,
        haptics: Bool = true
    ) {
        self.tap = tap
        self.longPress = longPress
        self.dragLooksAt = dragLooksAt
        self.reactSeconds = reactSeconds
        self.tapBounce = tapBounce
        self.haptics = haptics
    }

    enum CodingKeys: String, CodingKey {
        case tap, longPress, dragLooksAt, reactSeconds, tapBounce, haptics
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
    }
}

public struct IdleConfig: Codable, Equatable {
    public var blink: Bool
    public var breathe: Bool
    public var lookAround: Bool

    public init(blink: Bool = true, breathe: Bool = true, lookAround: Bool = true) {
        self.blink = blink
        self.breathe = breathe
        self.lookAround = lookAround
    }

    enum CodingKeys: String, CodingKey {
        case blink, breathe, lookAround
    }

    public init(from decoder: Decoder) throws {
        if let c = try? decoder.container(keyedBy: CodingKeys.self) {
            blink = (try? c.decodeIfPresent(Bool.self, forKey: .blink)) ?? true
            breathe = (try? c.decodeIfPresent(Bool.self, forKey: .breathe)) ?? true
            lookAround = (try? c.decodeIfPresent(Bool.self, forKey: .lookAround)) ?? true
        } else {
            blink = true
            breathe = true
            lookAround = true
        }
    }
}

// MARK: - CharacterSpec

public struct CharacterSpec: Codable, Equatable {
    public var name: String
    public var version: Int
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
        case name, version, palette, parts, expressions, expressionOrder, defaultMood, touch, idle
    }

    public init(from decoder: Decoder) throws {
        let d = CharacterSpec()
        guard let c = try? decoder.container(keyedBy: CodingKeys.self) else {
            self = d
            return
        }
        name = (try? c.decodeIfPresent(String.self, forKey: .name)) ?? "Character"
        version = (try? c.decodeIfPresent(Int.self, forKey: .version)) ?? 3
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
        return copy
    }

    // MARK: Loading

    /// Decode and sanitize a spec exported from the editor.
    public static func load(from data: Data) throws -> CharacterSpec {
        try JSONDecoder().decode(CharacterSpec.self, from: data).sanitized()
    }

    /// Load `<name>.json` from a bundle (your app bundle by default, falling back to CharacterKit module).
    public static func load(named name: String, in bundle: Bundle = .main) throws -> CharacterSpec {
        if name.lowercased() == "current" || name.lowercased() == CharacterSpec.current.name.lowercased() {
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
