//
//  StravaConnectScreen.swift
//  Stridewell
//

import SwiftUI

struct StravaConnectScreen: View {

    @Environment(\.onboardingStore) private var onboardingStore
    @Environment(\.authStore) private var authStore
    @Environment(\.apiClient) private var apiClient

    @State private var screenState: StravaConnectContent.ScreenState = .starting
    @State private var navigateToInterview = false

    var body: some View {
        StravaConnectContent(
            screenState: screenState,
            onConnect: { Task { await startOAuth() } },
            onSkip: { navigateToInterview = true },
            onContinue: { navigateToInterview = true },
            onRetrySession: {
                Task {
                    screenState = .starting
                    await startOnboardingSession()
                }
            },
            onSignOut: { signOut() }
        )
        .navigationTitle("Set up your plan")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $navigateToInterview) {
            IntakeInterviewScreen()
        }
        .task { await startOnboardingSession() }
    }

    // MARK: - API Calls

    private func startOnboardingSession() async {
        let result: ApiResult<OnboardingStartResponse> = await apiClient.startOnboarding()
        switch result {
        case .success(let response):
            onboardingStore.onStarted(
                conversationId: response.conversation_id,
                status: response.status,
                stravaConnected: response.strava_connected
            )
            screenState = response.strava_connected ? .connected : .idle
        case .failure(let status, _) where status == 409:
            await resumeExistingSession()
        case .failure(_, let message):
            screenState = .sessionError(message)
        }
    }

    private func resumeExistingSession() async {
        let result: ApiResult<OnboardingState> = await apiClient.onboardingStatus()
        switch result {
        case .success(let state):
            onboardingStore.update(from: state)
            switch state.status {
            case .interview:
                navigateToInterview = true
            case .analyzing:
                screenState = .analyzing
                await pollUntilInterview()
            case .pending:
                screenState = .idle
            case .complete, .skipped:
                break
            }
        case .failure(_, let message):
            screenState = .sessionError(message)
        }
    }

    // MARK: - OAuth

    private func startOAuth() async {
        screenState = .connecting
        guard let code = await StravaOAuthHelper.authenticate() else {
            screenState = .idle
            return
        }
        await exchangeStravaCode(code)
    }

    private func exchangeStravaCode(_ code: String) async {
        let result: ApiResult<StravaConnectResponse> = await apiClient.stravaConnect(code: code)
        switch result {
        case .success:
            onboardingStore.stravaDidConnect()
            screenState = .analyzing
            await pollUntilInterview()
        case .failure(_, let message):
            screenState = .error(message)
        }
    }

    private func pollUntilInterview() async {
        var attempts = 0
        await Polling.exponentialBackoff {
            attempts += 1
            if attempts > 10 {
                self.screenState = .sessionError("Analysis is taking longer than expected. Tap 'Try again' to retry.")
                return true
            }
            let result: ApiResult<OnboardingState> = await self.apiClient.onboardingStatus()
            if case .success(let state) = result {
                self.onboardingStore.update(from: state)
                if state.status == .interview {
                    self.navigateToInterview = true
                    return true
                }
            }
            return false
        }
    }

    private func signOut() {
        onboardingStore.reset()
        authStore.signOut()
    }
}


