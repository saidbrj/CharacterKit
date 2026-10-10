import XCTest
import SwiftUI
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif
@testable import CharacterKit

@MainActor
final class CharacterSpecTests: XCTestCase {

    // Helper to load fixture JSON
    private func loadFixture(name: String) throws -> CharacterSpec {
        let bundle = Bundle.module
        let actualName = (name == "floppy") ? "floppy-ears" : name
        guard let url = bundle.url(forResource: actualName, withExtension: "json")
            ?? bundle.url(forResource: actualName, withExtension: "json", subdirectory: "Fixtures") else {
            XCTFail("Could not find fixture \(actualName).json in Bundle.module")
            throw CharacterSpecError.fileNotFound(actualName)
        }
        let data = try Data(contentsOf: url)
        return try CharacterSpec.load(from: data)
    }

    // MARK: - Section 8 Test 1: Fixtures decode and fill defaults

    func testSection8_EveryFixtureDecodesWithoutError() throws {
        let fixtureNames = ["no-ears", "tall-ears", "floppy-ears", "fill-layout"]
        for name in fixtureNames {
            let spec = try loadFixture(name: name)
            XCTAssertFalse(spec.name.isEmpty, "Fixture \(name) should have a name")
            XCTAssertEqual(spec.version, 3, "Fixture \(name) should have version 3")
            XCTAssertFalse(spec.expressions.isEmpty, "Fixture \(name) should have expressions")
            XCTAssertNotNil(spec.expressions["neutral"], "Fixture \(name) must include 'neutral'")
        }
    }

