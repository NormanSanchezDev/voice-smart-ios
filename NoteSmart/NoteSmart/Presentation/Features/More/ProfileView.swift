//
//  ProfileView.swift
//  NoteSmart
//

import DSAtoms
import DSMolecules
import DSTemplates
import DSTokens
import NoteSmartDomain
import SwiftUI

/// Local profile: what the app knows, where it keeps it, and how to get rid of it.
///
/// There is no account to edit, by design — see
/// `documentation/decisions/0005-local-first-sin-autenticacion.md`. This screen is
/// the honest replacement for the sign-in that never had to exist, and the only place
/// that says out loud that nothing leaves the device.
struct ProfileView: View {

    @Environment(AppEnvironment.self) private var environment
    @State private var usage: VaultUsage?
    @State private var isConfirmingDelete = false

    var body: some View {
        DSListScaffold(title: "Perfil") {
            VStack(spacing: Spacing.l) {
                DSSectionHeader("App")
                DSCard {
                    VStack(alignment: .leading, spacing: Spacing.m) {
                        field("Versión", value: Self.versionDescription)
                        field("Sistema", value: ProcessInfo.processInfo.operatingSystemVersionString)
                    }
                }

                DSSectionHeader("Almacenamiento")
                DSCard {
                    VStack(alignment: .leading, spacing: Spacing.m) {
                        field("Notas", value: usage.map { "\($0.noteCount)" } ?? "—")
                        field("Audio", value: usage.map { ByteCountFormatter.string(fromByteCount: $0.audioBytes, countStyle: .file) } ?? "—")
                        field("En", value: vaultDescription)
                    }
                }

                DSSectionHeader("Privacidad")
                DSCard {
                    Text("La transcripción y el resumen se generan en este dispositivo. Ninguna grabación ni nota se sube a un servidor, porque no hay servidor. Desinstalar la app elimina el vault.")
                        .font(Typography.subheadline)
                        .foregroundStyle(Palette.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                DSButton(
                    "Eliminar todos los datos",
                    kind: .destructive,
                    fullWidth: true
                ) {
                    isConfirmingDelete = true
                }
            }
            .padding(.horizontal, Metrics.screenGutter)
            .padding(.top, Spacing.m)
            .padding(.bottom, Spacing.xxxl)
        }
        .navigationTitle("Perfil")
        .navigationBarTitleDisplayMode(.inline)
        .task { usage = await loadUsage() }
        .confirmationDialog(
            "¿Eliminar todos los datos?",
            isPresented: $isConfirmingDelete,
            titleVisibility: .visible
        ) {
            Button("Eliminar todo", role: .destructive) {
                Task { await eraseEverything() }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Se borran las notas y los audios de este dispositivo. No hay copia en ningún otro sitio.")
        }
    }

    // MARK: - Pieces

    private func field(_ label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(Typography.subheadline)
                .foregroundStyle(Palette.textSecondary)
            Spacer(minLength: Spacing.m)
            Text(value)
                .font(Typography.subheadline)
                .foregroundStyle(Palette.textPrimary)
                .multilineTextAlignment(.trailing)
        }
    }

    private var vaultDescription: String {
        environment.vault.recordingsURL.deletingLastPathComponent().lastPathComponent
    }

    /// Read from the bundle so there is no UIKit dependency for something SwiftUI
    /// does not surface on its own.
    private static var versionDescription: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "0"
        let build = info?["CFBundleVersion"] as? String ?? "0"
        return "\(short) (\(build))"
    }

    // MARK: - Data

    private struct VaultUsage: Equatable {
        let noteCount: Int
        let audioBytes: Int64
    }

    private func loadUsage() async -> VaultUsage? {
        let notes = try? await environment.repository.allNotes()
        let recordings = try? FileManager.default.contentsOfDirectory(
            at: environment.vault.recordingsURL,
            includingPropertiesForKeys: [.fileSizeKey]
        )
        let bytes = (recordings ?? []).reduce(Int64(0)) { total, url in
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            return total + Int64(size)
        }
        return VaultUsage(noteCount: notes?.count ?? 0, audioBytes: bytes)
    }

    private func eraseEverything() async {
        let notes = (try? await environment.repository.allNotes()) ?? []
        for note in notes {
            try? await environment.repository.delete(id: note.id)
        }

        let recordings = (try? FileManager.default.contentsOfDirectory(
            at: environment.vault.recordingsURL,
            includingPropertiesForKeys: nil
        )) ?? []
        for url in recordings {
            try? FileManager.default.removeItem(at: url)
        }

        usage = await loadUsage()
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
    .environment(try! AppEnvironment.inMemory())
}
