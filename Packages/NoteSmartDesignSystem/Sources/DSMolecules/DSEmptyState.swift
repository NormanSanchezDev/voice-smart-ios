import DSAtoms
import DSTokens
import SwiftUI

/// Explains why a surface is empty and offers the one action that fills it. Used by
/// Notes, Search and the vault, so an empty list never reads as a broken screen.
public struct DSEmptyState: View {
    private let systemImage: String
    private let title: String
    private let message: String
    private let actionTitle: String?
    private let onAction: (() -> Void)?

    public init(
        systemImage: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        onAction: (() -> Void)? = nil
    ) {
        self.systemImage = systemImage
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.onAction = onAction
    }

    public var body: some View {
        VStack(spacing: Spacing.l) {
            Image(systemName: systemImage)
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(Palette.textTertiary)
                .accessibilityHidden(true)

            VStack(spacing: Spacing.s) {
                Text(title)
                    .font(Typography.title3)
                    .foregroundStyle(Palette.textPrimary)

                Text(message)
                    .font(Typography.subheadline)
                    .foregroundStyle(Palette.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle, let onAction {
                DSButton(actionTitle, kind: .secondary, action: onAction)
            }
        }
        .padding(Spacing.xl)
        .frame(maxWidth: 420)
    }
}

/// Section title with optional trailing accessory, for grouping content without
/// resorting to nested cards.
public struct DSSectionHeader<Trailing: View>: View {
    private let title: String
    private let trailing: () -> Trailing

    public init(_ title: String, @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }) {
        self.title = title
        self.trailing = trailing
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(Typography.title3)
                .foregroundStyle(Palette.textPrimary)
            Spacer(minLength: Spacing.s)
            trailing()
        }
    }
}

public extension DSSectionHeader where Trailing == EmptyView {
    init(_ title: String) {
        self.init(title, trailing: { EmptyView() })
    }
}
