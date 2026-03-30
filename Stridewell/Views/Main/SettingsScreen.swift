//
//  SettingsScreen.swift
//  Stridewell
//

import SwiftUI

struct SettingsScreen: View {

    @Environment(\.apiClient) private var apiClient
    @Environment(\.authStore) private var authStore
    @Environment(\.onboardingStore) private var onboardingStore
    @Environment(\.planStore) private var planStore
    @Environment(\.chatStore) private var chatStore
    @Environment(\.settingsStore) private var settingsStore
    @Environment(\.activityStore) private var activityStore

    @State private var showDisconnectAlert = false
    @State private var showDeleteStep1 = false
    @State private var showDeleteStep2 = false

    var body: some View {
        ZStack {
            HeatmapBackgroundView(userId: authStore.userId ?? "")

            ScrollView {
                VStack(spacing: Spacing.lg) {
                    connectedAccountsSection
                    trainingPreferencesSection
                    accountSection
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.md)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .task { await settingsStore.loadStravaStatus(apiClient: apiClient) }
        .alert("Disconnect Strava?", isPresented: $showDisconnectAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Disconnect", role: .destructive) {
                Task { await settingsStore.disconnectStrava(apiClient: apiClient) }
            }
        } message: {
            Text("Your run data will remain, but new activities won't sync.")
        }
        .alert("Delete Account?", isPresented: $showDeleteStep1) {
            Button("Cancel", role: .cancel) {}
            Button("Delete My Account", role: .destructive) { showDeleteStep2 = true }
        } message: {
            Text("This will permanently delete your account, training plan, all run data, and conversation history.")
        }
        .alert("This cannot be undone", isPresented: $showDeleteStep2) {
            Button("Cancel", role: .cancel) {}
            Button("Permanently Delete", role: .destructive) {
                Task {
                    let success = await settingsStore.executeDeleteAccount(apiClient: apiClient)
                    if success {
                        settingsStore.signOut(
                            authStore: authStore,
                            onboardingStore: onboardingStore,
                            planStore: planStore,
                            chatStore: chatStore,
                            activityStore: activityStore
                        )
                    }
                }
            }
        } message: {
            Text("All data will be permanently removed from our servers.")
        }
    }

    // MARK: - Sections

    private var connectedAccountsSection: some View {
        SettingsConnectedAccountsSection(
            stravaState: settingsStore.stravaState,
            onConnect: { Task { await connectStrava() } },
            onReconnect: { Task { await connectStrava() } },
            onDisconnect: { showDisconnectAlert = true },
            onRetry: { Task { await settingsStore.loadStravaStatus(apiClient: apiClient) } }
        )
    }

    private var trainingPreferencesSection: some View {
        SettingsTrainingPreferencesSection(
            unitSystem: Binding(
                get: { settingsStore.unitSystem },
                set: { settingsStore.unitSystem = $0 }
            ),
            reflectionReminders: Binding(
                get: { settingsStore.reflectionReminders },
                set: { settingsStore.reflectionReminders = $0 }
            ),
            planUpdateAlerts: Binding(
                get: { settingsStore.planUpdateAlerts },
                set: { settingsStore.planUpdateAlerts = $0 }
            ),
            appTheme: Binding(
                get: { settingsStore.appTheme },
                set: { settingsStore.appTheme = $0 }
            )
        )
    }

    private var accountSection: some View {
        SettingsAccountSection(
            isSigningOut: false,
            deleteState: settingsStore.deleteState,
            onSignOut: {
                settingsStore.signOut(
                    authStore: authStore,
                    onboardingStore: onboardingStore,
                    planStore: planStore,
                    chatStore: chatStore,
                    activityStore: activityStore
                )
            },
            onDeleteAccount: { showDeleteStep1 = true }
        )
    }

    // MARK: - OAuth

    private func connectStrava() async {
        settingsStore.setConnecting()
        guard let code = await StravaOAuthHelper.authenticate() else {
            await settingsStore.loadStravaStatus(apiClient: apiClient)
            return
        }
        await settingsStore.exchangeStravaCode(code, apiClient: apiClient)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SettingsScreen()
    }
}
