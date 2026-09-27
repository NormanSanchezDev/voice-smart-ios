import CoreGraphics

/// 4pt spacing grid. Every gap, pad and inset in the app is one of these values.
public enum Spacing {
    public static let xxs: CGFloat = 2
    public static let xs: CGFloat = 4
    public static let s: CGFloat = 8
    public static let m: CGFloat = 12
    public static let l: CGFloat = 16
    public static let xl: CGFloat = 24
    public static let xxl: CGFloat = 32
    public static let xxxl: CGFloat = 48
}

/// Corner radii, kept in sync with the glass shapes so floating chrome and its
/// content share one silhouette.
public enum Radius {
    public static let none: CGFloat = 0
    public static let xs: CGFloat = 6
    public static let s: CGFloat = 10
    public static let m: CGFloat = 14
    public static let l: CGFloat = 20
    public static let xl: CGFloat = 28
    public static let pill: CGFloat = 999
}
