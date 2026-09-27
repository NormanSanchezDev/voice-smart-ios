import SwiftUI

/// Semantic type roles. Views ask for a role, never a raw font.
public enum Typography {
    private static func font(_ size: CGFloat, _ weight: Font.Weight) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    public static let largeTitle = font(34, .bold)
    public static let title = font(28, .bold)
    public static let title2 = font(22, .semibold)
    public static let title3 = font(20, .semibold)
    public static let headline = font(17, .semibold)
    public static let body = font(17, .regular)
    public static let callout = font(16, .regular)
    public static let subheadline = font(15, .regular)
    public static let footnote = font(13, .regular)
    public static let caption = font(12, .regular)
    public static let caption2 = font(11, .medium)

    /// Recording durations and audio positions must not jitter as digits change.
    public static let timer = Font.system(size: 15, weight: .medium, design: .monospaced)
    public static let timerLarge = Font.system(size: 34, weight: .semibold, design: .monospaced)

    public static func emphasis(_ role: Font) -> Font {
        role
    }

    /// Line height tuned for long-form reading of transcripts.
    public static let transcriptLineSpacing: CGFloat = 6
}
