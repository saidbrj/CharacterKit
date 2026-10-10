# Charakit Character Spec: v3, minor 1

This is the contract between the **web editor** (Lovable) and the **CharacterKit Swift package** (Antigravity). Both must read and write exactly these names, units, ranges and defaults.

This update is **additive**. Every existing character (Blobby, Bean, Cyclops, Grumbleprick) must look and behave **identically** after it.

---

## 1. Global rules

1. Keep `"version": 3`. Add `"schemaMinor": 1`.
2. Every new field is **optional**. A missing field takes the default listed below.
3. **Clamp** every value to its range on load. Never throw or crash on a bad number. The only hard error is a `version` newer than the package supports ("update CharacterKit").
4. Unknown fields are ignored.
5. **No logic keyed to expression names.** Behavior comes only from numeric values.
6. The web preview is the **reference**. Swift must match it.
7. Do not change `ContentView` per character. The app reads `CharacterSpec.current`, `spec.expressionOrder` and `spec.defaultMood`.

### Units

- Lengths are fractions of **body width** (about 234 canvas units, in the 320 x 300 canvas).
- `baseY` runs from -1 (top edge of the body) to +1 (bottom edge). The body's height range is about y = 54 to 260.
- Angles are in **degrees**. Positive is clockwise.
- Ears are drawn **behind the body** and rotate around their base point.

---

## 2. Fixes that must ship with this update

These are mismatches found in the Swift renderer. Fix them first.

1. **Annoyed shows no eyes.** The lid is applied twice (once from `eye.open`, once from a mood-specific offset). Remove every mood-name check and fixed lid offset. Lid position derives only from `eye.open`, `eye.lidTilt` and blink.
2. **Happy cuts too much of the eye.** Replace the hard-coded squint lid with one computed from `eye.squint` (0 to 1) and the eye geometry. Web and Swift use the same formula.
3. **Press and hold takes 3 s in Swift, 1 s on web.** Read `touch.holdSeconds` from the spec (default 1.0). Fire the hold reaction exactly when that time elapses with the finger still down. Check that no competing `DragGesture` delays it.
4. **Calm blink is inverted.** `blink = 1` must mean eyes open everywhere.

---

## 3. New and changed fields (full example)

```json
{
  "version": 3,
  "schemaMinor": 1,
  "palette": {
    "ear": "#A17AF5",
    "earInner": "#C9B3FA"
  },
  "parts": {
    "ears": {
      "style": "tall",
      "anchor": "top",
      "length": 0.7,
      "width": 0.2,
      "spread": 0.45,
      "baseY": -0.85,
      "baseAngle": 12,
      "tipRoundness": 0.8,
      "bend": 0.15,
      "innerScale": 0.6,
      "spring": { "stiffness": 140, "damping": 9, "follow": 0.6 }
    }
  },
  "layout": {
    "mode": "contained",
    "faceCenterY": 0.38,
    "faceScale": 0.55,
    "topInset": 0.08
  },
  "expressions": {
    "excited": {
      "eye": { "squint": 0 },
      "ears": { "perk": 1.0, "tilt": 0.0, "splay": 0.2 }
    },
    "sad": {
      "ears": { "perk": -0.8, "tilt": 0.0, "splay": 0.5 }
    }
  },
  "touch": {
    "holdSeconds": 1.0,
    "earFlick": 1.0,
    "earLean": 0.6
  },
  "idle": {
    "earTwitch": true
  }
}
```

---

## 4. Field reference

### `parts.ears`

Omit the object, or use `"style": "none"`, for no ears.

| Field | Type / range | Default | Meaning |
|---|---|---|---|
| `style` | `none`, `tall`, `pointed`, `round`, `floppy`, `elf` | `none` | Preset family. Only fills defaults; drawing always comes from the numbers |
| `anchor` | `top`, `side` | per style | Where the ears attach. `tall`, `pointed`, `round`: top. `floppy`, `elf`: side |
| `length` | 0.1 to 1.5 | 0.6 | Ear length |
| `width` | 0.05 to 0.6 | 0.22 | Width at the base |
| `spread` | 0 to 1 | 0.45 | Distance of each base from the center |
| `baseY` | -1 to 1 | -0.85 (top), -0.1 (side) | Vertical base position |
| `baseAngle` | -60 to 60 | 12 | Outward splay at rest |
| `tipRoundness` | 0 to 1 | 0.8 | 0 is pointed, 1 is rounded |
| `bend` | -1 to 1 | 0 | Curve of the ear |
| `innerScale` | 0 to 1 | 0.6 | Inner-ear size. 0 hides it |
| `spring.stiffness` | 20 to 400 | 140 | Spring strength |
| `spring.damping` | 2 to 40 | 9 | Spring damping |
| `spring.follow` | 0 to 1 | 0.6 | How much body squash and bounce moves the ears |

**Style presets** (defaults only; every number can be overridden):

| Style | anchor | length | width | tipRoundness | Notes |
|---|---|---|---|---|---|
| `tall` (rabbit) | top | 0.9 | 0.2 | 0.8 | Flagship, widest perk/droop range |
| `pointed` (cat, fox) | top | 0.45 | 0.3 | 0.1 | Same shape code, pointed tip |
| `round` (bear, mouse) | top | 0.25 | 0.3 | 1.0 | Short and bouncy |
| `floppy` (dog) | side | 0.5 | 0.28 | 0.9 | Hangs and swings with the body |
| `elf` | side | 0.4 | 0.2 | 0.1 | Angled upward |

### Per-expression `ears`

