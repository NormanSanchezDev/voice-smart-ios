//
//  MoreView.swift
//  NoteSmart
//

import DSAtoms
import DSMolecules
import DSTemplates
import DSTokens
import SwiftUI

/// The overflow menu reached from the record screen.
///
/// Everything that is not the record button lives behind here, so the capture screen
/// can stay a single control with nothing to read.
struct MoreView: View {

    let onRecordings: () -> Void
    let onProfile: () -> Void
    let onSignOut: () -> Void

    @State private var isConfirmingSignOut = false

    var body: some View {
        DSListScaffold(title: "Más") {
            VStack(spacing: Spacing.l) {
                DSSectionHeader("Tu contenido")
                DSCard {
                    VStack(spacing: Spacing.xxs) {
                        row(
                            systemImage: "waveform",
                            title: "Grabaciones previas",
                            subtitle: "Tus notas y audios guardados",
                            action: onRecordings
                        )
                        Divider()
                        row(
                            systemImage: "person.crop.circle",
                            title: "Perfil",
                            subtitle: "Privacidad y datos locales",
                            action: onProfile
                        )
                    }
                }

                DSSectionHeader("Sesión")
                DSCard {
                    VStack(spacing: Spacing.xxs) {
                        row(
                            systemImage: "lock",
                            title: "Cerrar sesión",
                            subtitle: "Bloquea el vault en este dispositivo",
                            role: .destructive,
                            action: { isConfirmingSignOut = true }
                        )
                    }
                }

                Text("NoteSmart no tiene cuentas ni servidores. Las notas y el audio viven solo en este dispositivo.")
                    .font(Typography.footnote)
                    .foregroundStyle(Palette.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, Metrics.screenGutter)
            .padding(.top, Spacing.m)
            .padding(.bottom, Spacing.xxxl)
        }
        .navigationTitle("Más")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "¿Cerrar sesión?",
            isPresented: $isConfirmingSignOut,
            titleVisibility: .visible
        ) {
            Button("Cerrar sesión", role: .destructive, action: onSignOut)
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("El vault se bloquea y tendrás que abrirlo de nuevo en este dispositivo.")
        }
    }

    // MARK: - Pieces

    private func row(
        systemImage: String,
        title: String,
        subtitle: String,
        role: ButtonRole? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(role: role, action: action) {
            HStack(spacing: Spacing.m) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(role == .destructive ? Palette.danger : Palette.accent)
                    .frame(width: 28)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(title)
                        .font(Typography.headline)
                        .foregroundStyle(Palette.textPrimary)
                    Text(subtitle)
                        .font(Typography.footnote)
                        .foregroundStyle(Palette.textSecondary)
                }

                Spacer(minLength: Spacing.s)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Palette.textTertiary)
                    .accessibilityHidden(true)
            }
            .frame(minHeight: Metrics.minimumTapTarget)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}
