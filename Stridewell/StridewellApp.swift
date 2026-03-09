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
    private let apiClient: APIClient

    init() {
        let store = AuthStore()
        let client = APIClient(
            tokenProvider: { store.token },
            onUnauthorized: { store.handle401() }
        )
        _authStore = State(wrappedValue: store)
        apiClient = client
    }

    var body: some Scene {
        WindowGroup {
            RootView(authStore: authStore, onboardingStore: onboardingStore)
                .environment(\.authStore, authStore)
                .environment(\.apiClient, apiClient)
                .environment(\.onboardingStore, onboardingStore)
                .environment(\.planStore, planStore)
                .environment(\.chatStore, chatStore)
                .environment(\.settingsStore, settingsStore)
                .environment(\.notificationStore, notificationStore)
                .onReceive(NotificationCenter.default.publisher(for: .apnsTokenReceived)) { notification in
                    guard let token = notification.object as? String,
                          authStore.isAuthenticated else { return }
                    Task { _ = await apiClient.registerDeviceToken(token) }
                }
        }
    }
}
