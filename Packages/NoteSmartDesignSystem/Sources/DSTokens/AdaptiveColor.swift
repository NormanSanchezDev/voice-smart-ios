import SwiftUI

/// A color token that carries both appearances and lets SwiftUI pick one.
///
/// The palette needs light and dark values to live next to each other, in code,
/// where a palette change is one diff. A plain `Color` cannot do that by itself:
/// it either names an asset or bakes in a single appearance. So a token is a
/// `ShapeStyle` instead, and SwiftUI resolves it against the real environment at
/// draw time — the same mechanism behind `HierarchicalShapeStyle`.
///
/// Consequences worth knowing:
/// - No UIKit, no asset catalog, no `UIColor` dynamic provider. The pair resolves
///   against the view's own `colorScheme`, so a token measured on a dark surface
///   is measurably the dark value.
/// - A `ShapeStyle` cannot be stored, interpolated or passed where a `Color` is
///   required. Use `resolved(in:)` at those few sites, with the environment in hand.
public struct AdaptiveColor: ShapeStyle, Sendable, Hashable {

    public typealias Resolved = Color.Resolved

    public let light: Color
    public let dark: Color

    /// Both appearances from `0xRRGGBB`.
    public init(light: UInt32, dark: UInt32) {
        self.light = Color(hex: light)
        self.dark = Color(hex: dark)
    }

    /// One value for both appearances.
    public init(_ hex: UInt32) {
        self.init(light: hex, dark: hex)
    }

    /// Lifts a plain `Color` into a token, for the rare case where a caller has a
    /// color that is not a palette entry.
    public init(_ color: Color) {
        self.init(light: color, dark: color)
    }

    public init(light: Color, dark: Color) {
        self.light = light
        self.dark = dark
    }

    public func resolve(in environment: EnvironmentValues) -> Color.Resolved {
        (environment.colorScheme == .dark ? dark : light).resolve(in: environment)
    }

    /// The token as a plain `Color` for one appearance. Needed where a value must
    /// be a `Color` — an animation interpolation, a gradient stop, a stored
    /// property — because a `ShapeStyle` cannot be stored.
    public func resolved(in environment: EnvironmentValues) -> Color {
        Color(resolve(in: environment))
    }

    /// Applies alpha to both appearances, so `Palette.accentSoft.opacity(0.7)`
    /// stays a token instead of collapsing to a single light-mode color.
    public func opacity(_ value: Double) -> AdaptiveColor {
        AdaptiveColor(light: light.opacity(value), dark: dark.opacity(value))
    }
}

// MARK: - Reading a color

public extension Color {

    init(hex: UInt32, opacity: Double = 1) {
        let channel = { (shift: UInt32) in
            Double((hex >> shift) & 0xFF) / 255
        }
        self.init(
            .sRGB,
            red: channel(16),
            green: channel(8),
            blue: channel(0),
            opacity: opacity
        )
    }

    /// WCAG relative luminance of the appearance SwiftUI resolves for this
    /// environment. `Color.Resolved` already stores linear channels, so there is no
    /// gamma left to undo — the previous hand-rolled sRGB conversion was both
    /// slower and less accurate.
    func luminance(in environment: EnvironmentValues) -> Double {
        let c = resolve(in: environment)
        return 0.2126 * Double(c.linearRed)
            + 0.7152 * Double(c.linearGreen)
            + 0.0722 * Double(c.linearBlue)
    }
}

public extension ShapeStyle where Resolved == Color.Resolved {

    func resolved(in environment: EnvironmentValues) -> Color {
        Color(resolve(in: environment))
    }

    func luminance(in environment: EnvironmentValues) -> Double {
        resolved(in: environment).luminance(in: environment)
    }

    /// Near-black or white, whichever stays readable on top of this fill.
    func readableForeground(in environment: EnvironmentValues) -> Color {
        luminance(in: environment) > 0.45 ? Color(hex: 0x14141A) : .white
    }
}
