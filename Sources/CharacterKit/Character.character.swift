import Foundation
import CharacterKit

extension CharacterSpec {
    public static let current: CharacterSpec = {
        let json = #"""
        {
          "name": "Blobby",
          "version": 3,
          "schemaMinor": 1,
          "layout": {
            "mode": "contained",
            "faceCenterY": 0.49,
            "faceScale": 0.79,
            "faceMaxHeight": 0.45,
            "topInset": 0.23
          },
          "palette": {
            "body": "#FF9F5A",
            "bodyShade": "#F2833F",
            "eyeWhite": "#FFFFFF",
            "pupil": "#2A160A",
            "mouth": "#FFFFFF",
            "mouthOutline": "#7A2E0E",
            "brow": "#FFFFFF",
            "sparkle": "#FFFFFF",
            "pad": "#7A2E0E",
            "cavity": "#2A160A",
            "tongue": "#FF9F5A",
            "tear": "#78D9F4",
            "teeth": "#FFFFFF",
            "ear": "#FF9F5A",
            "earInner": "#F8BB95"
          },
          "parts": {
            "ears": {
              "style": "none",
              "anchor": "top",
              "length": 0.6,
              "width": 0.22,
              "tipRoundness": 0.8,
              "spread": 0.45,
              "baseY": -0.85,
              "baseAngle": 12,
              "bend": 0,
              "innerScale": 0.6,
              "spring": {
                "stiffness": 140,
                "damping": 9,
                "follow": 0.6
              }
            },
            "bodyShape": "cloud",
            "bumps": 4,
            "bumpiness": 0.09,
            "eyeCount": 2,
            "eyeSize": 1.07,
            "eyeSpacing": 0.18,
            "eyeY": -0.1,
            "pupilSize": 0.3,
            "mouthWidth": 0.42,
            "mouthY": 0.33,
            "mouthThickness": 1
          },
          "expressions": {
            "neutral": {
              "eye": {
                "open": 1,
                "size": 1.07,
                "spacing": 0.18,
                "y": -0.1,
                "pupil": 0.3,
                "squint": 0,
                "lidTilt": 0,
                "style": 0
              },
              "sparkle": 0,
              "brow": {
                "amount": 0,
                "y": -0.14,
                "tilt": 0,
                "arch": 0
              },
              "mouth": {
                "curve": 0,
                "open": 0.43,
                "width": 0.05,
                "pad": 0.89,
                "teeth": 1,
                "tongue": 0.67
              },
              "tear": 1,
              "body": {
                "squash": -0.3
              },
              "ears": {
                "perk": 0,
                "tilt": 0,
                "splay": 0
              }
            },
            "happy": {
              "eye": {
                "open": 1,
                "size": 1.07,
                "spacing": 0.18,
                "y": -0.23,
                "pupil": 0.3,
                "squint": 0.38,
                "lidTilt": 0,
                "style": 0
              },
              "sparkle": 0,
              "brow": {
                "amount": 0,
                "y": 0,
                "tilt": 0,
                "arch": 0
              },
              "mouth": {
                "curve": 0.85,
                "open": 0.65,
                "width": 0.95,
                "pad": 1,
                "teeth": 1,
                "tongue": 0.48
              },
              "tear": 1,
              "body": {
                "squash": 0
              },
              "ears": {
                "perk": 0,
                "tilt": 0,
                "splay": -0.02
              }
            },
            "annoyed": {
              "eye": {
                "open": 0.5,
                "size": 1.07,
                "spacing": 0.18,
                "y": -0.1,
                "pupil": 0.3,
                "squint": 0,
                "lidTilt": 0,
                "style": 0
              },
              "sparkle": 0,
              "brow": {
                "amount": 0,
                "y": 0,
                "tilt": 0,
                "arch": 0
              },
              "mouth": {
                "curve": -0.75,
                "open": 0,
                "width": 0.3,
                "pad": 1,
                "teeth": 0,
                "tongue": 0
              },
              "tear": 0,
              "body": {
                "squash": 0
              },
              "ears": {
                "perk": 0,
                "tilt": 0,
                "splay": 0
              }
            },
            "anxious": {
              "eye": {
                "open": 1,
                "size": 1.07,
                "spacing": 0.18,
                "y": -0.1,
                "pupil": 0.216,
                "squint": 0,
                "lidTilt": 0,
                "style": 0
              },
              "sparkle": 0,
              "brow": {
                "amount": 1,
                "y": 0,
                "tilt": 0.35,
                "arch": -0.15
              },
              "mouth": {
                "curve": -0.75,
                "open": 0,
                "width": 0,
                "pad": 1,
                "teeth": 0,
                "tongue": 0
              },
              "tear": 0,
              "body": {
                "squash": 0
              },
              "ears": {
                "perk": 0,
                "tilt": 0,
                "splay": 0
              }
            },
            "calm": {
              "eye": {
                "open": 0.65,
                "size": 1.07,
                "spacing": 0.18,
                "y": -0.1,
                "pupil": 0.3,
                "squint": 0.65,
                "lidTilt": 0,
                "style": 1
              },
              "sparkle": 0,
              "brow": {
                "amount": 0,
                "y": 0,
                "tilt": 0,
                "arch": 0
              },
              "mouth": {
                "curve": 0.8,
                "open": 0,
                "width": 0.35,
                "pad": 0,
                "teeth": 0,
                "tongue": 0
              },
              "tear": 0,
              "body": {
                "squash": 0
              },
              "ears": {
                "perk": 0,
                "tilt": 0,
                "splay": 0
              }
            },
            "sad": {
              "eye": {
                "open": 0.6,
                "size": 1.07,
                "spacing": 0.18,
                "y": -0.17,
                "pupil": 0.3,
                "squint": -0.25,
                "lidTilt": 0.85,
                "style": 0
              },
              "sparkle": 0,
              "brow": {
                "amount": 0,
                "y": 0,
                "tilt": 0,
                "arch": 0
              },
              "mouth": {
                "curve": -1,
                "open": 0.35,
                "width": 0.4,
                "pad": 1,
                "teeth": 0,
                "tongue": 0
              },
              "tear": 1,
              "body": {
                "squash": 0
              },
              "ears": {
                "perk": 0,
                "tilt": 0,
                "splay": 0
              }
            },
            "excited": {
              "eye": {
                "open": 1,
                "size": 1.1,
                "spacing": 0.18,
                "y": -0.14,
                "pupil": 0.77,
                "squint": 0,
                "lidTilt": 0,
                "style": 0
              },
              "sparkle": 1,
              "brow": {
                "amount": 1,
                "y": -0.12,
                "tilt": 0.27,
                "arch": 0.26
              },
              "mouth": {
                "curve": 0.85,
                "open": 1,
                "width": 0.65,
                "pad": 1,
                "teeth": 1,
                "tongue": 1
              },
              "tear": 0,
              "body": {
                "squash": 0
              },
              "ears": {
                "perk": 0,
                "tilt": 0,
                "splay": 0
              }
            }
          },
          "expressionOrder": [
            "neutral",
            "happy",
            "annoyed",
            "anxious",
            "calm",
            "sad",
            "excited"
          ],
          "defaultMood": "neutral",
          "touch": {
            "tap": "happy",
            "longPress": "annoyed",
            "holdSeconds": 1,
            "earFlick": 1,
            "earLean": 0.6,
            "dragLooksAt": true,
            "reactSeconds": 1.1,
            "tapBounce": 1,
            "haptics": true
          },
          "idle": {
            "blink": true,
            "breathe": true,
            "lookAround": true,
            "earTwitch": true
          }
        }
        """#
        do {
            return try JSONDecoder().decode(CharacterSpec.self, from: Data(json.utf8))
        } catch {
            preconditionFailure("Invalid embedded character spec: \(error)")
        }
    }()
}
