import Testing
import SwiftUI
@testable import TodoTimers

@Suite("Color Extension Tests")
struct ColorExtensionTests {

    // MARK: - Hex Parsing Tests

    @Test("Hex init with hash prefix parses correctly")
    func hexInit_WithHashPrefix_ParsesCorrectly() {
        let color = Color(hex: "#FF0000")
        let uiColor = UIColor(color)

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        #expect(abs(red - 1.0) < 0.01)  // Red should be ~1.0
        #expect(abs(green - 0.0) < 0.01)  // Green should be ~0.0
        #expect(abs(blue - 0.0) < 0.01)  // Blue should be ~0.0
    }

    @Test("Hex init without hash prefix parses correctly")
    func hexInit_WithoutHashPrefix_ParsesCorrectly() {
        let color = Color(hex: "00FF00")
        let uiColor = UIColor(color)

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        #expect(abs(red - 0.0) < 0.01)  // Red should be ~0.0
        #expect(abs(green - 1.0) < 0.01)  // Green should be ~1.0
        #expect(abs(blue - 0.0) < 0.01)  // Blue should be ~0.0
    }

    @Test("Hex init with six digit hex parses correctly")
    func hexInit_SixDigitHex_ParsesCorrectly() {
        let color = Color(hex: "007AFF")  // iOS blue
        let uiColor = UIColor(color)

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        // Should be approximately (0, 122/255, 255/255)
        #expect(abs(red - 0.0) < 0.01)
        #expect(abs(green - 0.478) < 0.01)  // 122/255 ≈ 0.478
        #expect(abs(blue - 1.0) < 0.01)
    }

    @Test("Hex init for red color has correct RGB")
    func hexInit_RedColor_CorrectRGB() {
        let color = Color(hex: "#FF0000")
        let uiColor = UIColor(color)

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        #expect(abs(red - 1.0) < 0.01)
        #expect(abs(green - 0.0) < 0.01)
        #expect(abs(blue - 0.0) < 0.01)
        #expect(abs(alpha - 1.0) < 0.01)  // Opacity should be 1.0
    }

    @Test("Hex init for green color has correct RGB")
    func hexInit_GreenColor_CorrectRGB() {
        let color = Color(hex: "#00FF00")
        let uiColor = UIColor(color)

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        #expect(abs(red - 0.0) < 0.01)
        #expect(abs(green - 1.0) < 0.01)
        #expect(abs(blue - 0.0) < 0.01)
    }

    @Test("Hex init for blue color has correct RGB")
    func hexInit_BlueColor_CorrectRGB() {
        let color = Color(hex: "#0000FF")
        let uiColor = UIColor(color)

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        #expect(abs(red - 0.0) < 0.01)
        #expect(abs(green - 0.0) < 0.01)
        #expect(abs(blue - 1.0) < 0.01)
    }

    // MARK: - Common Color Tests

    @Test("iOS system blue parses correctly")
    func hexInit_SystemBlue_ParsesCorrectly() {
        let color = Color(hex: "#007AFF")
        let uiColor = UIColor(color)

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        #expect(abs(blue - 1.0) < 0.01)  // Blue channel should be max
    }

    @Test("Black color parses correctly")
    func hexInit_Black_ParsesCorrectly() {
        let color = Color(hex: "#000000")
        let uiColor = UIColor(color)

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        #expect(abs(red - 0.0) < 0.01)
        #expect(abs(green - 0.0) < 0.01)
        #expect(abs(blue - 0.0) < 0.01)
    }

    @Test("White color parses correctly")
    func hexInit_White_ParsesCorrectly() {
        let color = Color(hex: "#FFFFFF")
        let uiColor = UIColor(color)

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        #expect(abs(red - 1.0) < 0.01)
        #expect(abs(green - 1.0) < 0.01)
        #expect(abs(blue - 1.0) < 0.01)
    }
}
