//
//  StravaConnectScreen.swift
//  Stridewell
//
//  S1 of the guided flow ("You, In Context"). The first step — where the athlete
//  connects their data. Three affordances (Onboarding V2 spec §2.1):
//    • Connect              → Strava OAuth → analyze → baseline branch (S2a/S2b)
//    • Continue without Strava → no OAuth → manual baseline branch (S2b)
//    • Skip onboarding      → POST /onboarding/skip → default plan
//

import SwiftUI

struct StravaConnectScreen: View {

    @Environment(\.onboardingStore) private var onboardingStore
    @Environment(\.authStore) private var authStore
    @Environment(\.apiClient) private var apiClient

    @State private var screenState: StravaConnectContent.ScreenState = .starting
    @State private var navigateToInterview = false
    @State private var showSkipConfirm = false
    @State private var isSkipping = false

    /// Poll attempts before offering the "continue without waiting" escape hatch.
    /// With 3s→15s backoff this lands a little past ~60s (spec §8.8).
    private let slowBackfillThreshold = 6

    var body: some View {
        StravaConnectContent(
            screenState: screenState,
            onConnect: { Task { await startOAuth() } },
            onContinueWithoutStrava: { advanceToInterview() },
            onSkipOnboarding: { showSkipConfirm = true },
            onContinue: { advanceToInterview() },
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
            baselineScreen
        }
        .confirmationDialog(
            "Skip onboarding?",
            isPresented: $showSkipConfirm,
            titleVisibility: .visible
        ) {
            Button("Skip and use a default plan", role: .destructive) {
                Task { await skipOnboarding() }
            }
            Button("Keep setting up", role: .cancel) {}
        } message: {
            Text("You'll get a generic starter plan instead of one tailored to you. You can refine it later in Settings.")
        }
        .task { await startOnboardingSession() }
    }

    // MARK: - Navigation

    /// Advance into the intake interview. The baseline branch (S2a vs S2b) is
    /// recomputed from `strava_connected` + `history_summary` — not stored here.
    private func advanceToInterview() {
        navigateToInterview = true
    }

    /// S2a (Strava history confirm) or S2b (manual baseline), per the resolved branch.
    @ViewBuilder
    private var baselineScreen: some View {
        switch OnboardingFlow.baselineBranch(
            stravaConnected: onboardingStore.stravaConnected,
            historySummary: onboardingStore.historySummary
        ) {
        case .historyConfirm:
            HistoryConfirmScreen()
        default:
            ManualBaselineScreen()
        }
    }

    // MARK: - Session lifecycle

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
            // Slow backfill: stop blocking the athlete; offer to continue (→ manual branch).
            if attempts > slowBackfillThreshold {
                self.screenState = .slowBackfill
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

    // MARK: - Skip

    private func skipOnboarding() async {
        guard !isSkipping else { return }
        isSkipping = true
        let result = await apiClient.skipOnboarding()
        isSkipping = false
        switch result {
        case .success:
            // `skipped` is terminal in the current model → RootView routes to main.
            onboardingStore.markSkipped()
        case .failure(_, let message):
            screenState = .sessionError(message)
        }
    }

    private func signOut() {
        onboardingStore.reset()
        authStore.signOut()
    }
}
