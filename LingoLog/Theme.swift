import SwiftUI

/// LingoLog's editorial design system: quiet surfaces, confident type, and one
/// high-signal accent. All colors are semantic so the same hierarchy survives
/// Dark Mode and increased contrast without per-screen branching.
struct Theme {
    struct Colors {
        static let background = adaptive(light: "FFFFFF", dark: "0B0B0C")
        static let cardBackground = adaptive(light: "F7F7F5", dark: "18181A")
        static let raised = adaptive(light: "FFFFFF", dark: "222225")
        static let textPrimary = adaptive(light: "0A0A0A", dark: "F7F7F5")
        static let textSecondary = adaptive(light: "858585", dark: "A1A1A6")
        static let accent = adaptive(light: "FF5A1F", dark: "FF6A32")
        static let secondaryAccent = accent
        static let success = adaptive(light: "198754", dark: "3ECF8E")
        static let error = adaptive(light: "D92D20", dark: "FF6961")
        static let warning = adaptive(light: "E97800", dark: "FF9F0A")
        static let divider = adaptive(light: "DEDEDC", dark: "343438")
        static let inputBackground = adaptive(light: "FFFFFF", dark: "222225")
        static let inactive = adaptive(light: "E7E7E5", dark: "3A3A3E")

        private static func adaptive(light: String, dark: String) -> Color {
            Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(Color(hex: dark)) : UIColor(Color(hex: light)) })
        }
    }

    struct Metrics {
        static let pagePadding: CGFloat = 20
        static let cardRadius: CGFloat = 24
        static let controlRadius: CGFloat = 16
    }

    struct Typography {
        static func display(_ text: String) -> Text {
            Text(text).font(.system(size: 38, weight: .regular, design: .default))
        }
        static func title(_ text: String) -> Text {
            Text(text).font(.system(.title2, design: .default)).fontWeight(.medium)
        }
        static func body(_ text: String) -> Text {
            Text(text).font(.system(.body, design: .default))
        }
    }
}

extension Color {
    init(hex: String) {
        let value = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var number: UInt64 = 0
        Scanner(string: value).scanHexInt64(&number)
        let a, r, g, b: UInt64
        switch value.count {
        case 3: (a, r, g, b) = (255, (number >> 8) * 17, (number >> 4 & 0xF) * 17, (number & 0xF) * 17)
        case 6: (a, r, g, b) = (255, number >> 16, number >> 8 & 0xFF, number & 0xFF)
        case 8: (a, r, g, b) = (number >> 24, number >> 16 & 0xFF, number >> 8 & 0xFF, number & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

struct GlassCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Theme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Metrics.cardRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.Metrics.cardRadius, style: .continuous)
                    .stroke(Theme.Colors.divider.opacity(0.45), lineWidth: 0.5)
            }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .default).weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(isEnabled ? Theme.Colors.textPrimary : Theme.Colors.inactive)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.82 : 1)
            .animation(.snappy(duration: 0.18), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Theme.Colors.textPrimary)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(Theme.Colors.inputBackground)
            .clipShape(Capsule())
            .overlay { Capsule().stroke(Theme.Colors.divider, lineWidth: 1) }
            .opacity(configuration.isPressed ? 0.65 : 1)
    }
}

extension View {
    func glassCard() -> some View { modifier(GlassCardModifier()) }
    func primaryButtonStyle() -> some View { buttonStyle(PrimaryButtonStyle()) }
    func secondaryButtonStyle() -> some View { buttonStyle(SecondaryButtonStyle()) }
}
