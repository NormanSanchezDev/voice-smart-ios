//
//  RootView.swift
//  NoteSmart
//

import SwiftUI

/// Routes on the state of the graph, not on navigation: the vault has to exist before
/// there is anything to navigate to.
struct RootView: View {

    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        switch environment.state {
        case .preparing:
            SplashView(phase: .preparing)
        case .ready:
            // Locked keeps the same splash the app opened with, so returning to the
            // app and re-entering the vault are one gesture.
            if environment.isLocked {
                SplashView(phase: .locked) { environment.unlock() }
            } else {
                RecordHomeView()
            }
        case .failed:
            // `prepare` already reported the message on the launch screen; the app
            // cannot do anything useful without a vault, so there is nothing to
            // route to.
            EmptyView()
        }
    }
}
