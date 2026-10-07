# CharacterKit (v0.2)

Interactive animated characters for SwiftUI. Design a character in the web editor, export a small JSON file, and drop it into your app. No animation tool, no runtime to learn.

> **Status:** prototype. The Swift was written without access to a compiler, so expect to fix a few small build errors the first time you open it in Xcode. The JSON schema, the sample, and the spring constants are checked; `tools/reference_render.py` shows what the Swift renderer should draw.

## What's new in v0.2

- **Cloud body** (scalloped top) alongside `blob` and `round`
- **Real eyelids** instead of brows: a flat lid comes down from the top of the eye and can tilt, so emotion comes from lid slant plus mouth shape
- **A bolder, morphing mouth**: a thick pill when closed, a bowl/arch with a dark outline when open, and an adjustable width
- **Springs with overshoot**: eyes snap, the mouth lags a beat and overshoots, the body is loosest
- Breaking change in the spec: `browAngle`/`browLift`/`mouthInside` are gone; `lidTilt`, `mouthWidth` and `mouthOutline` are new. Old files still load (unknown keys are ignored) but will look different.

## Install

In Xcode: **File > Add Package Dependencies...** and add this package (or drag the `CharacterKit` folder in as a local package).

Requires iOS 16+ / macOS 13+, Swift 5.9+.

## Use

```swift
import SwiftUI
import CharacterKit

struct ContentView: View {
    @State private var mood = "neutral"
    let spec = try! CharacterSpec.load(named: "mycharacter")   // mycharacter.json in your app bundle

    var body: some View {
        CharacterView(spec: spec, mood: mood) { event in
            if event == .tap { /* play a sound, add a point... */ }
        }
        .frame(width: 280)

        Button("Cheer up") { mood = "happy" }
    }
}
```

Try it without any JSON of your own: `CharacterDemoView()` shows the bundled sample with mood buttons.

## What the character does by itself

- Blinks (the lid sweeps down and back), breathes, and glances around while idle
- Pupils follow your finger while you touch or drag
- **Tap:** shows the spec's `touch.tap` expression briefly, squashes and bounces, light haptic
- **Long press:** holds the `touch.longPress` expression until you let go
- Changing `mood` springs the face to the new expression
- Respects **Reduce Motion** (no idle motion, no bounce, no wobble)

## Events

`CharacterEvent`: `.tap`, `.longPress`, `.dragBegan`, `.dragEnded`.

## The spec

See `character-spec.schema.json` for the full schema with ranges.

| Section | What it controls |
|---|---|
| `palette` | Hex colours: body, bodyShade, eyeWhite, pupil, mouth (fill), mouthOutline |
| `parts` | Body shape (`cloud`/`blob`/`round`), cloud bumps and bumpiness, eye count/size/spacing/height, pupil size, base mouth width/position/thickness |
| `expressions` | Named sets of six numbers: `eyeOpen`, `lidTilt`, `mouthCurve`, `mouthOpen`, `mouthWidth`, `bodySquash`. `neutral` is required. |
| `touch` | Which expression tap/long-press show, whether pupils follow the finger, reaction time, bounce, haptics |
| `idle` | Toggle blinking, breathing, looking around |

Anything missing falls back to a default. Everything is clamped to safe ranges by `CharacterSpec.sanitized()` (called automatically), so a bad or AI-generated file can't break the rig.

## Sign conventions

- `lidTilt` negative = angry (inner lid corners lowered), positive = worried/sad (inner corners raised)
- `mouthCurve` negative = frown/arch, positive = smile
- `mouthOpen` above 0 fades in the dark outline
- Unit space is -1...1 on both axes with y pointing down

## Files

- `Sources/CharacterKit/CharacterSpec.swift`: models, defaults, clamping, loading
- `RigState.swift`: per-frame animation state (springs, blink, breath, bounce)
- `CharacterRenderer.swift`: the drawing code
- `CharacterView.swift`: public view, gestures, haptics, events
- `DemoView.swift`: `CharacterDemoView` playground
- `tools/reference_render.py`: Pillow renderer that mirrors the Swift drawing, for visual comparison (`pip install pillow`)
- `Tests/`: decoding, clamping and spring tests

## Keeping web and Swift in sync

`CharacterRenderer.swift` and `RigState.swift` are the source of truth. The web editor and `tools/reference_render.py` copy their constants. If you change a number in one, change it in all three, then export a character from the editor and compare it with `CharacterDemoView` side by side.
