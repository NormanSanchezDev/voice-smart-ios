import DSTokens
import SwiftUI

/// Single-line text input with the system's chrome removed, so search and note
/// fields look like one control across the app.
public struct DSTextField: View {
    private let placeholder: String
    private let systemImage: String?
    private let text: Binding<String>
    private let onSubmit: (() -> Void)?

    public init(
        _ placeholder: String,
        systemImage: String? = nil,
        text: Binding<String>,
        onSubmit: (() -> Void)? = nil
    ) {
        self.placeholder = placeholder
        self.systemImage = systemImage
        self.text = text
        self.onSubmit = onSubmit
    }

    public var body: some View {
        HStack(spacing: Spacing.s) {
            if let systemImage {
                Image(systemName: systemImage)
                    .foregroundStyle(Palette.textTertiary)
            }
            field
        }
        .padding(.horizontal, Spacing.m)
        .frame(minHeight: Metrics.minimumTapTarget)
        .background {
            RoundedRectangle(cornerRadius: Radius.m, style: .continuous)
                .fill(Palette.surfaceSunken)
        }
        .overlay {
            RoundedRectangle(cornerRadius: Radius.m, style: .continuous)
                .strokeBorder(Palette.border, lineWidth: Metrics.hairline)
        }
    }

    private var field: some View {
        TextField(placeholder, text: text, prompt: Text(placeholder).foregroundStyle(Palette.textTertiary))
            .font(Typography.body)
            .foregroundStyle(Palette.textPrimary)
            .submitLabel(.search)
            .onSubmit { onSubmit?() }
    }
}
