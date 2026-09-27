import DSTokens
import SwiftUI

/// Constrains long-form content to a comfortable measure and centers it. Applied to
/// every transcript and note body so text never stretches across an iPad.
public struct DSReadingColumn<Content: View>: View {
    private let content: () -> Content

    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    public var body: some View {
        content()
            .frame(maxWidth: Metrics.readingMaxWidth)
            .frame(maxWidth: .infinity)
    }
}
