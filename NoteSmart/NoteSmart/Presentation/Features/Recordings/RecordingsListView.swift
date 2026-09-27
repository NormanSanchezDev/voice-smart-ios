//
//  RecordingsListView.swift
//  NoteSmart
//

import DSAtoms
import DSMolecules
import DSTemplates
import DSTokens
import NoteSmartDomain
import SwiftUI

/// Previous recordings, in reading order. Reached from "Más", not from the record
/// button, so the capture screen can stay a single control.
///
/// Navigation is keyed on `NoteID` rather than a file path: renames and folder moves
/// change the path but never the identity, so an open note survives being retitled
/// underneath it.
struct RecordingsListView: View {

    @Environment(AppEnvironment.self) private var environment
    @State private var model: RecordingsListViewModel?
    @State private var path: [NoteID] = []

    var body: some View {
        DSListScaffold(
            title: "Grabaciones previas",
            isEmpty: cards.isEmpty,
            emptyState: emptyState
        ) {
            list
        }
        .navigationTitle("Grabaciones previas")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: NoteID.self) { noteID in
            NoteEditorView(noteID: noteID)
        }
        .task(id: environment.state) {
            guard case .ready = environment.state else { return }
            if model == nil { model = RecordingsListViewModel(environment: environment) }
            await model?.load()
        }
    }

    // MARK: - Content

    private var cards: [NoteCardModel] {
        model?.cards ?? []
    }

    private var list: some View {
        ScrollView {
            DSReadingColumn {
                VStack(spacing: Spacing.m) {
                    if let errorMessage = model?.errorMessage {
                        errorBanner(errorMessage)
                    }

                    ForEach(cards) { card in
                        card
                            .card { path.append(card.id) }
                            .contextMenu {
                                // Menus draw their own chrome and style by role.
                                Button("Eliminar nota", systemImage: "trash", role: .destructive) {
                                    Task { await delete(card) }
                                }
                            }
                    }
                }
                .padding(.horizontal, Metrics.screenGutter)
                .padding(.top, Spacing.m)
                .padding(.bottom, Spacing.xxxl)
            }
        }
        .refreshable { await model?.load() }
    }

    /// The empty state belongs here, not on the record screen: this is the only place
    /// that is about the vault's contents, and it is the only place that can say what
    /// an empty vault means.
    private var emptyState: DSEmptyState {
        DSEmptyState(
            systemImage: "waveform",
            title: "Vault vacío",
            message: "Vuelve a la pantalla de grabación y habla. La nota se transcribe y se guarda sola como markdown."
        )
    }

    private func errorBanner(_ message: String) -> some View {
        DSCard {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Palette.danger)
                    .accessibilityHidden(true)
                Text(message)
                    .font(Typography.subheadline)
                    .foregroundStyle(Palette.textSecondary)
                Spacer(minLength: 0)
            }
        }
    }

    // MARK: - Actions

    private func delete(_ card: NoteCardModel) async {
        guard let note = model?.note(for: card.id) else { return }
        await model?.delete(note)
    }
}
