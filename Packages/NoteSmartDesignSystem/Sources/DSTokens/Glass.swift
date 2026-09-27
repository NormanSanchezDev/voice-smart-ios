import SwiftUI

/// Configuration for Liquid Glass surfaces.
///
/// Glass is chrome only: tab bars, toolbars, floating controls. It is never used
/// behind reading content, because a translucent material over a transcript hurts
/// legibility.
///
/// Named `GlassConfig` rather than `Glass` to avoid colliding with SwiftUI's own
/// `Glass` value type.
public enum GlassConfig {
    /// Shape of floating glass chrome.
    public static var cornerRadius: CGFloat { Radius.l }

    /// Subtle tint layered over the material, per elevation. Stays a token so
    /// `dsGlass` can resolve it against the surface it is drawn on.
    public static func tint(for emphasis: Emphasis) -> AdaptiveColor {
        switch emphasis {
        case .neutral: AdaptiveColor(light: 0xFFFFFF, dark: 0x1C1C22)
        case .accent: Palette.accentSoft.opacity(0.7)
        case .danger: Palette.recordingSoft.opacity(0.8)
        }
    }

    public enum Emphasis: Sendable {
        /// Standard floating chrome: navigation, toolbars.
        case neutral
        /// A primary action that should read as the active surface.
        case accent
        /// Destructive or live-capture state.
        case danger
    }

    /// Interactive glass reacts to press; non-interactive glass is for containers.
    public enum Interactivity: Sendable {
        case interactive
        case passive
    }
}
