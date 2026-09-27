import DSAtoms
import DSMolecules
import DSTokens
import SwiftUI

/// Summary of a saved note for list surfaces.
///
/// Takes primitives rather than domain entities on purpose: the design system stays
/// reusable and the app maps its models onto this shape.
public struct DSNoteCard: View {
    public struct Badge: Identifiable, Sendable {
        public let id = UUID()
        public let text: String
        public let systemImage: String?
        public let tone: DSBadge.Tone

        public init(_ text: String, systemImage: String? = nil, tone: DSBadge.Tone = .neutral) {
            self.text = text
            self.systemImage = systemImage
            self.tone = tone
        }
    }

    private let title: String
    private let preview: String
    private let date: Date
    private let duration: TimeInterval?
    private let tags: [String]
    private let badges: [Badge]
    private let action: () -> Void

    public init(
        title: String,
        preview: String,
        date: Date,
        duration: TimeInterval? = nil,
        tags: [String] = [],
        badges: [Badge] = [],
        action: @escaping () -> Void = {}
    ) {
        self.title = title
        self.preview = preview
        self.date = date
        self.duration = duration
        self.tags = tags
        self.badges = badges
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            DSCard {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
                        Text(title)
                            .font(Typography.headline)
                            .foregroundStyle(Palette.textPrimary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        Spacer(minLength: 0)

                        if let duration {
                            Text(Self.formattedDuration(duration))
                                .font(Typography.timer)
                                .foregroundStyle(Palette.textTertiary)
                        }
                    }

                    if !preview.isEmpty {
                        Text(preview)
                            .font(Typography.subheadline)
                            .foregroundStyle(Palette.textSecondary)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                    }

                    if !badges.isEmpty || !tags.isEmpty {
                        DSFlowLayout {
                            ForEach(badges) { badge in
                                DSBadge(badge.text, systemImage: badge.systemImage, tone: badge.tone)
                            }
                            ForEach(tags.prefix(4), id: \.self) { tag in
                                DSChip(tag, systemImage: "number")
                            }
                            if tags.count > 4 {
                                DSBadge("+\(tags.count - 4)")
                            }
                        }
                    }

                    Text(date, format: .dateTime.day().month(.abbreviated).hour().minute())
                        .font(Typography.caption)
                        .foregroundStyle(Palette.textTertiary)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }

    static func formattedDuration(_ duration: TimeInterval) -> String {
        let total = Int(duration.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
