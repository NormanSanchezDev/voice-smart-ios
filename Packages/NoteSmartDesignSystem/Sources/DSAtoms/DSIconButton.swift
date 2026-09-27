import DSTokens
import SwiftUI

/// Square, icon-only control. Always keeps a 44pt hit area even when the glyph is
/// smaller, so it stays comfortable to tap.
public struct DSIconButton: View {
    private let systemImage: String
    private let accessibilityLabel: String
    private let size: CGFloat
    private let isActive: Bool
    private let action: () -> Void

    public init(
        systemImage: String,
        accessibilityLabel: String,
        size: CGFloat = 40,
        isActive: Bool = false,
        action: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.accessibilityLabel = accessibilityLabel
        self.size = size
        self.isActive = isActive
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: size * 0.42, weight: .medium))
                .foregroundStyle(isActive ? Palette.accent : Palette.textSecondary)
                .frame(width: Metrics.minimumTapTarget, height: Metrics.minimumTapTarget)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(accessibilityLabel))
        .accessibilityAddTraits(isActive ? [.isSelected] : [])
    }
}
