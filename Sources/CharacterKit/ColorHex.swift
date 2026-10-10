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

extension String {
    /// Returns a lightened version of a hex color string (e.g. #RRGGBB).
    func lightenedHex(factor: Double = 0.25) -> String {
        var s = trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        var value: UInt64 = 0
        guard s.count >= 6, Scanner(string: s).scanHexInt64(&value) else {
            return self
        }
        let r = Double((value >> 16) & 0xFF)
        let g = Double((value >> 8) & 0xFF)
        let b = Double(value & 0xFF)
        let f = min(max(factor, 0.0), 1.0)
        let nr = Int(min(255.0, r + (255.0 - r) * f))
        let ng = Int(min(255.0, g + (255.0 - g) * f))
        let nb = Int(min(255.0, b + (255.0 - b) * f))
        return String(format: "#%02X%02X%02X", nr, ng, nb)
    }
}
