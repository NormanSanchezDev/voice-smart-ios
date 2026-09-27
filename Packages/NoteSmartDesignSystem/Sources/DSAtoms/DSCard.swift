import DSTokens
import SwiftUI

/// Opaque container for grouped content. Deliberately not glass: cards hold reading
/// material and must stay legible over any wallpaper or scroll position.
public struct DSCard<Content: View>: View {
    private let padding: CGFloat
    private let content: () -> Content

    public init(padding: CGFloat = Metrics.cardPadding, @ViewBuilder content: @escaping () -> Content) {
        self.padding = padding
        self.content = content
    }

    public var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: Radius.l, style: .continuous)
                    .fill(Palette.surface)
            }
            .overlay {
                RoundedRectangle(cornerRadius: Radius.l, style: .continuous)
                    .strokeBorder(Palette.separator, lineWidth: Metrics.hairline)
            }
    }
}

/// Hairline that matches the card border instead of the system default.
public struct DSSeparator: View {
    private let inset: CGFloat

    public init(inset: CGFloat = 0) {
        self.inset = inset
    }

    public var body: some View {
        Rectangle()
            .fill(Palette.separator)
            .frame(height: Metrics.separator)
            .padding(.leading, inset)
            .accessibilityHidden(true)
    }
}
