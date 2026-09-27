import DSTokens
import SwiftUI

public enum DSButtonKind: Sendable {
    /// Highest emphasis: one per screen.
    case primary
    /// Supporting action next to a primary one.
    case secondary
    /// Low-emphasis action on a glass surface.
    case glass
    /// Destructive confirmation.
    case destructive
}

/// The app's only button. Features pick a `kind` and never style a raw `Button`.
public struct DSButton<Label: View>: View {
    private let kind: DSButtonKind
    private let isEnabled: Bool
    private let fullWidth: Bool
    private let action: () -> Void
    private let label: () -> Label

    public init(
        kind: DSButtonKind = .primary,
        isEnabled: Bool = true,
        fullWidth: Bool = false,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.kind = kind
        self.isEnabled = isEnabled
        self.fullWidth = fullWidth
        self.action = action
        self.label = label
    }

    public init(
        _ title: String,
        kind: DSButtonKind = .primary,
        isEnabled: Bool = true,
        fullWidth: Bool = false,
        action: @escaping () -> Void
    ) where Label == Text {
        self.init(
            kind: kind,
            isEnabled: isEnabled,
            fullWidth: fullWidth,
            action: action
        ) {
            Text(title)
        }
    }

    public var body: some View {
        Button(action: action) {
            label()
                .font(Typography.headline)
                .frame(maxWidth: fullWidth ? .infinity : nil)
                .frame(minHeight: Metrics.minimumTapTarget)
                .padding(.horizontal, fullWidth ? Spacing.l : Spacing.xl)
        }
        .buttonStyle(DSButtonStyle(kind: kind))
        .disabled(!isEnabled)
    }
}

struct DSButtonStyle: ButtonStyle {
    let kind: DSButtonKind

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(foreground)
            .background {
                switch kind {
                case .primary:
                    Capsule().fill(Palette.accent.opacity(configuration.isPressed ? 0.85 : 1))
                case .secondary:
                    Capsule().fill(Palette.accentSoft)
                case .glass:
                    Capsule().fill(.clear)
                case .destructive:
                    Capsule().fill(Palette.danger.opacity(configuration.isPressed ? 0.85 : 1))
                }
            }
            .overlay {
                if kind == .secondary {
                    Capsule().strokeBorder(Palette.accent.opacity(0.25), lineWidth: Metrics.hairline)
                }
            }
            .modifier(GlassChrome(kind: kind, isPressed: configuration.isPressed))
            .animation(Motion.Spring.gentle, value: configuration.isPressed)
    }

    private var foreground: AdaptiveColor {
        switch kind {
        case .primary, .destructive: Palette.textOnAccent
        case .secondary: Palette.accent
        case .glass: Palette.textPrimary
        }
    }
}

/// Glass for the kind that is meant to float; solid fills for the rest, so a screen
/// never turns into a pile of translucent blobs.
private struct GlassChrome: ViewModifier {
    let kind: DSButtonKind
    let isPressed: Bool

    func body(content: Content) -> some View {
        switch kind {
        case .glass:
            content
                .dsGlass(emphasis: .neutral, interactivity: .interactive, in: .capsule)
                .opacity(isPressed ? 0.7 : 1)
        default:
            content
        }
    }
}
