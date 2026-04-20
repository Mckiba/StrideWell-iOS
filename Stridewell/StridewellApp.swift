//
//  StridewellApp.swift
//  Stridewell
//
//  Created by McKiba Williams on 2/20/26.
//

import SwiftUI

// MARK: - Environment Keys

extension EnvironmentValues {
    @Entry var authStore: AuthStore = AuthStore()
    @Entry var apiClient: APIClient = APIClient(tokenProvider: { nil }, onUnauthorized: {})
    @Entry var onboardingStore: OnboardingStore = OnboardingStore()
    @Entry var planStore: PlanStore = PlanStore()
    @Entry var chatStore: ChatStore = ChatStore()
    @Entry var settingsStore: SettingsStore = SettingsStore()
    @Entry var notificationStore: NotificationStore = NotificationStore()
    @Entry var locationStore: LocationStore = LocationStore()
    @Entry var heatmapViewModel: HeatmapViewModel? = nil
    @Entry var weatherStore: WeatherStore = WeatherStore()
    @Entry var activitiesStore: ActivitiesStore = ActivitiesStore()
    @Entry var activityStore: ActivityStore = ActivityStore()
}

// MARK: - Password Reset State

/// Carries the Supabase recovery token received via deep link.
/// Passed to ResetPasswordScreen so it can authenticate the update call.
struct PendingReset: Identifiable {
    let id = UUID()
    let accessToken: String
    let userId: String
}

// MARK: - App

@main
struct StridewellApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @State private var authStore: AuthStore
    @State private var onboardingStore = OnboardingStore()
    @State private var planStore = PlanStore()
    @State private var chatStore = ChatStore()
    @State private var settingsStore = SettingsStore()
    @State private var notificationStore = NotificationStore()
    @State private var locationStore = LocationStore()
    @State private var weatherStore = WeatherStore()
    @State private var activitiesStore = ActivitiesStore()
    @State private var activityStore = ActivityStore()
    @State private var pendingReset: PendingReset?
    private let apiClient: APIClient
    private let heatmapViewModel: HeatmapViewModel

    init() {
        let store = AuthStore()
        let client = APIClient(
            tokenProvider: { store.token },
            onUnauthorized: { store.handle401() }
        )
        _authStore = State(wrappedValue: store)
        apiClient = client
        heatmapViewModel = HeatmapViewModel(apiClient: client)
    }

    var body: some Scene {
        WindowGroup {
            RootView(authStore: authStore, onboardingStore: onboardingStore)
                .task {
                    // Validate the stored JWT and refresh onboarding status on every cold
                    // launch. A 401 triggers onUnauthorized → clears auth → RootView re-routes.
                    guard authStore.isAuthenticated else { return }
                    if case .success(let me) = await apiClient.me() {
                        if me.onboarding_status == .complete || me.onboarding_status == .skipped {
                            onboardingStore.markComplete()
                        }
                    }
                }
                .preferredColorScheme(settingsStore.appTheme.colorScheme)
                .environment(\.authStore, authStore)
                .environment(\.apiClient, apiClient)
                .environment(\.onboardingStore, onboardingStore)
                .environment(\.planStore, planStore)
                .environment(\.chatStore, chatStore)
                .environment(\.settingsStore, settingsStore)
                .environment(\.notificationStore, notificationStore)
                .environment(\.locationStore, locationStore)
                .environment(\.heatmapViewModel, heatmapViewModel)
                .environment(\.weatherStore, weatherStore)
                .environment(\.activitiesStore, activitiesStore)
                .environment(\.activityStore, activityStore)
                .onReceive(NotificationCenter.default.publisher(for: .apnsTokenReceived)) { notification in
                    guard let token = notification.object as? String,
                          authStore.isAuthenticated else { return }
                    Task { _ = await apiClient.registerDeviceToken(token) }
                }
                .onReceive(NotificationCenter.default.publisher(for: .foregroundPushReceived)) { notification in
                    guard let userInfo = notification.object as? [AnyHashable: Any],
                          let deepLink = userInfo["deep_link"] as? String else { return }
                    if deepLink == "home", let runId = userInfo["run_id"] as? String {
                        let summary = (userInfo["aps"] as? [String: Any])
                            .flatMap { $0["alert"] as? [String: Any] }
                            .flatMap { $0["body"] as? String } ?? ""
                        activityStore.setLastSyncedRun(runId: runId, summary: summary)
                    }
                    if deepLink == "plan_change", let pvId = userInfo["plan_version_id"] as? String {
                        planStore.setCurrentPlanVersionId(pvId)
                    }
                }
                .onOpenURL { url in
                    handleDeepLink(url)
                }
                .fullScreenCover(item: $pendingReset) { pending in
                    ResetPasswordScreen(recovery: pending)
                        .environment(\.authStore, authStore)
                        .environment(\.apiClient, apiClient)
                        .environment(\.onboardingStore, onboardingStore)
                }
        }
    }

    // MARK: - Deep Link Handler

    private func handleDeepLink(_ url: URL) {
        // Only handle stridewell://auth/... links
        guard url.scheme == Config.appScheme, url.host == "auth" else { return }

        // The recovery tokens come in the URL fragment: #access_token=...&type=recovery
        let fragment = url.fragment ?? ""
        var params: [String: String] = [:]
        for pair in fragment.split(separator: "&") {
            let kv = pair.split(separator: "=", maxSplits: 1)
            if kv.count == 2 {
                let key   = String(kv[0])
                let value = String(kv[1]).removingPercentEncoding ?? String(kv[1])
                params[key] = value
            }
        }

        guard params["type"] == "recovery", let accessToken = params["access_token"] else { return }

        // Decode the user ID from the JWT payload (middle base64 segment, "sub" claim)
        let userId = jwtSubject(from: accessToken) ?? ""
        pendingReset = PendingReset(accessToken: accessToken, userId: userId)
    }

    /// Extracts the `sub` claim from a JWT without verifying the signature.
    private func jwtSubject(from token: String) -> String? {
        let segments = token.split(separator: ".")
        guard segments.count >= 2 else { return nil }
        var base64 = String(segments[1])
        // Pad to a multiple of 4
        let remainder = base64.count % 4
        if remainder != 0 { base64 += String(repeating: "=", count: 4 - remainder) }
        guard let data = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let sub  = json["sub"] as? String else { return nil }
        return sub
    }
}