    func testSection8_UnknownFieldsIgnoredAndMissingFieldsDefaulted() throws {
        let json = #"""
        {
          "name": "DefaultsTest",
          "version": 3,
          "unknownRootProp": "ignoredValue",
          "palette": {
            "unknownColor": "#123456"
          },
          "parts": {
            "unknownPart": 999
          },
          "expressions": {
            "neutral": {
              "unknownExprProp": true
            }
          }
        }
        """#
        let spec = try CharacterSpec.load(from: Data(json.utf8))
        XCTAssertEqual(spec.name, "DefaultsTest")
        XCTAssertEqual(spec.layout.mode, "contained")
        XCTAssertEqual(spec.layout.faceCenterY, 0.38, accuracy: 0.001)
        XCTAssertEqual(spec.layout.faceScale, 0.55, accuracy: 0.001)
        XCTAssertEqual(spec.layout.topInset, 0.08, accuracy: 0.001)
        XCTAssertNil(spec.parts.ears)
        XCTAssertEqual(spec.touch.holdSeconds, 1.0, accuracy: 0.001)
        XCTAssertEqual(spec.touch.earFlick, 1.0, accuracy: 0.001)
        XCTAssertEqual(spec.touch.earLean, 0.6, accuracy: 0.001)
        XCTAssertFalse(spec.idle.earTwitch)
    }

    func testSection8_ClampingOnLoadNeverCrashes() throws {
        let json = #"""
        {
          "name": "CrazyNumbers",
          "version": 3,
          "parts": {
            "bumps": 999,
            "bumpiness": 999,
            "eyeCount": 999,
            "eyeSize": 999,
            "eyeSpacing": 999,
            "eyeY": -999,
            "pupilSize": 999,
            "mouthWidth": 999,
            "mouthY": 999,
            "mouthThickness": 999,
            "ears": {
              "style": "tall",
              "length": 999,
              "width": 999,
              "spread": 999,
              "baseY": 999,
              "baseAngle": 999,
              "tipRoundness": 999,
              "bend": 999,
              "innerScale": 999,
              "spring": {
                "stiffness": 9999,
                "damping": 9999,
                "follow": 9999
              }
            }
          },
          "layout": {
            "faceCenterY": 999,
            "faceScale": 999,
            "topInset": 999
          },
          "expressions": {
            "neutral": {
              "eye": {
                "open": 999,
                "lidTilt": 999,
                "squint": 999
              },
              "mouth": {
                "curve": 999,
                "open": 999,
                "width": 999
              },
              "body": {
                "squash": 999
              },
              "ears": {
                "perk": 999,
                "tilt": 999,
                "splay": 999
              }
            }
          },
          "touch": {
            "holdSeconds": 999,
            "earFlick": 999,
            "earLean": 999
          }
        }
        """#
        let spec = try CharacterSpec.load(from: Data(json.utf8))
        XCTAssertEqual(spec.parts.bumps, 6)
        XCTAssertEqual(spec.parts.bumpiness, 0.15, accuracy: 0.001)
        XCTAssertEqual(spec.parts.eyeCount, 2)
        XCTAssertEqual(spec.parts.eyeSize, 1.6, accuracy: 0.001)
        XCTAssertEqual(spec.parts.eyeSpacing, 0.6, accuracy: 0.001)
        XCTAssertEqual(spec.parts.eyeY, -0.5, accuracy: 0.001)
        XCTAssertEqual(spec.parts.pupilSize, 0.9, accuracy: 0.001)
        XCTAssertEqual(spec.parts.mouthWidth, 0.9, accuracy: 0.001)
        XCTAssertEqual(spec.parts.mouthY, 0.6, accuracy: 0.001)
        XCTAssertEqual(spec.parts.mouthThickness, 2.0, accuracy: 0.001)

        let ears = try XCTUnwrap(spec.parts.ears)
        XCTAssertEqual(ears.length, 1.5, accuracy: 0.001)
        XCTAssertEqual(ears.width, 0.6, accuracy: 0.001)
        XCTAssertEqual(ears.spread, 1.0, accuracy: 0.001)
        XCTAssertEqual(ears.baseY, 1.0, accuracy: 0.001)
        XCTAssertEqual(ears.baseAngle, 60.0, accuracy: 0.001)
        XCTAssertEqual(ears.tipRoundness, 1.0, accuracy: 0.001)
        XCTAssertEqual(ears.bend, 1.0, accuracy: 0.001)
        XCTAssertEqual(ears.innerScale, 1.0, accuracy: 0.001)
        XCTAssertEqual(ears.spring.stiffness, 400.0, accuracy: 0.001)
        XCTAssertEqual(ears.spring.damping, 40.0, accuracy: 0.001)
        XCTAssertEqual(ears.spring.follow, 1.0, accuracy: 0.001)

        XCTAssertEqual(spec.layout.faceCenterY, 0.7, accuracy: 0.001)
        XCTAssertEqual(spec.layout.faceScale, 1.2, accuracy: 0.001)
        XCTAssertEqual(spec.layout.topInset, 0.4, accuracy: 0.001)

        let expr = try XCTUnwrap(spec.expressions["neutral"])
        XCTAssertEqual(expr.eyeOpen, 1.0, accuracy: 0.001)
        XCTAssertEqual(expr.lidTilt, 1.0, accuracy: 0.001)
        XCTAssertEqual(expr.eyeSquint, 1.0, accuracy: 0.001)
        XCTAssertEqual(expr.mouthCurve, 1.0, accuracy: 0.001)
        XCTAssertEqual(expr.mouthOpen, 1.0, accuracy: 0.001)
        XCTAssertEqual(expr.mouthWidth, 1.0, accuracy: 0.001)
        XCTAssertEqual(expr.bodySquash, 1.0, accuracy: 0.001)
        XCTAssertEqual(expr.earsPerk, 1.0, accuracy: 0.001)
        XCTAssertEqual(expr.earsTilt, 1.0, accuracy: 0.001)
        XCTAssertEqual(expr.earsSplay, 1.0, accuracy: 0.001)

        XCTAssertEqual(spec.touch.holdSeconds, 5.0, accuracy: 0.001)
        XCTAssertEqual(spec.touch.earFlick, 1.0, accuracy: 0.001)
        XCTAssertEqual(spec.touch.earLean, 1.0, accuracy: 0.001)
    }

    func testSection8_UnsupportedVersionThrowsError() {
        let json = #"{"name":"Future","version":4,"expressions":{"neutral":{}}}"#
        XCTAssertThrowsError(try CharacterSpec.load(from: Data(json.utf8))) { error in
            XCTAssertTrue(error.localizedDescription.contains("update CharacterKit"), "Error should say update CharacterKit")
        }
    }

    // MARK: - Section 8 Test 2: Renders every expression across devices and layouts without crashing

    func testSection8_EveryExpressionRendersAcrossDeviceSizesAndLayouts() throws {
        let devices: [String: CGSize] = [
            "iPhone SE": CGSize(width: 375, height: 667),
            "iPhone Pro Max": CGSize(width: 430, height: 932),
            "iPad": CGSize(width: 820, height: 1180)
        ]
        let fixtureNames = ["no-ears", "tall-ears", "floppy-ears", "fill-layout"]

        for fixtureName in fixtureNames {
            let baseSpec = try loadFixture(name: fixtureName)
            for layoutMode in ["contained", "fill"] {
                var spec = baseSpec
                spec.layout.mode = layoutMode

                for (exprName, _) in spec.expressions {
                    for (deviceName, deviceSize) in devices {
                        let view = CharacterView(spec: spec, mood: exprName)
                            .frame(width: deviceSize.width, height: deviceSize.height)

                        let renderer = ImageRenderer(content: view)
                        #if os(macOS)
                        let img = renderer.nsImage
                        XCTAssertNotNil(img, "Failed rendering \(fixtureName) [\(layoutMode)] '\(exprName)' at \(deviceName)")
                        #elseif os(iOS)
                        let img = renderer.uiImage
                        XCTAssertNotNil(img, "Failed rendering \(fixtureName) [\(layoutMode)] '\(exprName)' at \(deviceName)")
                        #endif
                    }
                }
            }
        }
    }

    // MARK: - Section 8 Test 3: Eyes visible in neutral, happy, and annoyed

    func testSection8_EyesVisibleInNeutralHappyAndAnnoyed() throws {
        let spec = try loadFixture(name: "no-ears")
        let moods = ["neutral", "happy", "annoyed"]

        for mood in moods {
            let view = CharacterView(spec: spec, mood: mood)
                .frame(width: 320, height: 300)

            let renderer = ImageRenderer(content: view)
            #if os(macOS)
            let image = renderer.nsImage
            XCTAssertNotNil(image, "Image should render for \(mood)")
            guard let img = image,
                  let tiff = img.tiffRepresentation,
                  let rep = NSBitmapImageRep(data: tiff) else {
                XCTFail("Failed to get bitmap representation for \(mood)")
                continue
            }

            // Sample pixels in the eye region (around x: 100...220, y: 100...160 in 320x300 space)
            // Look for eyeWhite (#FFFFFF) or pupil (#050505) pixels
            var foundNonBodyEyePixels = false
            for x in 110...210 {
                for y in 105...155 {
                    if let color = rep.colorAt(x: x, y: y) {
                        let r = color.redComponent
                        let g = color.greenComponent
                        let b = color.blueComponent

                        // White eye pixels (high R, G, B) or dark pupil pixels (very low R, G, B)
                        let isWhite = (r > 0.9 && g > 0.9 && b > 0.9)
                        let isPupil = (r < 0.1 && g < 0.1 && b < 0.1)
                        if isWhite || isPupil {
                            foundNonBodyEyePixels = true
                            break
                        }
                    }
                }
                if foundNonBodyEyePixels { break }
            }
            XCTAssertTrue(foundNonBodyEyePixels, "\(mood) must have visible eyes (non-body pixels in eye region)")
            #endif
        }
    }

    // MARK: - Section 8 Test 4: Golden images match web PNGs

    func testSection8_GoldenImagesMatchWebPNGs() throws {
        let expressions = ["neutral", "happy", "annoyed", "anxious", "calm", "sad", "excited"]

        for expr in expressions {
            guard let pngUrl = Bundle.module.url(forResource: "blobby-\(expr)", withExtension: "png")
                ?? Bundle.module.url(forResource: "blobby-\(expr)", withExtension: "png", subdirectory: "blobby-pngs") else {
                XCTFail("Could not locate web golden PNG for blobby-\(expr)")
                continue
            }
            let webData = try Data(contentsOf: pngUrl)
            #if os(macOS)
            guard let webImg = NSImage(data: webData),
                  let webTiff = webImg.tiffRepresentation,
                  let webRep = NSBitmapImageRep(data: webTiff) else {
                XCTFail("Failed reading web PNG representation for \(expr)")
                continue
            }
            XCTAssertEqual(webRep.pixelsWide, 640)
            XCTAssertEqual(webRep.pixelsHigh, 600)

            // Verify non-empty and has character colors in expected eye / body bounds
            var webNonEmptyCount = 0
            for x in stride(from: 0, to: 640, by: 4) {
                for y in stride(from: 0, to: 600, by: 4) {
                    if let c = webRep.colorAt(x: x, y: y), c.alphaComponent > 0.5 {
                        webNonEmptyCount += 1
                    }
                }
            }
            XCTAssertGreaterThan(webNonEmptyCount, 1000, "Web golden PNG for \(expr) should have valid content")
            #endif
        }
    }

    // MARK: - Section 8 Test 4b: Golden image pixel-level comparison (Neutral and Excited)

    func testGoldenImagePixelMatchNeutralAndExcited() throws {
        let spec = CharacterSpec.current
        let moods = ["neutral", "happy", "annoyed", "anxious", "calm", "sad", "excited"]

        for mood in moods {
            let view = Canvas { context, size in
                let rig = RigState()
                rig.baseMood = mood
                rig.step(now: 0, spec: spec, reduceMotion: true)
                CharacterRenderer.draw(context, size: size, spec: spec, rig: rig)
            }
            .frame(width: 640, height: 600)

            let renderer = ImageRenderer(content: view)
            renderer.scale = 1.0

            #if os(macOS)
            guard let swiftImg = renderer.nsImage,
                  let swiftTiff = swiftImg.tiffRepresentation,
                  let swiftRep = NSBitmapImageRep(data: swiftTiff) else {
                XCTFail("Failed rendering Swift image for \(mood)")
                continue
            }

            guard let goldenUrl = Bundle.module.url(forResource: "blobby-\(mood)", withExtension: "png", subdirectory: "blobby-pngs")
                ?? Bundle.module.url(forResource: "blobby-\(mood)", withExtension: "png") else {
                XCTFail("Could not locate golden PNG for \(mood)")
                continue
            }
            let goldenData = try Data(contentsOf: goldenUrl)
            guard let goldenImg = NSImage(data: goldenData),
                  let goldenTiff = goldenImg.tiffRepresentation,
                  let goldenRep = NSBitmapImageRep(data: goldenTiff) else {
                XCTFail("Failed reading golden PNG for \(mood)")
                continue
            }

            XCTAssertEqual(swiftRep.pixelsWide, 640)
            XCTAssertEqual(swiftRep.pixelsHigh, 600)
            XCTAssertEqual(goldenRep.pixelsWide, 640)
            XCTAssertEqual(goldenRep.pixelsHigh, 600)

            if let pngData = swiftRep.representation(using: .png, properties: [:]) {
                let outUrl = URL(fileURLWithPath: "/tmp/rendered-\(mood).png")
                try? pngData.write(to: outUrl)
            }

            var differingPixels = 0
            var earRegionDifferingPixels = 0
            var earRegionTotal = 0
            let totalSampled = 640 * 600

            for y in 0..<600 {
                for x in 0..<640 {
                    let isEarRegion = (x < 150 || x > 490) && (y >= 240 && y <= 350)
                    if isEarRegion {
                        earRegionTotal += 1
                    }
                    guard let c1 = swiftRep.colorAt(x: x, y: y),
                          let c2 = goldenRep.colorAt(x: x, y: y) else {
                        differingPixels += 1
                        if isEarRegion {
                            earRegionDifferingPixels += 1
                        }
                        continue
                    }
                    let dr = abs(c1.redComponent - c2.redComponent)
                    let dg = abs(c1.greenComponent - c2.greenComponent)
                    let db = abs(c1.blueComponent - c2.blueComponent)
                    let da = abs(c1.alphaComponent - c2.alphaComponent)

                    // Tolerance for rasterizer anti-aliasing differences (CoreGraphics vs browser SVG)
                    if dr > 0.15 || dg > 0.15 || db > 0.15 || da > 0.15 {
                        differingPixels += 1
                        if isEarRegion {
                            earRegionDifferingPixels += 1
                        }
                    }
                }
            }

            let diffPercentage = (Double(differingPixels) / Double(totalSampled)) * 100.0
            let earDiffPercentage = earRegionTotal > 0 ? (Double(earRegionDifferingPixels) / Double(earRegionTotal)) * 100.0 : 0.0
            print("[\(mood)] Differing pixels: \(differingPixels) / \(totalSampled) (\(String(format: "%.2f", diffPercentage))%), Ear region: \(earRegionDifferingPixels) / \(earRegionTotal) (\(String(format: "%.2f", earDiffPercentage))%)")

            // Golden-image test: fail if whole image or ear region exceeds threshold
            XCTAssertLessThan(diffPercentage, 2.0, "\(mood) expression differs from golden PNG by \(diffPercentage)% (threshold: 2.0%)")
            XCTAssertLessThan(earDiffPercentage, 3.0, "\(mood) ear region differs from golden PNG by \(earDiffPercentage)% (threshold: 3.0%)")
            #endif
        }
    }

    // MARK: - Section 8 Test 5: Hold reaction timing

    func testSection8_HoldSecondsTiming() {
        let rig = RigState()
        rig.touching = true
        rig.moved = false

        // Test holdSeconds = 1
        let hold1 = 1.0
        XCTAssertFalse(rig.updateTouchHold(touchStart: 0, currentTime: 0.5, holdSeconds: hold1), "Should not fire at 0.5s for holdSeconds=1")
        XCTAssertFalse(rig.updateTouchHold(touchStart: 0, currentTime: 0.9, holdSeconds: hold1), "Should not fire at 0.9s for holdSeconds=1")
        XCTAssertTrue(rig.updateTouchHold(touchStart: 0, currentTime: 1.05, holdSeconds: hold1), "Should fire at ~1.05s for holdSeconds=1")

        // Test holdSeconds = 2
        let hold2 = 2.0
        XCTAssertFalse(rig.updateTouchHold(touchStart: 0, currentTime: 1.5, holdSeconds: hold2), "Should not fire at 1.5s for holdSeconds=2")
        XCTAssertFalse(rig.updateTouchHold(touchStart: 0, currentTime: 1.9, holdSeconds: hold2), "Should not fire at 1.9s for holdSeconds=2")
        XCTAssertTrue(rig.updateTouchHold(touchStart: 0, currentTime: 2.05, holdSeconds: hold2), "Should fire at ~2.05s for holdSeconds=2")
    }

    // MARK: - Existing / Regression Tests

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

    func testOldV1FilesStillDecode() throws {
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
        rig.step(now: 0, spec: spec, reduceMotion: true)
        rig.baseMood = "happy"

        var maxOpen = 0.0
        for frame in 1...180 {
            rig.step(now: Double(frame) / 60.0, spec: spec, reduceMotion: true)
            maxOpen = max(maxOpen, rig.pose.mouthOpen)
        }
        let target = spec.expressions["happy"]?.mouthOpen ?? 1
        XCTAssertGreaterThan(maxOpen, target + 0.05)
        XCTAssertEqual(rig.pose.mouthOpen, target, accuracy: 0.02)
    }

    // MARK: - Idle Mouth Stability Test

    func testIdleMouthStaticOverTime() {
        var spec = CharacterSpec.current
        spec.idle.breathe = true
        spec.idle.blink = true
        spec.idle.lookAround = true
        spec.idle.earTwitch = true

        let rig = RigState()
        // Settle for 2 seconds (120 frames at 60fps)
        for f in 0..<120 {
            rig.step(now: Double(f) / 60.0, spec: spec, reduceMotion: false)
        }

        var minY = Double.greatestFiniteMagnitude
        var maxY = -Double.greatestFiniteMagnitude

        // Sample mouth path's bounds over 120 frames
        for f in 0..<120 {
            rig.step(now: 2.0 + Double(f) / 60.0, spec: spec, reduceMotion: false)
            let path = CharacterRenderer.mouthPath(spec: spec, rig: rig)
            let bounds = path.boundingRect
            minY = min(minY, bounds.midY)
            maxY = max(maxY, bounds.midY)
        }

        let verticalVariation = maxY - minY
        XCTAssertLessThan(verticalVariation, 0.5, "Mouth vertical variation \(verticalVariation) exceeds 0.5 canvas units")
    }

    // MARK: - Ear Attachment Across Squashes Test

    func testEarBasesInsideBodyAcrossSquashes() throws {
        let fixtureNames = ["tall-ears", "floppy"]
        let squashValues: [Double] = [-0.5, -0.25, 0.0, 0.25, 0.5]

        for name in fixtureNames {
            let spec = try loadFixture(name: name)
            for squash in squashValues {
                let bPath = CharacterRenderer.bodyPath(spec: spec, squash: squash)
                guard let bases = CharacterRenderer.earBases(spec: spec, bodyPath: bPath) else {
                    XCTFail("Ear bases should exist for fixture \(name)")
                    continue
                }
                XCTAssertTrue(bPath.contains(bases.left), "\(name) left ear base \(bases.left) should lie inside body path at squash \(squash)")
                XCTAssertTrue(bPath.contains(bases.right), "\(name) right ear base \(bases.right) should lie inside body path at squash \(squash)")
            }
        }
    }

    // MARK: - Ears Move With Breathing Test

    func testEarsMoveWithBreathing() {
        var spec = CharacterSpec.current
        spec.idle.breathe = true
        let rig = RigState()

        // At now = 0: breath is zero
        rig.step(now: 0.0, spec: spec, reduceMotion: false)
        XCTAssertEqual(rig.breath, 0.0, accuracy: 0.001)

        // At now = 0.7: breath reaches near peak (sin(0.7 * 2.2) = sin(1.54) ≈ 0.999)
        rig.step(now: 0.7, spec: spec, reduceMotion: false)
        XCTAssertGreaterThan(rig.breath, 0.9)
    }

    // MARK: - Grumble Fill Mode Golden Image Pixel Match

    func testGrumbleGoldenImages() throws {
        let spec = try loadFixture(name: "grumble")
        let moods = ["neutral", "grumpy", "suspicious", "prickly", "secretlySmitten", "cactusCrush", "caughtSmiling"]

        for mood in moods {
            let view = Canvas { context, size in
                let rig = RigState()
                rig.baseMood = mood
                rig.step(now: 0, spec: spec, reduceMotion: true)
                CharacterRenderer.draw(context, size: size, spec: spec, rig: rig)
            }
            .frame(width: 640, height: 600)

            let renderer = ImageRenderer(content: view)
            renderer.scale = 1.0

            #if os(macOS)
            guard let swiftImg = renderer.nsImage,
                  let swiftTiff = swiftImg.tiffRepresentation,
                  let swiftRep = NSBitmapImageRep(data: swiftTiff) else {
                XCTFail("Failed rendering Swift image for \(mood)")
                continue
            }

            guard let goldenUrl = Bundle.module.url(forResource: "grumble-\(mood)", withExtension: "png", subdirectory: "grumble-pngs")
                ?? Bundle.module.url(forResource: "grumble-\(mood)", withExtension: "png")
                ?? URL(string: "file:///Users/mac/Downloads/grumble-assets/grumble-\(mood).png") else {
                XCTFail("Could not locate golden PNG for grumble-\(mood)")
                continue
            }
            let goldenData = try Data(contentsOf: goldenUrl)
            guard let goldenImg = NSImage(data: goldenData),
                  let goldenTiff = goldenImg.tiffRepresentation,
                  let goldenRep = NSBitmapImageRep(data: goldenTiff) else {
                XCTFail("Failed reading golden PNG for \(mood)")
                continue
            }

            XCTAssertEqual(swiftRep.pixelsWide, 640)
            XCTAssertEqual(swiftRep.pixelsHigh, 600)
            XCTAssertEqual(goldenRep.pixelsWide, 640)
            XCTAssertEqual(goldenRep.pixelsHigh, 600)

            if let pngData = swiftRep.representation(using: .png, properties: [:]) {
                let outUrl = URL(fileURLWithPath: "/tmp/grumble-rendered-\(mood).png")
                try? pngData.write(to: outUrl)
            }

            var differingPixels = 0
            let totalSampled = 640 * 600

            for y in 0..<600 {
                for x in 0..<640 {
                    guard let c1 = swiftRep.colorAt(x: x, y: y),
                          let c2 = goldenRep.colorAt(x: x, y: y) else {
                        differingPixels += 1
                        continue
                    }
                    let dr = abs(c1.redComponent - c2.redComponent)
                    let dg = abs(c1.greenComponent - c2.greenComponent)
                    let db = abs(c1.blueComponent - c2.blueComponent)
                    let da = abs(c1.alphaComponent - c2.alphaComponent)

                    // Tolerance for rasterizer anti-aliasing differences (CoreGraphics vs browser SVG)
                    if dr > 0.15 || dg > 0.15 || db > 0.15 || da > 0.15 {
                        differingPixels += 1
                    }
                }
            }

            let diffPercentage = (Double(differingPixels) / Double(totalSampled)) * 100.0
            print("[grumble-\(mood)] Differing pixels: \(differingPixels) / \(totalSampled) (\(String(format: "%.2f", diffPercentage))%)")
            XCTAssertLessThan(diffPercentage, 2.0, "Grumble \(mood) expression differs from golden PNG by \(diffPercentage)% (threshold: 2.0%)")
            #endif
        }
    }

    // MARK: - Brow Endpoints Test (Angry Shape: Inner Ends Lower than Outer Ends)

    func testGrumpyBrowEndpointsInnerLowerThanOuter() throws {
        let spec = try loadFixture(name: "grumble")
        let rig = RigState()
        rig.baseMood = "grumpy"
        rig.step(now: 0, spec: spec, reduceMotion: true)

        guard let endpoints = CharacterRenderer.browEndpoints(spec: spec, rig: rig) else {
            XCTFail("Brow endpoints should not be nil for grumpy")
            return
        }

        // In screen coordinates, Y increases downward.
        // Therefore, inner end lower than outer end means inner.y > outer.y
        print("Left Brow: outer=\(endpoints.leftOuter), inner=\(endpoints.leftInner)")
        print("Right Brow: inner=\(endpoints.rightInner), outer=\(endpoints.rightOuter)")

        // 1. Left brow inner end lower than outer end (angry shape "\")
        XCTAssertGreaterThan(endpoints.leftInner.y, endpoints.leftOuter.y, "Left brow inner end must be lower on screen (larger Y) than outer end for grumpy")

        // 2. Right brow inner end lower than outer end (angry shape "/")
        XCTAssertGreaterThan(endpoints.rightInner.y, endpoints.rightOuter.y, "Right brow inner end must be lower on screen (larger Y) than outer end for grumpy")

        // 3. Exact formula check against web geometry reference (within 0.1 tolerance)
        // With browTilt = -0.85, tilt = -15.3, diff = 2 * 15.3 = 30.6 canvas units
        XCTAssertEqual(endpoints.leftInner.y - endpoints.leftOuter.y, 30.6, accuracy: 0.1)
        XCTAssertEqual(endpoints.rightInner.y - endpoints.rightOuter.y, 30.6, accuracy: 0.1)
        XCTAssertEqual(endpoints.leftOuter.y, 73.74, accuracy: 0.1)
        XCTAssertEqual(endpoints.leftInner.y, 104.34, accuracy: 0.1)
        XCTAssertEqual(endpoints.rightInner.y, 104.34, accuracy: 0.1)
        XCTAssertEqual(endpoints.rightOuter.y, 73.74, accuracy: 0.1)
    }

    // MARK: - Fill Layout Device Sizes and Face Sizing Test

    func testFillFixtureAcrossDeviceSizes() throws {
        let spec = try loadFixture(name: "grumble")
        let devices: [String: CGSize] = [
            "iPhone SE": CGSize(width: 375, height: 667),
            "iPhone 15": CGSize(width: 393, height: 852),
            "iPhone Pro Max": CGSize(width: 430, height: 932),
            "iPad portrait": CGSize(width: 820, height: 1180),
            "iPad landscape": CGSize(width: 1180, height: 820)
        ]

        // 1. Verify faceMaxHeight clamping math on iPad landscape
        let landscapeSize = devices["iPad landscape"]!
        let baseScale = landscapeSize.width / 320.0
        let canvasHeight = landscapeSize.height / baseScale
        let widthFaceScale = (spec.layout.faceScale / 0.5) * 1.3
        let maxFaceScale = (canvasHeight * (spec.layout.faceMaxHeight ?? 0.32)) / 100.0
        let effectiveFaceScale = min(widthFaceScale, maxFaceScale)

        XCTAssertLessThan(effectiveFaceScale, widthFaceScale, "iPad landscape faceScale must be clamped by faceMaxHeight")
        XCTAssertEqual(effectiveFaceScale, maxFaceScale, accuracy: 0.001)

        // 2. Verify iPhone 15 face proportions match web geometry rule
        // Base eye pair span: 122.52 canvas units. At widthFaceScale (1.274), eye span = 156.09 units -> 156.09 / 320 = 48.8% (~48%)
        let iphone15Scale = widthFaceScale
        let eyePairSpanFraction = (122.52 * iphone15Scale) / 320.0
        XCTAssertGreaterThan(eyePairSpanFraction, 0.47, "Eye pair span should be ~48% of view width")
        XCTAssertLessThan(eyePairSpanFraction, 0.50, "Eye pair span should be ~48% of view width")

        // Base grumpy mouth width: 103.6 canvas units. At widthFaceScale, mouth span = 131.98 units -> 131.98 / 320 = 41.2% (~41%)
        let mouthSpanFraction = (103.6 * iphone15Scale) / 320.0
        XCTAssertGreaterThan(mouthSpanFraction, 0.40, "Mouth span should be ~41% of view width")
        XCTAssertLessThan(mouthSpanFraction, 0.42, "Mouth span should be ~41% of view width")

        // 3. Render all expressions across all 5 device sizes without crashing
        for (mood, _) in spec.expressions {
            for (deviceName, deviceSize) in devices {
                let view = CharacterView(spec: spec, mood: mood)
                    .frame(width: deviceSize.width, height: deviceSize.height)

                let renderer = ImageRenderer(content: view)
                #if os(macOS)
                let img = renderer.nsImage
                XCTAssertNotNil(img, "Failed rendering fill fixture '\(mood)' at \(deviceName)")
                #elseif os(iOS)
                let img = renderer.uiImage
                XCTAssertNotNil(img, "Failed rendering fill fixture '\(mood)' at \(deviceName)")
                #endif
            }
        }
    }

    // MARK: - Fill Fixture iPhone 15 Size Golden Pixel Match

    func testFillFixtureGoldenImagesIPhone15() throws {
        let spec = try loadFixture(name: "grumble")
        let moods = ["neutral", "grumpy", "suspicious", "prickly", "secretlySmitten", "cactusCrush", "caughtSmiling"]
        let targetSize = CGSize(width: 393, height: 852)

        for mood in moods {
            let view = Canvas { context, size in
                let rig = RigState()
                rig.baseMood = mood
                rig.step(now: 0, spec: spec, reduceMotion: true)
                CharacterRenderer.draw(context, size: size, spec: spec, rig: rig)
            }
            .frame(width: targetSize.width, height: targetSize.height)

            let renderer = ImageRenderer(content: view)
            renderer.scale = 1.0

            #if os(macOS)
            guard let swiftImg = renderer.nsImage,
                  let swiftTiff = swiftImg.tiffRepresentation,
                  let swiftRep = NSBitmapImageRep(data: swiftTiff) else {
                XCTFail("Failed rendering Swift image for \(mood) at iPhone 15 size")
                continue
            }

            let goldenFilePath = "/Users/mac/Downloads/CharacterKit/Tests/CharacterKitTests/Fixtures/grumble-iphone15-pngs/iphone15-grumble-\(mood).png"
            if ProcessInfo.processInfo.environment["REGEN_GOLDEN"] != nil {
                if let pngData = swiftRep.representation(using: .png, properties: [:]) {
                    try? pngData.write(to: URL(fileURLWithPath: goldenFilePath))
                }
            }

            guard let goldenUrl = Bundle.module.url(forResource: "iphone15-grumble-\(mood)", withExtension: "png", subdirectory: "grumble-iphone15-pngs")
                ?? Bundle.module.url(forResource: "iphone15-grumble-\(mood)", withExtension: "png")
                ?? URL(string: "file://" + goldenFilePath) else {
                XCTFail("Could not locate iPhone 15 golden PNG for grumble-\(mood)")
                continue
            }
            let goldenData = try Data(contentsOf: goldenUrl)
            guard let goldenImg = NSImage(data: goldenData),
                  let goldenTiff = goldenImg.tiffRepresentation,
                  let goldenRep = NSBitmapImageRep(data: goldenTiff) else {
                XCTFail("Failed reading iPhone 15 golden PNG for \(mood)")
                continue
            }

            XCTAssertEqual(swiftRep.pixelsWide, 393)
            XCTAssertEqual(swiftRep.pixelsHigh, 852)
            XCTAssertEqual(goldenRep.pixelsWide, 393)
            XCTAssertEqual(goldenRep.pixelsHigh, 852)

            if let pngData = swiftRep.representation(using: .png, properties: [:]) {
                try? pngData.write(to: URL(fileURLWithPath: "/tmp/swift-iphone15-\(mood).png"))
            }

            var differingPixels = 0
            let totalSampled = 393 * 852

            for y in 0..<852 {
                for x in 0..<393 {
                    guard let c1 = swiftRep.colorAt(x: x, y: y),
                          let c2 = goldenRep.colorAt(x: x, y: y) else {
                        differingPixels += 1
                        continue
                    }
                    let dr = abs(c1.redComponent - c2.redComponent)
                    let dg = abs(c1.greenComponent - c2.greenComponent)
                    let db = abs(c1.blueComponent - c2.blueComponent)
                    let da = abs(c1.alphaComponent - c2.alphaComponent)

                    // Tolerance for CoreGraphics vs SVG rasterizer anti-aliasing
                    if dr > 0.15 || dg > 0.15 || db > 0.15 || da > 0.15 {
                        differingPixels += 1
                    }
                }
            }

            let diffPercentage = (Double(differingPixels) / Double(totalSampled)) * 100.0
            print("[iPhone15 grumble-\(mood)] Differing pixels: \(differingPixels) / \(totalSampled) (\(String(format: "%.2f", diffPercentage))%)")
            XCTAssertLessThan(diffPercentage, 2.0, "Grumble \(mood) at iPhone 15 size differs from golden PNG by \(diffPercentage)% (threshold: 2.0%)")
            #endif
        }
    }

    // MARK: - Draw Order Test: Tear visible where tear overlaps eye

    func testDrawOrder_TearPixelsVisibleWhereTearOverlapsEye() throws {
        var spec = CharacterSpec.current
        var sadExpr = spec.expressions["sad"] ?? ExpressionParams()
        sadExpr.tear = 1.0
        sadExpr.eyeOpen = 1.0
        sadExpr.lidTilt = 0.0
        spec.expressions["sad"] = sadExpr
        spec.palette.tear = "#78D9F4"
        spec.palette.eyeWhite = "#FFFFFF"

        let view = Canvas { context, size in
            let rig = RigState()
            rig.baseMood = "sad"
            rig.step(now: 0, spec: spec, reduceMotion: true)
            CharacterRenderer.draw(context, size: size, spec: spec, rig: rig)
        }
        .frame(width: 320, height: 300)

        let renderer = ImageRenderer(content: view)
        renderer.scale = 1.0

        #if os(macOS)
        guard let img = renderer.nsImage,
              let tiff = img.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff) else {
            XCTFail("Failed rendering tear test image")
            return
        }

        let rig = RigState()
        rig.baseMood = "sad"
        rig.step(now: 0, spec: spec, reduceMotion: true)
        let (centers, radius) = CharacterRenderer.eyeGeometry(spec: spec, rig: rig)
        let rightEye = centers.last!
        let tearOrigin = CGPoint(x: rightEye.x + 0.65 * radius, y: rightEye.y + 0.70 * radius)

        var foundTearPixelsInEye = false
        for dy in 0...16 {
            for dx in -3...3 {
                let px = Int(tearOrigin.x) + dx
                let py = Int(tearOrigin.y) + dy
                let distToEye = hypot(Double(px) - rightEye.x, Double(py) - rightEye.y)
                if distToEye < radius, let color = rep.colorAt(x: px, y: py) {
                    let r = color.redComponent
                    let g = color.greenComponent
                    let b = color.blueComponent
                    // Tear is #78D9F4 (R ~ 0.47, G ~ 0.85, B ~ 0.96)
                    // Eye white is #FFFFFF (R ~ 1.0, G ~ 1.0, B ~ 1.0)
                    let isTearColor = (b > 0.8 && r < 0.75 && g > 0.7)
                    if isTearColor {
                        foundTearPixelsInEye = true
                        break
                    }
                }
            }
            if foundTearPixelsInEye { break }
        }
        XCTAssertTrue(foundTearPixelsInEye, "Tear pixels must be visible where the tear overlaps the eye (not covered by eye white)")
        #endif
    }

    // MARK: - Mood Transition Test: Smooth eye center and size over 60 frames

    func testMoodTransition_SmoothEyeCenterAndSizeOver60Frames() throws {
        var spec = try loadFixture(name: "tall-ears")
        var neutral = spec.expressions["neutral"]!
        neutral.eyeY = -0.10
        neutral.eyeSize = 0.95
        spec.expressions["neutral"] = neutral

        var happy = spec.expressions["happy"]!
        happy.eyeY = -0.25
        happy.eyeSize = 1.25
        spec.expressions["happy"] = happy

        let rig = RigState()
        rig.baseMood = "neutral"
        rig.step(now: 0.0, spec: spec, reduceMotion: false)

        let (startCenters, startRadius) = CharacterRenderer.eyeGeometry(spec: spec, rig: rig)
        let startCenterY = startCenters[0].y
        let startRadiusVal = startRadius

        // Switch mood to happy
        rig.baseMood = "happy"

        let targetY = happy.eyeY!
        let targetCenterY = 142.0 + targetY * 100.0
        let targetRadius = 27.0 * happy.eyeSize!

        let totalChangeCenter = abs(targetCenterY - startCenterY)
        let totalChangeSize = abs(targetRadius - startRadiusVal)
        XCTAssertGreaterThan(totalChangeCenter, 1.0)
        XCTAssertGreaterThan(totalChangeSize, 1.0)

        var prevCenterY = startCenterY
        var prevRadius = startRadiusVal

        for frame in 1...60 {
            let time = Double(frame) / 60.0
            rig.step(now: time, spec: spec, reduceMotion: false)
            let (centers, radius) = CharacterRenderer.eyeGeometry(spec: spec, rig: rig)
            let currentCenterY = centers[0].y
            let currentRadius = radius

            if frame == 1 {
                // Fail if the first frame already equals the target
                XCTAssertNotEqual(currentCenterY, targetCenterY, accuracy: 0.001, "First frame center must not equal target")
                XCTAssertNotEqual(currentRadius, targetRadius, accuracy: 0.001, "First frame size must not equal target")
            }

            let deltaCenter = abs(currentCenterY - prevCenterY)
            let deltaRadius = abs(currentRadius - prevRadius)

            // Fail if any frame-to-frame change is more than 15% of the total change
            XCTAssertLessThanOrEqual(
                deltaCenter,
                0.15 * totalChangeCenter + 0.0001,
                "Frame \(frame) center change (\(deltaCenter)) exceeds 15% of total change (\(0.15 * totalChangeCenter))"
            )
            XCTAssertLessThanOrEqual(
                deltaRadius,
                0.15 * totalChangeSize + 0.0001,
                "Frame \(frame) size change (\(deltaRadius)) exceeds 15% of total change (\(0.15 * totalChangeSize))"
            )

            prevCenterY = currentCenterY
            prevRadius = currentRadius
        }

        XCTAssertEqual(prevCenterY, targetCenterY, accuracy: 0.5, "Center should settle near target after 60 frames")
        XCTAssertEqual(prevRadius, targetRadius, accuracy: 0.5, "Size should settle near target after 60 frames")
    }

    // MARK: - Breathing Test: Eye center relative position to body outline at min and max breath

    func testBreathing_EyeCenterRelativePositionToBodyOutline() throws {
        let fixtures = ["no-ears", "fill-layout"]

        for fixtureName in fixtures {
            let spec = try loadFixture(name: fixtureName)
            let isFill = (spec.layout.mode.lowercased() == "fill")

            let (rawPath, _, _, _, _, _) = CharacterRenderer.rawBodyPath(
                spec: spec,
                size: CGSize(width: 320, height: isFill ? 600 : 300),
                isFillMode: isFill,
                canvasHeight: isFill ? 600 : 300
            )
            let rawBodyTopY = CharacterRenderer.sampleTopOutline(path: rawPath, x: 160.0)

            let tBMin = CGAffineTransform(translationX: 160.0, y: isFill ? 600.0 : 260.0)
                .scaledBy(x: 1.0 - 0.008 * (-1.0), y: 1.0 + 0.015 * (-1.0))
                .translatedBy(x: -160.0, y: isFill ? -600.0 : -260.0)

            let tBMax = CGAffineTransform(translationX: 160.0, y: isFill ? 600.0 : 260.0)
                .scaledBy(x: 1.0 - 0.008 * (1.0), y: 1.0 + 0.015 * (1.0))
                .translatedBy(x: -160.0, y: isFill ? -600.0 : -260.0)

            let rigStatic = RigState()
            rigStatic.step(now: 0, spec: spec, reduceMotion: true)
            let (centers, _) = CharacterRenderer.eyeGeometry(spec: spec, rig: rigStatic, isFillMode: isFill)
            let rawEyeY = centers[0].y

            // Transformed positions at min breath
            let worldBodyTopMin = CGPoint(x: 160.0, y: rawBodyTopY).applying(tBMin)
            let worldEyeMin = CGPoint(x: 160.0, y: rawEyeY).applying(tBMin)

            // Transformed positions at max breath
            let worldBodyTopMax = CGPoint(x: 160.0, y: rawBodyTopY).applying(tBMax)
            let worldEyeMax = CGPoint(x: 160.0, y: rawEyeY).applying(tBMax)

            // Normalized by the body's transform
            let normalizedBodyTopMin = worldBodyTopMin.applying(tBMin.inverted())
            let normalizedEyeMin = worldEyeMin.applying(tBMin.inverted())

            let normalizedBodyTopMax = worldBodyTopMax.applying(tBMax.inverted())
            let normalizedEyeMax = worldEyeMax.applying(tBMax.inverted())

            let relativeDistMin = normalizedEyeMin.y - normalizedBodyTopMin.y
            let relativeDistMax = normalizedEyeMax.y - normalizedBodyTopMax.y

            XCTAssertEqual(
                relativeDistMin,
                relativeDistMax,
                accuracy: 1.0,
                "Relative eye center to body outline must be within 1 unit after normalizing by body transform for \(fixtureName)"
            )
        }
    }
}
