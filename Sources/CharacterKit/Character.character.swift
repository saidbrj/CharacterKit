import Foundation

public extension CharacterSpec {
    static let current: CharacterSpec = {
        let json = #"""
        {
          "name": "Grumbleprick",
          "version": 3,
          "palette": {
            "body": "#66A653",
            "bodyShade": "#3C743F",
            "eyeWhite": "#FFF5DB",
            "pupil": "#182B20",
            "mouth": "#35452A",
            "mouthOutline": "#243921",
            "brow": "#283D22",
            "sparkle": "#FFE58A",
            "pad": "#EBA081",
            "cavity": "#252319",
            "tongue": "#ED877D",
            "tear": "#82D8F1",
            "teeth": "#FFF9E8"
          },
          "parts": {
            "bodyShape": "blob",
            "bumps": 5,
            "bumpiness": 0.14,
            "eyeCount": 2,
            "eyeSize": 0.85,
            "eyeSpacing": 0.24,
            "eyeY": -0.15,
            "pupilSize": 0.35,
            "mouthWidth": 0.4,
            "mouthY": 0.35,
            "mouthThickness": 1.3
          },
          "expressionOrder": [
            "neutral",
            "grumpy",
            "suspicious",
            "prickly",
            "secretlySmitten",
            "cactusCrush",
            "caughtSmiling"
          ],
          "defaultMood": "neutral",
          "expressions": {
            "neutral": {
              "eye": {
                "open": 0.65,
                "size": 0.85,
                "spacing": 0.24,
                "y": -0.15,
                "pupil": 0.35,
                "squint": -0.15,
                "lidTilt": -0.2,
                "style": 0
              },
              "sparkle": 0,
              "brow": {
                "amount": 0.8,
                "y": 0,
                "tilt": -0.45,
                "arch": -0.15
              },
              "mouth": {
                "curve": -0.4,
                "open": 0,
                "width": 0.33,
                "pad": 0.08,
                "teeth": 0,
                "tongue": 0
              },
              "tear": 0,
              "body": {
                "squash": 0
              }
            },
            "grumpy": {
              "eye": {
                "open": 0.5,
                "size": 0.85,
                "spacing": 0.24,
                "y": -0.15,
                "pupil": 0.35,
                "squint": -0.4,
                "lidTilt": -0.65,
                "style": 0
              },
              "sparkle": 0,
              "brow": {
                "amount": 1,
                "y": 0.35,
                "tilt": -0.85,
                "arch": -0.3
              },
              "mouth": {
                "curve": -0.85,
                "open": 0.05,
                "width": 0.45,
                "pad": 0.05,
                "teeth": 0,
                "tongue": 0
              },
              "tear": 0,
              "body": {
                "squash": -0.05
              }
            },
            "suspicious": {
              "eye": {
                "open": 0.35,
                "size": 0.85,
                "spacing": 0.24,
                "y": -0.15,
                "pupil": 0.35,
                "squint": -0.6,
                "lidTilt": -0.3,
                "style": 0
              },
              "sparkle": 0,
              "brow": {
                "amount": 0.95,
                "y": 0.1,
                "tilt": -0.5,
                "arch": 0.3
              },
              "mouth": {
                "curve": -0.2,
                "open": 0,
                "width": 0.25,
                "pad": 0.05,
                "teeth": 0,
                "tongue": 0
              },
              "tear": 0,
              "body": {
                "squash": 0
              }
            },
            "prickly": {
              "eye": {
                "open": 0.75,
                "size": 0.85,
                "spacing": 0.24,
                "y": -0.15,
                "pupil": 0.25,
                "squint": 0.1,
                "lidTilt": -0.75,
                "style": 0
              },
              "sparkle": 0,
              "brow": {
                "amount": 1,
                "y": 0.45,
                "tilt": -0.95,
                "arch": -0.4
              },
              "mouth": {
                "curve": -0.95,
                "open": 0.2,
                "width": 0.5,
                "pad": 0,
                "teeth": 0.4,
                "tongue": 0
              },
              "tear": 0,
              "body": {
                "squash": -0.12
              }
            },
            "secretlySmitten": {
              "eye": {
                "open": 0.7,
                "size": 0.85,
                "spacing": 0.24,
                "y": -0.15,
                "pupil": 0.45,
                "squint": 0.2,
                "lidTilt": 0.2,
                "style": 0
              },
              "sparkle": 0.4,
              "brow": {
                "amount": 0.6,
                "y": -0.2,
                "tilt": 0.15,
                "arch": 0.2
              },
              "mouth": {
                "curve": 0.35,
                "open": 0,
                "width": 0.28,
                "pad": 0.9,
                "teeth": 0,
                "tongue": 0
              },
              "tear": 0,
              "body": {
                "squash": 0.08
              }
            },
            "cactusCrush": {
              "eye": {
                "open": 0.85,
                "size": 0.85,
                "spacing": 0.24,
                "y": -0.15,
                "pupil": 0.55,
                "squint": 0.35,
                "lidTilt": 0.3,
                "style": 0
              },
              "sparkle": 0.95,
              "brow": {
                "amount": 0.7,
                "y": -0.3,
                "tilt": 0.35,
                "arch": 0.4
              },
              "mouth": {
                "curve": 0.8,
                "open": 0.45,
                "width": 0.48,
                "pad": 1,
                "teeth": 0.3,
                "tongue": 0.6
              },
              "tear": 0,
              "body": {
                "squash": 0.18
              }
            },
            "caughtSmiling": {
              "eye": {
                "open": 0.6,
                "size": 0.85,
                "spacing": 0.24,
                "y": -0.15,
                "pupil": 0.4,
                "squint": 0.1,
                "lidTilt": 0.1,
                "style": 0
              },
              "sparkle": 0.3,
              "brow": {
                "amount": 0.85,
                "y": -0.1,
                "tilt": 0.3,
                "arch": 0.45
              },
              "mouth": {
                "curve": 0.95,
                "open": 0.3,
                "width": 0.52,
                "pad": 0.95,
                "teeth": 0.25,
                "tongue": 0.15
              },
              "tear": 0,
              "body": {
                "squash": 0.2
              }
            }
          },
          "touch": {
            "tap": "grumpy",
            "longPress": "cactusCrush",
            "dragLooksAt": true,
            "reactSeconds": 1.1,
            "tapBounce": 1,
            "haptics": true
          },
          "idle": {
            "blink": true,
            "breathe": true,
            "lookAround": true
          }
        }
        """#
        do {
            return try JSONDecoder().decode(CharacterSpec.self, from: Data(json.utf8)).sanitized()
        } catch {
            preconditionFailure("Invalid embedded character spec: \(error)")
        }
    }()

    static var grumbleprick: CharacterSpec { current }
}
