import SwiftUI

extension Color {
    // Main colors
    static let appBackground = Color(hex: "F2F2F7")
    static let appAccent = Color(hex: "2D7FF9")  // Brighter blue
    static let appText = Color(hex: "1C1C1E")
    
    // Enhanced color palette
    static let appSuccess = Color(hex: "34C759")  // Green
    static let appWarning = Color(hex: "FF9500")  // Orange
    static let appError = Color(hex: "FF3B30")    // Red
    static let appInfo = Color(hex: "5856D6")     // Purple
    static let appSecondary = Color(hex: "5AC8FA") // Light blue
    static let appTertiary = Color(hex: "FF2D55")  // Pink
    
    // Gradient collections
    static let blueGradient = LinearGradient(
        gradient: Gradient(colors: [Color(hex: "2D7FF9"), Color(hex: "5AC8FA")]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let greenGradient = LinearGradient(
        gradient: Gradient(colors: [Color(hex: "34C759"), Color(hex: "30D158")]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let redGradient = LinearGradient(
        gradient: Gradient(colors: [Color(hex: "FF3B30"), Color(hex: "FF2D55")]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Helper initializer for hex colors
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// SwiftUI theme extension
extension View {
    func appTheme() -> some View {
        self
            .tint(Color.appAccent)
            .preferredColorScheme(.light) // Default to light, system will handle dark mode
    }
}

// Encouraging messages for timer
struct EncouragingMessages {
    static let startMessages = [
        "Let's get productive! 💪",
        "Time to focus and shine! ✨",
        "You've got this! Starting strong 🚀",
        "Focus mode activated! 🎯",
        "It's go time! Ready to achieve? 💯",
        "Building momentum starts now! 🔄",
        "Your productivity journey begins! 🏃‍♂️",
        "Starting another successful session! 🏆"
    ]
    
    static let stopMessages = [
        "Great work! Session recorded ✅",
        "Another productive session complete! 🎉",
        "Well done! Take a moment to celebrate 🥳",
        "Progress made! Keep it up 📈",
        "Session saved! You're crushing it today 💪",
        "Excellent work! Break time earned 🍵",
        "Session recorded! One step closer to your goals 🎯",
        "Success! Your hard work is paying off 💎"
    ]
    
    static func randomStartMessage() -> String {
        startMessages.randomElement() ?? startMessages[0]
    }
    
    static func randomStopMessage() -> String {
        stopMessages.randomElement() ?? stopMessages[0]
    }
} 