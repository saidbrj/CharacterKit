import XCTest
import SwiftUI
@testable import CharacterKit

@MainActor
final class CharacterSpecTests: XCTestCase {

    func testBundledSampleLoads() {
        let spec = CharacterSpec.blobby
        XCTAssertEqual(spec.name, "Blobby")
        XCTAssertEqual(spec.version, 2)
        XCTAssertEqual(spec.parts.bodyShape, "cloud")
        XCTAssertEqual(spec.expressions.count, 7)
        XCTAssertNotNil(spec.expressions["neutral"])
        XCTAssertFalse(spec.expressionOrder.isEmpty)
        XCTAssertEqual(spec.defaultMood, "neutral")
    }

    func testDefaultsFillMissingFields() throws {
        let json = #"{"name":"Tiny","expressions":{"neutral":{}}}"#
        let spec = try CharacterSpec.load(from: Data(json.utf8))
        XCTAssertEqual(spec.parts.bumps, 3)
        XCTAssertEqual(spec.parts.eyeCount, 2)
        XCTAssertEqual(spec.expressions["neutral"]?.eyeOpen, 1)
        XCTAssertEqual(spec.expressions["neutral"]?.mouthWidth, 0.5)
        XCTAssertTrue(spec.idle.blink)
        XCTAssertEqual(spec.defaultMood, "neutral")
        XCTAssertEqual(spec.expressionOrder, ["neutral"])
        XCTAssertEqual(spec.touch.tap, "neutral")
        XCTAssertEqual(spec.touch.longPress, "neutral")
    }

    func testSanitizeClampsValuesAndFixesReferences() throws {
        let json = #"""
        {"name":"Bad",
         "parts":{"eyeCount":9,"eyeSize":99,"bumps":99,"bodyShape":"square"},
         "expressions":{"happy":{"eyeOpen":5,"lidTilt":9,"mouthCurve":-9}},
         "touch":{"tap":"missing","longPress":"happy","reactSeconds":99}}
        """#
        let spec = try CharacterSpec.load(from: Data(json.utf8))
        XCTAssertEqual(spec.parts.eyeCount, 2)
        XCTAssertEqual(spec.parts.eyeSize, 1.6, accuracy: 0.0001)
        XCTAssertEqual(spec.parts.bumps, 6)
        XCTAssertEqual(spec.parts.bodyShape, "cloud")
        XCTAssertEqual(spec.expressions["happy"]?.eyeOpen, 1)
        XCTAssertEqual(spec.expressions["happy"]?.lidTilt, 1)
        XCTAssertEqual(spec.expressions["happy"]?.mouthCurve, -1)
        XCTAssertNotNil(spec.expressions["neutral"])   // added automatically
        XCTAssertEqual(spec.touch.tap, spec.expressionOrder.first) // fell back to first expression
        XCTAssertEqual(spec.touch.longPress, "happy")
        XCTAssertEqual(spec.touch.reactSeconds, 5, accuracy: 0.0001)
    }

    func testOldV1FilesStillDecode() throws {
        // v1 used browAngle/browLift. They are ignored, not fatal.
        let json = #"{"name":"Old","version":1,"expressions":{"neutral":{"browAngle":0.5,"mouthCurve":0.3}}}"#
        let spec = try CharacterSpec.load(from: Data(json.utf8))
        XCTAssertEqual(spec.expressions["neutral"]?.lidTilt, 0)
        XCTAssertEqual(spec.expressions["neutral"]?.mouthCurve, 0.3)
    }

    func testRoundTrip() throws {
        let original = CharacterSpec.blobby
        let data = try JSONEncoder().encode(original)
        let decoded = try CharacterSpec.load(from: data)
        XCTAssertEqual(decoded, original)
    }

    func testSpringsOvershootThenSettle() {
        let spec = CharacterSpec.blobby
        let rig = RigState()
        rig.step(now: 0, spec: spec, reduceMotion: true)   // starts at neutral
        rig.baseMood = "happy"

        var maxOpen = 0.0
        for frame in 1...180 {
            rig.step(now: Double(frame) / 60.0, spec: spec, reduceMotion: true)
            maxOpen = max(maxOpen, rig.pose.mouthOpen)
        }
        let target = spec.expressions["happy"]?.mouthOpen ?? 1
        XCTAssertGreaterThan(maxOpen, target + 0.05)                 // visible overshoot
        XCTAssertEqual(rig.pose.mouthOpen, target, accuracy: 0.02)   // then settles
    }

    func testBodyShapesAndEyeCounts() {
        for shape in ["cloud", "blob", "round"] {
            for eyeCount in [1, 2] {
                var parts = Parts()
                parts.bodyShape = shape
                parts.eyeCount = eyeCount
                let spec = CharacterSpec(
                    name: "\(shape)_\(eyeCount)",
                    parts: parts,
                    expressions: ["neutral": ExpressionParams()]
                )

                let rig = RigState()
                rig.step(now: 0, spec: spec, reduceMotion: true)

                let view = CharacterView(spec: spec, mood: "neutral")
                _ = view.body

                if #available(macOS 13.0, iOS 16.0, *) {
                    let renderer = ImageRenderer(content: view.frame(width: 320, height: 320))
                    #if os(macOS)
                    _ = renderer.nsImage
                    #elseif os(iOS)
                    _ = renderer.uiImage
                    #endif
                }
            }
        }
    }

    func testBundledCharactersRenderAllExpressionsWithoutCrashing() throws {
        var characters: [CharacterSpec] = [
            CharacterSpec.current,
            CharacterSpec.blobby
        ]

        if let resourceURLs = Bundle.module.urls(forResourcesWithExtension: "json", subdirectory: nil) {
            for url in resourceURLs {
                let name = url.deletingPathExtension().lastPathComponent
                if let spec = try? CharacterSpec.load(named: name, in: .module), !characters.contains(where: { $0.name == spec.name }) {
                    characters.append(spec)
                }
            }
        }

        XCTAssertFalse(characters.isEmpty, "Should have bundled characters to test")

        for character in characters {
            let spec = character.sanitized()
            XCTAssertFalse(spec.expressionOrder.isEmpty, "\(spec.name) must have non-empty expressionOrder")
            XCTAssertNotNil(spec.expressions[spec.defaultMood], "\(spec.name) defaultMood '\(spec.defaultMood)' must exist in expressions")

            let allKeys = Set(spec.expressionOrder).union(spec.expressions.keys)
            for expressionName in allKeys {
                let rig = RigState()
                rig.baseMood = expressionName
                rig.step(now: 0, spec: spec, reduceMotion: true)
                rig.step(now: 0.1, spec: spec, reduceMotion: true)

                let view = CharacterView(spec: spec, mood: expressionName)
                _ = view.body

                if #available(macOS 13.0, iOS 16.0, *) {
                    let renderer = ImageRenderer(content: view.frame(width: 320, height: 320))
                    #if os(macOS)
                    _ = renderer.nsImage
                    #elseif os(iOS)
                    _ = renderer.uiImage
                    #endif
                }
            }
        }
    }
}
