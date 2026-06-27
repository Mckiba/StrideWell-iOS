//
//  PlanBuildingScreen.swift
//  Stridewell
//

import SwiftUI

struct PlanBuildingScreen: View {

    @Environment(\.onboardingStore) private var onboardingStore
    @Environment(\.onboardingCoordinator) private var coordinator
    @Environment(\.authStore) private var authStore
    @Environment(\.apiClient) private var apiClient

    @State private var errorMessage: String? = nil
    @State private var retryTrigger = false

    var body: some View {
        PlanBuildingContent(
            errorMessage: errorMessage,
            onRetry: { retryTrigger.toggle() }
        )
        .navigationTitle("Building your plan")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Sign out") {
                    onboardingStore.reset()
                    authStore.signOut()
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
        }
        .task(id: retryTrigger) { await poll() }
    }

    // MARK: - Polling

    private func poll() async {
        errorMessage = nil
        var delay: Duration = .seconds(3)
        var consecutiveFailures = 0

        // Check immediately on first iteration, then sleep before subsequent checks.
        while !Task.isCancelled {
            let result: ApiResult<OnboardingState> = await apiClient.onboardingStatus()
            switch result {
            case .success(let state):
                consecutiveFailures = 0
                onboardingStore.update(from: state)
                if state.first_plan_version_id != nil {
                    coordinator.goToPlanReveal()
                    return
                }
            case .failure(_, let message):
                consecutiveFailures += 1
                if consecutiveFailures >= 3 {
                    errorMessage = message
                    return
                }
            }

            try? await Task.sleep(for: delay)
            delay = min(delay + .seconds(3), .seconds(15))
        }
    }
}
