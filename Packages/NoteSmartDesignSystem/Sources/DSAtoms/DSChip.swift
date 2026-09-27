import DSTokens
import SwiftUI

/// A tag, a filter, or a removable item. `onRemove` turns it into a dismissible chip.
public struct DSChip: View {
    private let text: String
    private let systemImage: String?
    private let onRemove: (() -> Void)?

    public init(_ text: String, systemImage: String? = nil, onRemove: (() -> Void)? = nil) {
        self.text = text
        self.systemImage = systemImage
        self.onRemove = onRemove
    }

    public var body: some View {
        HStack(spacing: Spacing.xs) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.caption2)
            }
            Text(text)
                .font(Typography.footnote)
                .lineLimit(1)
            if let onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Quitar \(text)"))
            }
        }
        .foregroundStyle(Palette.accent)
        .padding(.horizontal, Spacing.m)
        .padding(.vertical, Spacing.s)
        .background {
            Capsule().fill(Palette.accentSoft)
        }
        .overlay {
            Capsule().strokeBorder(Palette.accent.opacity(0.18), lineWidth: Metrics.hairline)
        }
    }
}

/// Small status marker: note kind, AI source, error counts.
public struct DSBadge: View {
    public enum Tone: Sendable {
        case neutral, accent, success, warning, danger

        var color: Color {
            switch self {
            case .neutral: Palette.textTertiary
            case .accent: Palette.accent
            case .success: Palette.success
            case .warning: Palette.warning
            case .danger: Palette.danger
            }
        }
    }

    private let text: String
    private let systemImage: String?
    private let tone: Tone

    public init(_ text: String, systemImage: String? = nil, tone: Tone = .neutral) {
        self.text = text
        self.systemImage = systemImage
        self.tone = tone
    }

    public var body: some View {
        HStack(spacing: Spacing.xxs) {
            if let systemImage {
                Image(systemName: systemImage).font(.system(size: 9, weight: .semibold))
            }
            Text(text).font(Typography.caption2)
        }
        .foregroundStyle(tone.color)
        .padding(.horizontal, Spacing.s)
        .padding(.vertical, Spacing.xxs)
        .background {
            Capsule().fill(tone.color.opacity(0.12))
        }
    }
}
