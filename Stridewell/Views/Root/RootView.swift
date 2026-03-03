//
//  RootView.swift
//  Stridewell
//

import SwiftUI

/// Top-level navigation gate.
///
/// Reads `authStore.authCheckComplete` before routing so there is never
/// a flash of the wrong stack during the Keychain read on launch.
/// The check is synchronous in practice (< 1ms) but the flag exists
/// to guard against any future async auth-check path.
struct RootView: View {

    var authStore: AuthStore

    var body: some View {
        Group {
            if !authStore.authCheckComplete {
                SkeletonLoadingView()
            } else if authStore.isAuthenticated {
                MainContainerView()
            } else {
                AuthContainerView()
            }
        }
        .animation(.easeInOut(duration: 0.2), value: authStore.authCheckComplete)
        .animation(.easeInOut(duration: 0.2), value: authStore.isAuthenticated)
    }
}

// MARK: - Skeleton

private struct SkeletonLoadingView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            ProgressView()
        }
    }
}
