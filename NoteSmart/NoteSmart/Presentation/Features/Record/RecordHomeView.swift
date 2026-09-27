//
//  RecordHomeView.swift
//  NoteSmart
//

import DSAtoms
import DSMolecules
import DSOrganisms
import DSTokens
import NoteSmartDomain
import SwiftUI

/// The capture screen: one button, and nothing else to read.
///
/// The vault lives behind "Más" instead of under the record button. The old layout
/// put the button on top of the note list, which meant the list's empty state and the
/// button competed for the same screen and the user never knew which was the app.
/// This screen holds exactly one control; everything else is one tap away.
struct RecordHomeView: View {

    @Environment(AppEnvironment.self) private var environment
    @State private var recorder: RecordViewModel?
    @State private var path: [Route] = []

    var body: some View {
        NavigationStack(path: $path) {
            captureScreen
                .toolbar { toolbar }
                .navigationDestination(for: Route.self) { route in
                    destination(for: route)
                }
        }
        .task(id: environment.state) {
            guard case .ready = environment.state, recorder == nil else { return }
            let recorder = RecordViewModel(environment: environment)
            recorder.onNoteSaved = { note in
                path.append(.note(note.id))
            }
            self.recorder = recorder
        }
    }

    // MARK: - Screens

    private var captureScreen: some View {
        ZStack {
            Rectangle()
                .fill(Palette.surfaceSunken)
                .ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                Spacer(minLength: 0)

                if let recorder {
                    if let stage = recorder.panel {
                        DSRecordingPanel(
                            stage: stage,
                            elapsed: recorder.elapsed,
                            levels: recorder.levels,
                            onRetry: { Task { await recorder.dismissFailure() } }
                        )
                        .padding(.horizontal, Metrics.screenGutter)
                        transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    DSRecordingButton(state: recorder.buttonState) {
                        Task { await recorder.toggle() }
                    }
                }

                caption
                Spacer(minLength: 0)
            }
            .frame(maxWidth: Metrics.readingMaxWidth)
            .animation(Motion.Spring.gentle, value: recorder?.panel)
        }
        .navigationTitle("NoteSmart")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            DSButton("Más", kind: .secondary) { path.append(.more) }
                .disabled(recorder?.isBusy ?? false)
        }
    }

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .more:
            MoreView(
                onRecordings: { path.append(.recordings) },
                onProfile: { path.append(.profile) },
                onSignOut: { environment.lock() }
            )
        case .recordings:
            RecordingsListView()
        case .profile:
            ProfileView()
        case .note(let noteID):
            NoteEditorView(noteID: noteID)
        }
    }

    private var caption: some View {
        Text(captionText)
            .font(Typography.subheadline)
            .foregroundStyle(Palette.textSecondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, Metrics.screenGutter)
    }

    private var captionText: String {
        guard let recorder else { return "" }
        return switch recorder.state {
        case .idle: "Toca para grabar. La nota se transcribe y se guarda sola."
        case .recording: "Grabando. Toca otra vez para parar."
        case .processing: "Trabajando…"
        case .failed: "No se pudo completar. Toca el botón para reintentar."
        }
    }
}

extension RecordHomeView {
    /// The navigation graph is one enum rather than several `Hashable` types, so a
    /// route can never be pushed onto the wrong stack and the compiler checks the
    /// whole flow at the `switch`.
    enum Route: Hashable {
        case more
        case recordings
        case profile
        case note(NoteID)
    }
}

#Preview {
    RecordHomeView()
        .environment(try! AppEnvironment.inMemory())
}
