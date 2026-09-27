import DSAtoms
import DSMolecules
import DSTokens
import SwiftUI

/// Scaffold for a scrolling list screen: background, title, optional empty state and
/// a floating glass action area that sits above the content.
public struct DSListScaffold<Content: View>: View {
    private let title: String
    private let emptyState: DSEmptyState?
    private let isEmpty: Bool
    private let floating: AnyView?
    private let content: () -> Content

    public init(
        title: String,
        isEmpty: Bool = false,
        emptyState: DSEmptyState? = nil,
        @ViewBuilder floating: @escaping () -> some View = { EmptyView() },
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.isEmpty = isEmpty
        self.emptyState = emptyState
        self.floating = AnyView(floating())
        self.content = content
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            Palette.surfaceSunken.ignoresSafeArea()

            if isEmpty, let emptyState {
                DSReadingColumn {
                    VStack {
                        Spacer()
                        emptyState
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                content()
            }

            floatingBar
        }
        .navigationTitle(title)
    }

    @ViewBuilder
    private var floatingBar: some View {
        if let floating {
            VStack {
                Spacer()
                floating
                    .padding(.horizontal, Metrics.screenGutter)
                    .padding(.bottom, Spacing.l)
            }
            .allowsHitTesting(true)
        }
    }
}

/// A cluster of floating glass controls, e.g. the record button on the capture tab.
public struct DSFloatingToolbar<Content: View>: View {
    private let content: () -> Content

    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    public var body: some View {
        HStack(spacing: Spacing.m) {
            content()
        }
        .padding(Spacing.m)
        .dsGlass(emphasis: .neutral, interactivity: .interactive, in: .capsule)
    }
}
