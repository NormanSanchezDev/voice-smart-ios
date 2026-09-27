//
//  SplashView.swift
//  NoteSmart
//

import DSAtoms
import DSMolecules
import DSTokens
import SwiftUI

/// The branded boot screen.
///
/// The app always opens here: it covers the window between launch and the vault
/// being ready, and it comes back whenever the vault is locked. Both states live in
/// one view so "opening the app" and "re-entering the vault" are the same gesture
/// rather than two screens that drift apart.
struct SplashView: View {

    enum Phase: Equatable {
        /// The vault is still being created, opened and indexed.
        case preparing
        /// The vault is closed until the user asks for it again.
        case locked
    }

    let phase: Phase
    var onUnlock: () -> Void = {}

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Palette.surfaceSunken)
                .ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                Spacer()

                mark
                wordmark

                Spacer()

                footer
                    .padding(.bottom, Spacing.xxl)
            }
            .frame(maxWidth: Metrics.readingMaxWidth)
            .padding(.horizontal, Metrics.screenGutter)
        }
    }

    // MARK: - Pieces

    private var mark: some View {
        ZStack {
            Circle()
                .fill(Palette.surfaceElevated)
            Circle()
                .strokeBorder(Palette.border, lineWidth: Metrics.hairline)
            Image(systemName: "waveform")
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(Palette.accent)
                .symbolEffect(.variableColor.iterative, options: .repeating, isActive: phase == .preparing)
        }
        .frame(width: 88, height: 88)
        .accessibilityHidden(true)
    }

    private var wordmark: some View {
        VStack(spacing: Spacing.s) {
            Text("NoteSmart")
                .font(Typography.title)
                .foregroundStyle(Palette.textPrimary)

            Text(subtitle)
                .font(Typography.subheadline)
                .foregroundStyle(Palette.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    /// Branches return different types on purpose, so the match is built up in a
    /// `Group` rather than forcing one view type onto the loading and the button.
    @ViewBuilder
    private var footer: some View {
        switch phase {
        case .preparing:
            ProgressView()
                .controlSize(.regular)
                .accessibilityLabel(Text("Abriendo el vault"))
        case .locked:
            DSButton("Abrir vault", kind: .primary, fullWidth: true, action: onUnlock)
        }
    }

    private var subtitle: String {
        switch phase {
        case .preparing: "Abriendo tu vault local"
        case .locked: "Vault cerrado"
        }
    }
}

#Preview("Preparando") {
    SplashView(phase: .preparing)
}

#Preview("Cerrado") {
    SplashView(phase: .locked, onUnlock: {})
}
