//
//  StravaConnectScreen.swift
//  Stridewell
//

import SwiftUI
import AuthenticationServices

struct StravaConnectScreen: View {

    @Environment(\.onboardingStore) private var onboardingStore
    @Environment(\.apiClient) private var apiClient

    @State private var screenState: ScreenState = .starting
    @State private var navigateToInterview = false
    @State private var webAuthSession: ASWebAuthenticationSession?
    @State private var authContext = StravaAuthContext()

    enum ScreenState: Equatable {
        case starting           // POST /onboarding/start in flight
        case idle               // session ready, Strava not connected
        case connecting         // OAuth browser open
        case connected          // Strava linked, ready to continue
        case analyzing          // polling GET /onboarding/status until 'interview'
        case sessionError(String) // POST /onboarding/start failed — retry session setup
        case error(String)      // Strava OAuth/connect failed — retry connect or skip
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Icon + copy
            VStack(spacing: 20) {
                Image(systemName: "figure.run.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.tint)

                VStack(spacing: 8) {
                    Text("Connect Strava")
                        .font(.title2.bold())
                    Text(
                        "Connecting gives your coach a head start — it already knows your recent mileage, pace, and training load before the interview opens. You can skip this and answer those questions manually."
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 32)

            Spacer()

            // Status feedback
            statusRow
                .frame(height: 44)
                .padding(.bottom, 4)

            // Actions
            VStack(spacing: 12) {
                switch screenState {
                case .starting, .connecting, .analyzing:
                    EmptyView()
                case .connected:
                    Button("Continue") { navigateToInterview = true }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .frame(maxWidth: .infinity)
                case .sessionError:
                    Button("Try again") {
                        Task {
                            screenState = .starting
                            await startOnboardingSession()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
                case .idle, .error:
                    Button("Connect Strava") { startOAuth() }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .frame(maxWidth: .infinity)
                    Button("Skip for now") { navigateToInterview = true }
                        .buttonStyle(.borderless)
                        .controlSize(.large)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
        .navigationTitle("Set up your plan")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $navigateToInterview) {
            // M4: IntakeInterviewScreen
            Text("Milestone 4 — Intake Interview")
                .foregroundStyle(.secondary)
        }
        .task { await startOnboardingSession() }
    }

    // MARK: - Status Row

    @ViewBuilder
    private var statusRow: some View {
        switch screenState {
        case .starting:
            ProgressView("Setting up your session…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        case .connecting:
            ProgressView("Opening Strava…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        case .analyzing:
            HStack(spacing: 8) {
                ProgressView()
                Text("Analyzing your run history…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        case .connected:
            Label("Strava connected", systemImage: "checkmark.circle.fill")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.green)
        case .sessionError(let message):
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
        case .error(let message):
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
        case .idle:
            EmptyView()
        }
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
            // Session already exists — fetch current state and resume
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
                break  // RootView will re-route
            }
        case .failure(_, let message):
            screenState = .sessionError(message)
        }
    }

    // MARK: - OAuth

    private func startOAuth() {
        guard let authURL = Config.stravaAuthURL else {
            screenState = .error("Invalid Strava configuration")
            return
        }
        screenState = .connecting
        let session = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: Config.appScheme
        ) { callbackURL, error in
            Task { @MainActor in
                guard let callbackURL, error == nil else {
                    screenState = .idle
                    return
                }
                guard let code = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
                    .queryItems?.first(where: { $0.name == "code" })?.value else {
                    screenState = .error("OAuth callback missing code")
                    return
                }
                await exchangeStravaCode(code)
            }
        }
        session.presentationContextProvider = authContext
        session.prefersEphemeralWebBrowserSession = false
        session.start()
        webAuthSession = session
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
        var delay: UInt64 = 3_000_000_000   // start at 3 s
        let maxDelay: UInt64 = 15_000_000_000 // cap at 15 s
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: delay)
            let result: ApiResult<OnboardingState> = await apiClient.onboardingStatus()
            if case .success(let state) = result {
                onboardingStore.update(from: state)
                if state.status == .interview {
                    navigateToInterview = true
                    return
                }
            }
            delay = min(delay + 3_000_000_000, maxDelay)
        }
    }
}

// MARK: - OAuth Presentation Context

private final class StravaAuthContext: NSObject, ASWebAuthenticationPresentationContextProviding,
    @unchecked Sendable {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow) ?? ASPresentationAnchor()
    }
}
