//
//  PlanBuildingScreen.swift
//  Stridewell
//

import SwiftUI

struct PlanBuildingScreen: View {

    @Environment(\.onboardingStore) private var onboardingStore
    @Environment(\.apiClient) private var apiClient

    @State private var errorMessage: String? = nil
    @State private var retryTrigger = false
    @State private var navigateToPlanReveal = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 72))
                .foregroundStyle(.tint)
                .symbolEffect(.variableColor.iterative, isActive: errorMessage == nil)

            VStack(spacing: 8) {
                Text("Building your plan")
                    .font(.title2.bold())
                Text("Your coach is putting together a training plan built around your goals. This usually takes a few seconds.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let errorMessage {
                VStack(spacing: 12) {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                    Button("Try again") { retryTrigger.toggle() }
                        .buttonStyle(.bordered)
                        .controlSize(.regular)
                }
                .transition(.opacity)
            } else {
                ProgressView()
                    .transition(.opacity)
            }

            Spacer()
        }
        .padding(.horizontal, 32)
        .animation(.easeInOut(duration: 0.2), value: errorMessage)
        .navigationTitle("Building your plan")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $navigateToPlanReveal) {
            PlanRevealScreen()
        }
        .task(id: retryTrigger) { await poll() }
    }

    // MARK: - Polling

    private func poll() async {
        errorMessage = nil
        var delay: UInt64 = 3_000_000_000    // 3 s
        let maxDelay: UInt64 = 15_000_000_000 // 15 s cap
        var consecutiveFailures = 0
        var isFirstCheck = true

        while !Task.isCancelled {
            // First check is immediate so fast builds and resumes feel instant
            if !isFirstCheck {
                try? await Task.sleep(nanoseconds: delay)
                guard !Task.isCancelled else { return }
                delay = min(delay + 3_000_000_000, maxDelay)
            }
            isFirstCheck = false

            let result: ApiResult<OnboardingState> = await apiClient.onboardingStatus()
            switch result {
            case .success(let state):
                consecutiveFailures = 0
                onboardingStore.update(from: state)
                if state.first_plan_version_id != nil {
                    navigateToPlanReveal = true
                    return
                }
            case .failure(_, let message):
                consecutiveFailures += 1
                if consecutiveFailures >= 3 {
                    errorMessage = message
                    return  // exit loop — user must tap "Try again"
                }
            }
        }
    }
}
