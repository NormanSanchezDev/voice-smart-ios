//
//  AppRootView.swift
//  NoteSmart
//

import DSMolecules
import SwiftUI

/// Owns the environment and the one-time bootstrap.
///
/// Built here rather than as a stored property on the `App` so a failure to open the
/// vault or the index is a screen the user can read, not a `fatalError` at launch.
struct AppRootView: View {

    /// The vault usually opens in a few milliseconds. Below this the branded splash
    /// would strobe for one frame and read as a glitch rather than as an opening, so
    /// the boot is held long enough to be seen and no longer.
    private static let minimumSplashDuration: Duration = .milliseconds(450)

    @State private var environment: AppEnvironment?
    @State private var failure: String?

    var body: some View {
        Group {
            if let environment {
                RootView()
                    .environment(environment)
            } else if let failure {
                DSEmptyState(
                    systemImage: "exclamationmark.triangle",
                    title: "No se pudo abrir el vault",
                    message: failure,
                    actionTitle: "Reintentar",
                    onAction: { Task { await bootstrap() } }
                )
            } else {
                SplashView(phase: .preparing)
            }
        }
        .task { await bootstrap() }
    }

    private func bootstrap() async {
        guard environment == nil, failure == nil else { return }

        let startedAt = ContinuousClock.now

        do {
            let environment = try AppEnvironment.live()
            self.environment = environment
            await environment.prepare()
        } catch {
            failure = AppErrorMessage.text(for: error)
        }

        // Measured from before the container is built, so a slow disk also gets a
        // splash long enough to read.
        let elapsed = ContinuousClock.now - startedAt
        if elapsed < Self.minimumSplashDuration {
            try? await Task.sleep(for: Self.minimumSplashDuration - elapsed)
        }
    }
}
