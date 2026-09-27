import DSTokens
import SwiftUI

public extension View {
    /// Applies Liquid Glass using the design system's configuration.
    ///
    /// - Parameters:
    ///   - emphasis: which tint layer to use.
    ///   - interactivity: `.interactive` for controls that respond to press.
    ///   - shape: silhouette; defaults to a continuous rounded rectangle.
    func dsGlass(
        emphasis: GlassConfig.Emphasis = .neutral,
        interactivity: GlassConfig.Interactivity = .passive,
        in shape: some Shape = .rect(cornerRadius: GlassConfig.cornerRadius, style: .continuous)
    ) -> some View {
        var glass: Glass = .regular
        glass = glass.tint(GlassConfig.tint(for: emphasis))
        glass = interactivity == .interactive ? glass.interactive() : glass

        return glassEffect(glass, in: shape)
    }

    /// Grouped glass shapes inside one container morph into each other instead of
    /// stacking independently, which is what makes the effect read as liquid.
    func dsGlassContainer(spacing: CGFloat = Spacing.s) -> some View {
        GlassEffectContainer(spacing: spacing) { self }
    }
}
