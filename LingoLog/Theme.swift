import SwiftUI

struct Theme {
    struct Colors {
        static let background = Color(hex: "F5F2EB") // Warm Paper
        static let textPrimary = Color(hex: "2D2D2D") // Charcoal
        static let textSecondary = Color(hex: "686868") // Soft Gray
        static let accent = Color(hex: "2D5D4B") // Deep Emerald
        static let secondaryAccent = Color(hex: "C6AD8F") // Antique Brass
        static let success = Color(hex: "4A7C59") // Muted Green
        static let error = Color(hex: "C4554D") // Muted Red
        static let warning = Color(hex: "E2B33C") // Burnt Yellow
    }
    
    struct Typography {
        static func display(_ text: String) -> Text {
            Text(text)
                .font(.system(.largeTitle, design: .serif))
                .fontWeight(.medium)
        }
        
        static func title(_ text: String) -> Text {
            Text(text)
                .font(.system(.title2, design: .serif))
                .fontWeight(.semibold)
        }
        
        static func body(_ text: String) -> Text {
            Text(text)
                .font(.system(.body, design: .rounded))
        }
    }
}

// MARK: - Color Extension
extension Color {
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
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Modifiers
struct GlassCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 5)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded))
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Theme.Colors.accent)
            .cornerRadius(16)
            .shadow(color: Theme.Colors.accent.opacity(0.3), radius: 8, x: 0, y: 4)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

extension View {
    func glassCard() -> some View {
        self.modifier(GlassCardModifier())
    }
    
    func primaryButtonStyle() -> some View {
        self.buttonStyle(PrimaryButtonStyle())
    }
}
