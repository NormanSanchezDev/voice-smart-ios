import DSAtoms
import DSMolecules
import DSTokens
import SwiftUI

/// One hit in a search result, with the matched terms highlighted so the user can
/// see why a result matched.
public struct DSSearchResultRow: View {
    private let title: String
    private let snippet: String
    private let score: Double
    private let onSelect: () -> Void

    public init(title: String, snippet: String, score: Double, onSelect: @escaping () -> Void) {
        self.title = title
        self.snippet = snippet
        self.score = score
        self.onSelect = onSelect
    }

    public var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Text(title)
                        .font(Typography.headline)
                        .foregroundStyle(Palette.textPrimary)
                        .lineLimit(1)
                    Spacer(minLength: Spacing.s)
                    if score > 0.6 {
                        DSBadge(String(format: "%.0f%%", score * 100), systemImage: "sparkle", tone: .accent)
                    }
                }

                Text(snippet)
                    .font(Typography.subheadline)
                    .foregroundStyle(Palette.textSecondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
            .padding(.vertical, Spacing.s)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}
