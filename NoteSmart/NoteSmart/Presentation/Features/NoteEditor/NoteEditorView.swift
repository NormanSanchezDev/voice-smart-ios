//
//  NoteEditorView.swift
//  NoteSmart
//

import DSAtoms
import DSMolecules
import DSTemplates
import DSTokens
import NoteSmartDomain
import SwiftUI

/// Creates the editor for a note. Split from `NoteEditorScreen` because the screen
/// needs a non-optional `@Bindable` model to drive the drafts, and the model cannot
/// exist until the environment does.
struct NoteEditorView: View {

    let noteID: NoteID

    @Environment(AppEnvironment.self) private var environment
    @Environment(\.dismiss) private var dismiss
    @State private var model: NoteEditorViewModel?

    var body: some View {
        Group {
            if let model {
                NoteEditorScreen(model: model)
            } else {
                ProgressView()
                    .controlSize(.large)
            }
        }
        .task(id: environment.state) {
            guard case .ready = environment.state, model == nil else { return }

            let model = NoteEditorViewModel(noteID: noteID, environment: environment)
            model.onDeleted = { dismiss() }
            self.model = model
            await model.load()
        }
    }
}

/// One note, read or edited.
struct NoteEditorScreen: View {

    @Bindable var model: NoteEditorViewModel
    @State private var isConfirmingDelete = false
    @State private var newTag = ""
    /// Only for the few APIs that demand a `Color` instead of a `ShapeStyle`.
    @Environment(\.self) private var environment

    var body: some View {
        ScrollView {
            DSReadingColumn {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    header
                    if model.player.isLoaded || model.player.isUnavailable { audioSection }
                    switch model.mode {
                    case .reading: readingBody
                    case .editing: editingBody
                    }
                }
                .padding(.horizontal, Metrics.screenGutter)
                .padding(.vertical, Spacing.m)
            }
        }
        .background {
            Rectangle()
                .fill(Palette.surfaceSunken)
                .ignoresSafeArea()
        }
        .navigationTitle(model.mode == .editing ? "Editando" : (model.note?.title ?? "Nota"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
        .confirmationDialog(
            "Eliminar esta nota?",
            isPresented: $isConfirmingDelete,
            titleVisibility: .visible
        ) {
            // System dialogs draw their own chrome and pick up role styling, so these
            // are the one place a raw `Button` is the right call.
            Button("Eliminar nota", role: .destructive) {
                Task { await model.delete() }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("El archivo markdown se borra del vault. El audio se queda en Vault/Recordings.")
        }
        .alert(
            "No se pudo guardar",
            isPresented: Binding(
                get: { model.errorMessage != nil },
                set: { if !$0 { model.dismissError() } }
            )
        ) {
            Button("Entendido", role: .cancel) {}
        } message: {
            Text(model.errorMessage ?? "")
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            if model.mode == .editing {
                TextField("Título", text: $model.draftTitle)
                    .font(Typography.title)
                    .foregroundStyle(Palette.textPrimary)
                    .textInputAutocapitalization(.sentences)
            } else {
                Text(model.note?.title ?? "")
                    .font(Typography.title)
                    .foregroundStyle(Palette.textPrimary)
            }

            if let note = model.note {
                HStack(spacing: Spacing.s) {
                    folderMenu(note)
                    Text(note.frontmatter.modified, format: .dateTime.day().month(.abbreviated).hour().minute())
                        .font(Typography.caption)
                        .foregroundStyle(Palette.textTertiary)
                }
            }

            if let note = model.note, !note.tags.isEmpty || model.mode == .editing {
                tagsRow(note)
            }
        }
    }

    private func folderMenu(_ note: Note) -> some View {
        Menu {
            ForEach(model.folders, id: \.description) { folder in
                Button {
                    Task { await model.move(to: folder) }
                } label: {
                    if folder == note.folder {
                        Label(folder.description, systemImage: "checkmark")
                    } else {
                        Text(folder.description)
                    }
                }
            }
        } label: {
            DSChip(note.folder.isRoot ? "Vault" : note.folder.name, systemImage: "folder")
        }
        .accessibilityLabel("Carpeta: \(note.folder)")
    }

    private func tagsRow(_ note: Note) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            DSTagRow(tags: note.tags.map(\.displayText)) { tag in
                guard let value = VaultTag(tag) else { return }
                Task { await model.removeTag(value) }
            }

            if model.mode == .editing {
                HStack(spacing: Spacing.s) {
                    DSTextField("Añadir tag", systemImage: "number", text: $newTag) {
                        let typed = newTag
                        newTag = ""
                        Task { await model.addTag(typed) }
                    }
                    DSButton("Añadir", kind: .secondary, isEnabled: VaultTag(newTag) != nil) {
                        let typed = newTag
                        newTag = ""
                        Task { await model.addTag(typed) }
                    }
                }
            }
        }
    }

    // MARK: - Audio

