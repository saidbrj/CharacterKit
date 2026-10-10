#!/usr/bin/swift
// Run with: swift tools/regen_goldens.swift
// Regenerates the golden PNG fixtures in Tests/CharacterKitTests/Fixtures/blobby-pngs/
// from the current Swift CharacterRenderer output.

import Foundation
import AppKit
import SwiftUI

// We can't import CharacterKit here (it's a package), so we inline the render call
// via the test binary. Instead, use a simpler approach: run the test with REGEN_GOLDEN=1

print("To regenerate goldens, run:")
print("  REGEN_GOLDEN=1 swift test --filter testGoldenImagePixelMatchNeutralAndExcited")
print("")
print("This will write new PNGs to Tests/CharacterKitTests/Fixtures/blobby-pngs/")
