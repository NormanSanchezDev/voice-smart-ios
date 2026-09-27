import SwiftUI

/// Every color the app is allowed to use. Views reference these names instead of
/// hardcoding hex values, so a palette change never touches a feature.
public enum Palette {
    // MARK: Brand

    public static let accent = Color(light: 0x5B5BD6, dark: 0x8B8BF0)
    public static let accentPressed = Color(light: 0x4A4ABF, dark: 0x7474E4)
    public static let accentSoft = Color(light: 0xEEEEFB, dark: 0x26264A)

    // MARK: Surfaces

    public static let surface = Color(light: 0xFFFFFF, dark: 0x16161C)
    public static let surfaceSunken = Color(light: 0xF4F4F7, dark: 0x101015)
    public static let surfaceElevated = Color(light: 0xFAFAFC, dark: 0x1E1E25)
    public static let surfaceOverlay = Color(light: 0xFFFFFF, dark: 0x24242C)

    // MARK: Content

    public static let textPrimary = Color(light: 0x14141A, dark: 0xF5F5F7)
    public static let textSecondary = Color(light: 0x6B6B76, dark: 0xA0A0AB)
    public static let textTertiary = Color(light: 0x94949F, dark: 0x767681)
    public static let textOnAccent = Color.white

    public static let separator = Color(light: 0xE4E4EA, dark: 0x2E2E38)
    public static let border = Color(light: 0xD8D8E0, dark: 0x383843)

    // MARK: Semantic

    public static let success = Color(light: 0x2E9E5B, dark: 0x4FC97D)
    public static let warning = Color(light: 0xB7791F, dark: 0xE5A83C)
    public static let danger = Color(light: 0xD13438, dark: 0xFF6B6F)
    public static let info = Color(light: 0x0A7EA4, dark: 0x3FB6DC)

    // MARK: Recording

    /// Reserved for the capture affordance, so a live recording is never confused
    /// with a destructive or disabled action.
    public static let recording = Color(light: 0xE5484D, dark: 0xFF6369)
    public static let recordingSoft = Color(light: 0xFDECEC, dark: 0x3A1F22)
}
