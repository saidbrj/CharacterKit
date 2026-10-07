import SwiftUI

extension Color {
    /// Accepts "#RRGGBB", "RRGGBB", "#RRGGBBAA" (case-insensitive). Falls back to magenta so mistakes are visible.
    init(characterHex hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }

        var value: UInt64 = 0
        guard Scanner(string: s).scanHexInt64(&value) else {
            self = Color(red: 1, green: 0, blue: 1)
            return
        }

        switch s.count {
        case 6:
            self = Color(
                red: Double((value >> 16) & 0xFF) / 255,
                green: Double((value >> 8) & 0xFF) / 255,
                blue: Double(value & 0xFF) / 255
            )
        case 8:
            self = Color(
                red: Double((value >> 24) & 0xFF) / 255,
                green: Double((value >> 16) & 0xFF) / 255,
                blue: Double((value >> 8) & 0xFF) / 255,
                opacity: Double(value & 0xFF) / 255
            )
        default:
            self = Color(red: 1, green: 0, blue: 1)
        }
    }
}