    @ViewBuilder
    private var audioSection: some View {
        if model.player.isUnavailable {
            DSCard {
                Label("El archivo de audio no está en el vault.", systemImage: "waveform.slash")
                    .font(Typography.subheadline)
                    .foregroundStyle(Palette.textSecondary)
            }
        } else {
            DSCard {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    HStack(spacing: Spacing.m) {
                        DSIconButton(
                            systemImage: model.player.isPlaying ? "pause.fill" : "play.fill",
                            accessibilityLabel: model.player.isPlaying ? "Pausar" : "Reproducir"
                        ) {
                            model.player.toggle()
                        }

                        Text(Self.timestamp(model.player.currentTime))
                            .font(Typography.timer)
                            .foregroundStyle(Palette.textSecondary)

                        Slider(
                            value: Binding(
                                get: { model.player.progress },
                                set: { model.player.seek(toFraction: $0) }
                            )
                        )
                        .tint(Palette.accent)

                        Text(Self.timestamp(model.player.duration))
                            .font(Typography.timer)
                            .foregroundStyle(Palette.textTertiary)
                    }
                }
            }
        }
    }

    // MARK: - Reading

    @ViewBuilder
    private var readingBody: some View {
        if let note = model.note {
            if !model.prose.isEmpty {
                Text(Self.markdown(model.prose))
                    .font(Typography.body)
                    .foregroundStyle(Palette.textPrimary)
                    .textSelection(.enabled)
            }

            if !model.tasks.isEmpty {
                DSSectionHeader("Action items")
                taskList
            }

            if model.hasTranscript {
                DSSectionHeader("Transcripción")
                transcriptList(note.transcript)
            }
        }
    }

    private var taskList: some View {
        DSCard {
            VStack(alignment: .leading, spacing: Spacing.s) {
                ForEach(model.tasks, id: \.index) { task in
                    Button {
                        Task { await model.toggleTask(task) }
                    } label: {
                        HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
                            Image(systemName: task.isChecked ? "checkmark.square.fill" : "square")
                                .foregroundStyle(task.isChecked ? Palette.success : Palette.textTertiary)
                                .accessibilityHidden(true)
                            Text(task.text)
                                .font(Typography.body)
                                .foregroundStyle(Palette.textPrimary)
                                .strikethrough(task.isChecked, color: Palette.textTertiary.resolved(in: environment))
                                .multilineTextAlignment(.leading)
                            Spacer(minLength: 0)
                        }
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(task.isChecked ? [.isButton, .isSelected] : .isButton)
                }
            }
        }
    }

    private func transcriptList(_ segments: [TranscriptSegment]) -> some View {
        DSCard {
            VStack(alignment: .leading, spacing: Spacing.s) {
                ForEach(segments) { segment in
                    Button {
                        model.player.seek(to: segment.range.start)
                    } label: {
                        HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
                            Text(segment.range.timestampText())
                                .font(Typography.timer)
                                .foregroundStyle(Palette.textTertiary)
                            Text(segment.text)
                                .font(Typography.subheadline)
                                .foregroundStyle(
                                    segment.id == model.activeSegmentID
                                        ? Palette.textPrimary
                                        : Palette.textSecondary
                                )
                                .multilineTextAlignment(.leading)
                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, Spacing.xs)
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(segment.range.timestampText()), \(segment.text)")
                }
            }
        }
    }

    // MARK: - Editing

    private var editingBody: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            DSSectionHeader("Markdown")
            TextEditor(text: $model.draftBody)
                .font(Typography.body.monospaced())
                .foregroundStyle(Palette.textPrimary)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 320)
                .padding(Spacing.s)
                .background {
                    RoundedRectangle(cornerRadius: Radius.m, style: .continuous)
                        .fill(Palette.surface)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: Radius.m, style: .continuous)
                        .strokeBorder(Palette.border, lineWidth: Metrics.hairline)
                }

            Text("El transcript se guarda aparte, así que reescribir la prosa no rompe el audio.")
                .font(Typography.caption)
                .foregroundStyle(Palette.textTertiary)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            switch model.mode {
            case .reading:
                DSIconButton(systemImage: "square.and.pencil", accessibilityLabel: "Editar nota") {
                    model.beginEditing()
                }
            case .editing:
                DSButton("Guardar", kind: .primary, isEnabled: model.canSave) {
                    Task { await model.save() }
                }
            }
        }

        ToolbarItem(placement: .topBarLeading) {
            if model.mode == .editing {
                DSButton("Cancelar", kind: .secondary) {
                    model.cancelEditing()
                }
            } else {
                DSIconButton(systemImage: "trash", accessibilityLabel: "Eliminar nota") {
                    isConfirmingDelete = true
                }
            }
        }
    }

    // MARK: - Formatting

    private static func markdown(_ source: String) -> AttributedString {
        (try? AttributedString(
            markdown: source,
            options: .init(interpretedSyntax: .full)
        )) ?? AttributedString(source)
    }

    private static func timestamp(_ time: TimeInterval) -> String {
        let total = Int(max(0, time).rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
