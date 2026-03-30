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
        }
    }
}
