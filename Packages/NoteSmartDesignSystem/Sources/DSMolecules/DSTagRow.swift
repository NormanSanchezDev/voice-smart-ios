import DSAtoms
import DSTokens
import SwiftUI

/// Wraps chips onto as many lines as needed. Tag lists are unbounded, so a fixed
/// `HStack` would clip or force a horizontal scroll.
public struct DSFlowLayout: Layout {
    public var spacing: CGFloat
    public var lineSpacing: CGFloat

    public init(spacing: CGFloat = Spacing.s, lineSpacing: CGFloat = Spacing.s) {
        self.spacing = spacing
        self.lineSpacing = lineSpacing
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let rows = arrange(subviews: subviews, maxWidth: maxWidth)
        let height = rows.reduce(0) { total, row in
            total + (row.height + lineSpacing)
        }
        return CGSize(width: proposal.width ?? rows.map(\.width).max() ?? 0, height: max(0, height - lineSpacing))
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = arrange(subviews: subviews, maxWidth: bounds.width)
        var y = bounds.minY

        for row in rows {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(
                    at: CGPoint(x: x, y: y + (row.height - size.height) / 2),
                    proposal: ProposedViewSize(size)
                )
                x += size.width + spacing
            }
            y += row.height + lineSpacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(subviews: Subviews, maxWidth: CGFloat) -> [Row] {
        var rows: [Row] = []
        var current = Row()

        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let additional = current.indices.isEmpty ? size.width : current.width + spacing + size.width

            if additional > maxWidth, !current.indices.isEmpty {
                rows.append(current)
                current = Row(indices: [index], width: size.width, height: size.height)
            } else {
                current.indices.append(index)
                current.width = additional
                current.height = max(current.height, size.height)
            }
        }

        if !current.indices.isEmpty { rows.append(current) }
        return rows
    }
}

/// Row of removable tag chips.
public struct DSTagRow: View {
    private let tags: [String]
    private let onRemove: ((String) -> Void)?

    public init(tags: [String], onRemove: ((String) -> Void)? = nil) {
        self.tags = tags
        self.onRemove = onRemove
    }

    public var body: some View {
        DSFlowLayout {
            ForEach(tags, id: \.self) { tag in
                DSChip(tag, systemImage: "number", onRemove: onRemove.map { handler in { handler(tag) } })
            }
        }
    }
}
