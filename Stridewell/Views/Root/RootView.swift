//
//  RootView.swift
//  Stridewell
//

import SwiftUI

/// Top-level navigation gate.
///
/// Routing priority:
/// 1. Keychain read incomplete → skeleton
/// 2. Not authenticated → Auth stack
/// 3. Authenticated + onboarding incomplete → Onboarding stack
/// 4. Authenticated + onboarding complete → Main tab bar
struct RootView: View {

    var authStore: AuthStore
    var onboardingStore: OnboardingStore

    var body: some View {
        Group {
            if !authStore.authCheckComplete {
                SkeletonLoadingView()
            } else if !authStore.isAuthenticated {
                AuthContainerView()
            } else if !onboardingStore.isComplete {
                OnboardingContainerView()
            } else {
                MainContainerView()
            }
        }
        .animation(.easeInOut(duration: 0.2), value: authStore.authCheckComplete)
        .animation(.easeInOut(duration: 0.2), value: authStore.isAuthenticated)
        .animation(.easeInOut(duration: 0.2), value: onboardingStore.isComplete)
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