| Field | Range | Default | Meaning |
|---|---|---|---|
| `perk` | -1 to 1 | 0 | -1 droop, 0 rest, 1 upright |
| `tilt` | -1 to 1 | 0 | Both ears lean left (-) or right (+) |
| `splay` | -1 to 1 | 0 | -1 inward, 1 outward |

These set the **target** angles. The spring produces the motion. Blending between expressions interpolates these values, like every other expression value.

### Per-expression `eye.squint` (fix #2)

`eye.squint`: 0 to 1, default 0. Drives the happy-style squint. The web and Swift renderers use the same formula.

### `palette`

| Field | Default |
|---|---|
| `ear` | same as `body` |
| `earInner` | lightened `bodyShade` |

### `layout`

| Field | Range | Default | Meaning |
|---|---|---|---|
| `mode` | `contained`, `fill` | `contained` | `contained` is today's behavior |
| `faceCenterY` | 0.2 to 0.7 | 0.38 | Face vertical position as a fraction of view height (fill only) |
| `faceScale` | 0.3 to 1.2 | 0.55 | Face size relative to view width (fill only) |
| `topInset` | 0 to 0.4 | 0.08 | Where the scalloped top starts, as a fraction of view height (fill only) |

**Fill mode:** the scalloped top sits near the top of the view, the body extends straight down past the bottom edge with the gradient continuing, the face is sized by view **width** (so it stays proportional on every device), and the body ignores safe areas. The host app's own UI stays inside safe areas.

### `touch`

| Field | Range | Default | Meaning |
|---|---|---|---|
| `holdSeconds` | 0.2 to 5 | 1.0 | Time before the hold reaction fires (fix #3) |
| `earFlick` | 0 to 1 | 1.0 | Strength of the ear flick on tap |
| `earLean` | 0 to 1 | 0.6 | How far ears lean toward the finger while dragging |

The existing `tap`, `longPress`, `reactSeconds`, `tapBounce`, `haptics` and `dragLooksAt` are unchanged. If `tap` or `longPress` names an unknown expression, fall back to the first entry of `expressionOrder`.

### `idle`

| Field | Default | Meaning |
|---|---|---|
| `earTwitch` | false | A small random ear flick every few seconds |

---

## 5. Behavior summary

- **Mood:** `perk`, `tilt` and `splay` set target angles; the spring moves the ears.
- **Body motion:** squash, bounce and breathing pass into the ears through `spring.follow`, so they lag and overshoot.
- **Tap:** ears flick, scaled by `touch.earFlick`.
- **Drag:** ears lean toward the finger, scaled by `touch.earLean`. Pupils keep tracking as before.
- **Idle:** blink and breathe as before; ears twitch if `idle.earTwitch` is true.

---

## 6. Web editor requirements (Lovable)

- A new **Ears** section: style selector, sliders and color pickers for every `parts.ears` field, and `palette.ear` / `palette.earInner`.
- In the **Tune** panel, per-expression sliders for `ears.perk`, `ears.tilt`, `ears.splay` and `eye.squint`.
- A **Layout** section: mode toggle (contained / fill) and sliders for the three fill fields, plus a "Full screen" preview toggle.
- In **Touch**: sliders for `holdSeconds`, `earFlick`, `earLean`. In **Idle life**: an `earTwitch` toggle.
- Web hold gesture uses `touch.holdSeconds`.
- Export all fields with defaults. The exported `Character.character.swift` includes them.
- A **Download PNGs** button: every expression at 640 px, named `<name>-<expression>.png`.
- Existing presets look identical. No mood-name checks in the web renderer.
- Also deliver a short markdown "Eye and ear geometry reference" listing the exact formulas the web renderer uses (eye circle, pupil, lid, squint curve, ear shape and rotation), in terms of the spec fields.

## 7. Swift package requirements (Antigravity)

- Decode all new fields with the defaults above. Clamp on load.
- Old JSON (without any new field) renders exactly as before.
- Implement ears as a generic **appendage** (base, length, width, bend, tip, spring), drawn behind the body. Do not hard-code per-style drawing.
- Implement `layout.mode = fill` as described in section 4.
- Implement the four fixes in section 2.
- No per-character edits to `ContentView`, and no `CharacterSpec.current` or demo views inside the package target.

---

## 8. Shared fixtures and tests

Both projects load the **same** JSON files:

- `Fixtures/no-ears.json`
- `Fixtures/tall-ears.json`
- `Fixtures/floppy-ears.json`
- `Fixtures/fill-layout.json`

In the web project and in `Tests/CharacterKitTests/Fixtures/`.

Tests:

1. Every fixture decodes without error, and unknown or missing fields use defaults.
2. Every expression of every fixture renders at iPhone SE, iPhone Pro Max and iPad sizes, in both layouts, without crashing.
3. Eyes are visible in neutral, happy and annoyed (non-body pixels exist in the eye region).
4. Golden images: the Swift render of each expression is within tolerance of the web PNG.
5. `touch.holdSeconds = 1` fires the hold reaction at about 1 s, and `2` fires at about 2 s.

## 9. Acceptance checklist

- [ ] Existing characters look identical on web and in Xcode
- [ ] Annoyed shows half-covered eyes in Swift, like web
- [ ] Happy squint matches web
- [ ] Hold fires at the time set in the slider
- [ ] Tall, pointed, round, floppy and elf ears render and animate
- [ ] Ears respond to mood, tap, drag and body motion
- [ ] Fill layout works on iPhone SE, Pro Max and iPad
- [ ] Replacing `Character.character.swift` is still the only step to change the character
