//
//  MainContainerView.swift
//  Stridewell
//
//  TabView with Home | Plan | Chat | Settings.
//  Each tab wraps its content in a NavigationStack for scoped push navigation.
//  Selection binding enables deep link routing from push notifications.
//

import SwiftUI

struct MainContainerView: View {

    @Environment(\.notificationStore) private var notificationStore
    @Environment(\.weatherStore) private var weatherStore

    @State private var selectedTab: MainTab = .home

    // MARK: - Tab

    enum MainTab: Hashable {
        case home, plan, chat, activities, settings
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                    Tab("Home", systemImage: "house", value: MainTab.home) {
                        NavigationStack {
                            HomeScreen()
                        }
                    }

                    Tab("Plan", systemImage: "calendar", value: MainTab.plan) {
                        NavigationStack {
                            PlanScreen()
                        }
                    }

                    Tab("Chat", systemImage: "bubble.left.and.bubble.right", value: MainTab.chat) {
                        NavigationStack {
                            ChatScreen()
                        }
                    }

                    Tab("Activities", systemImage: "figure.run", value: MainTab.activities) {
                        NavigationStack {
                            ActivitiesScreen()
                        }
                    }

                    Tab("Settings", systemImage: "gearshape", value: MainTab.settings) {
                        NavigationStack {
                            SettingsScreen()
                        }
                    }
                }
                .task {
                    // Request APNs permission on first entry to the main app (post-onboarding).
                    // Safe to call every launch — re-registration is idempotent on the backend.
                    await notificationStore.requestPermission()
                }
                .onReceive(NotificationCenter.default.publisher(for: .deepLinkReceived)) { notification in
                    guard let raw = notification.object as? String,
                          let deepLink = NotificationStore.DeepLink(rawValue: raw) else { return }
                    notificationStore.pendingDeepLink = deepLink
                }
                .onChange(of: notificationStore.pendingDeepLink) { _, deepLink in
                    guard let deepLink else { return }
                    switch deepLink {
                    case .planChange, .planReveal: selectedTab = .plan
                    case .home:                    selectedTab = .home
                    }
                    notificationStore.clearDeepLink()
                }
                .onReceive(NotificationCenter.default.publisher(for: .switchToActivities)) { _ in
                    selectedTab = .activities
                }

            // Residue strip: settles rain/snow particles over the tab bar area.
            // Only active when weather is rain or snow — zero overhead when clear.
            if weatherStore.activeCondition != .clear {
                ResidueView(
                    type: weatherStore.activeCondition == .rain ? .rain : .snow,
                    strength: weatherStore.activeCondition == .rain ? 250 : 150
                )
                .frame(maxWidth: .infinity)
                .frame(height: 120)
                .ignoresSafeArea(.container, edges: .bottom)
                .allowsHitTesting(false)
            }
        }
    }
}
