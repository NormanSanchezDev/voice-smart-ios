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
        modifier(DSGlassModifier(emphasis: emphasis, interactivity: interactivity, shape: shape))
    }

    /// Grouped glass shapes inside one container morph into each other instead of
    /// stacking independently, which is what makes the effect read as liquid.
    func dsGlassContainer(spacing: CGFloat = Spacing.s) -> some View {
        GlassEffectContainer(spacing: spacing) { self }
    }
}

/// `Glass.tint(_:)` takes a `Color`, not a `ShapeStyle`, so the token has to be
/// resolved before it can be handed over. Doing that in a modifier is what makes the
/// resolution correct: the modifier sees the same environment the glass is drawn in,
/// so a dark surface gets the dark tint.
private struct DSGlassModifier<S: Shape>: ViewModifier {
    @Environment(\.self) private var environment

    let emphasis: GlassConfig.Emphasis
    let interactivity: GlassConfig.Interactivity
    let shape: S

    func body(content: Content) -> some View {
        var glass: Glass = .regular
        glass = glass.tint(GlassConfig.tint(for: emphasis).resolved(in: environment))
        glass = interactivity == .interactive ? glass.interactive() : glass

        return content.glassEffect(glass, in: shape)
    }
}
