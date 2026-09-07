import SwiftUI
import UIKit

/// LingoLog's visual system: Apple-native structure with a playful, tactile
/// learning layer. Color always communicates a role; depth is reserved for
/// controls that can actually be pressed.
struct Theme {
    struct Colors {
        static let background = adaptive(light: "F5F7FA", dark: "101318")
        static let cardBackground = adaptive(light: "FFFFFF", dark: "1C2026")
        static let raised = adaptive(light: "E9EDF2", dark: "272C34")
        static let textPrimary = Color(uiColor: .label)
        static let textSecondary = Color(uiColor: .secondaryLabel)
        static let textTertiary = Color(uiColor: .tertiaryLabel)
        static let accent = adaptive(light: "10A57A", dark: "39D3A5")
        static let accentDepth = adaptive(light: "08775B", dark: "208F70")
        static let accentField = adaptive(light: "08775B", dark: "0A624E")
        static let accentSurface = adaptive(light: "DDF6ED", dark: "153A30")
        static let sky = adaptive(light: "258DDB", dark: "58B7F5")
        static let skyField = adaptive(light: "1767A5", dark: "174F76")
        static let skySurface = adaptive(light: "DFEFFB", dark: "172F42")
        static let violet = adaptive(light: "8063CF", dark: "A78BEF")
        static let violetField = adaptive(light: "6549B4", dark: "4B3B87")
        static let violetSurface = adaptive(light: "ECE7FA", dark: "2C2542")
        static let success = adaptive(light: "179B63", dark: "47D695")
        static let error = adaptive(light: "D94E55", dark: "FF7279")
        static let warning = adaptive(light: "E88918", dark: "FFB33E")
        static let secondaryAccent = sky
        static let divider = Color(uiColor: .separator)
        static let inputBackground = adaptive(light: "EDF1F5", dark: "252A32")
        static let inactive = Color(uiColor: .quaternarySystemFill)
        static let neutralDepth = adaptive(light: "CED5DD", dark: "0B0D11")

        private static func adaptive(light: String, dark: String) -> Color {
            Color(UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(Color(hex: dark))
                    : UIColor(Color(hex: light))
            })
        }
    }

    struct Metrics {
        static let pagePadding: CGFloat = 20
        static let cardRadius: CGFloat = 16
        static let controlRadius: CGFloat = 12
        static let sectionSpacing: CGFloat = 24
        static let minimumTapTarget: CGFloat = 44
    }

    struct Motion {
        static let quick = Animation.easeOut(duration: 0.14)
        static let standard = Animation.easeOut(duration: 0.22)
    }

    struct Typography {
        static func display(_ text: String) -> Text {
            Text(text).font(.system(.largeTitle, design: .rounded).weight(.heavy))
        }
        static func title(_ text: String) -> Text {
            Text(text).font(.system(.title2, design: .rounded).weight(.bold))
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
    }
}

struct SoftCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Theme.Colors.raised)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Metrics.controlRadius, style: .continuous))
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded).weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(isEnabled ? Theme.Colors.accentField : Theme.Colors.raised)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Metrics.controlRadius, style: .continuous))
            .shadow(
                color: isEnabled ? Theme.Colors.accentDepth : Theme.Colors.neutralDepth,
                radius: 0,
                x: 0,
                y: configuration.isPressed && !reduceMotion ? 0 : 4
            )
            .offset(y: configuration.isPressed && !reduceMotion ? 4 : 0)
        .padding(.bottom, 4)
        .opacity(isEnabled ? 1 : 0.52)
        .animation(reduceMotion ? nil : Theme.Motion.quick, value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded).weight(.bold))
            .foregroundStyle(Theme.Colors.accent)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(Theme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Metrics.controlRadius, style: .continuous))
            .shadow(
                color: Theme.Colors.neutralDepth,
                radius: 0,
                x: 0,
                y: configuration.isPressed && !reduceMotion ? 0 : 3
            )
            .offset(y: configuration.isPressed && !reduceMotion ? 3 : 0)
        .padding(.bottom, 3)
        .opacity(isEnabled ? 1 : 0.5)
        .animation(reduceMotion ? nil : Theme.Motion.quick, value: configuration.isPressed)
    }
}

struct LightButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded).weight(.bold))
            .foregroundStyle(Theme.Colors.accentField)
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Metrics.controlRadius, style: .continuous))
            .shadow(
                color: .black.opacity(0.18),
                radius: 0,
                x: 0,
                y: configuration.isPressed && !reduceMotion ? 0 : 4
            )
            .offset(y: configuration.isPressed && !reduceMotion ? 4 : 0)
        .padding(.bottom, 4)
        .opacity(isEnabled ? 1 : 0.52)
        .animation(reduceMotion ? nil : Theme.Motion.quick, value: configuration.isPressed)
    }
}

struct TactileButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.985 : 1)
            .opacity(configuration.isPressed ? 0.72 : 1)
            .animation(reduceMotion ? nil : Theme.Motion.quick, value: configuration.isPressed)
    }
}

struct IconTile: View {
    let symbol: String
    var color: Color = Theme.Colors.accent
    var size: CGFloat = 46

    var body: some View {
        Image(systemName: symbol)
            .font(.title2.weight(.semibold))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

struct SectionHeading: View {
    let title: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.Colors.textPrimary)
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.Colors.accent)
            }
        }
    }
}

struct PageHeader: View {
    let title: String
    let subtitle: String?

    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.Colors.textPrimary)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct AmbientBackground: View {
    var body: some View {
        Theme.Colors.background
            .ignoresSafeArea()
            .accessibilityHidden(true)
    }
}

extension View {
    func glassCard() -> some View { modifier(GlassCardModifier()) }
    func softCard() -> some View { modifier(SoftCardModifier()) }
    func primaryButtonStyle() -> some View { buttonStyle(PrimaryButtonStyle()) }
    func secondaryButtonStyle() -> some View { buttonStyle(SecondaryButtonStyle()) }
    func lightButtonStyle() -> some View { buttonStyle(LightButtonStyle()) }
    func tactileButtonStyle() -> some View { buttonStyle(TactileButtonStyle()) }
}
