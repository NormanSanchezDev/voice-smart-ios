import CoreGraphics

/// Layout constants that are not spacing: sizing rules shared across features.
public enum Metrics {
    /// Apple's minimum comfortable hit target.
    public static let minimumTapTarget: CGFloat = 44

    /// Primary control diameter (record button).
    public static let recordButton: CGFloat = 72
    public static let recordButtonCompact: CGFloat = 56

    /// Above this width, content is centered instead of stretched so long
    /// transcripts stay readable on iPad.
    public static let readingMaxWidth: CGFloat = 680

    public static let screenGutter: CGFloat = 20
    public static let cardPadding: CGFloat = 16

    public static let hairline: CGFloat = 1 / 3
    public static let separator: CGFloat = 1
}
