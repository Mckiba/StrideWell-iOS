//
//  MainContainerView.swift
//  Stridewell
//
//  TabView with Home | Plan | Chat | Activities | Settings, plus a Search tab
//  that holds the full searchable activity list.
//  Each tab wraps its content in a NavigationStack for scoped push navigation.
//  Selection binding enables deep link routing from push notifications.
//

import SwiftUI

struct MainContainerView: View {

    @Environment(\.notificationStore) private var notificationStore
    @Environment(\.weatherStore) private var weatherStore

    @State private var selectedTab: MainTab = .home
    private let stormTabs: Set<MainTab> = [.home, .activities, .settings, .search]

    // MARK: - Tab

    enum MainTab: Hashable {
        case home, plan, chat, activities, settings, search
    }

    /// Tab label that renders the symbol exactly as named. TabView otherwise
    /// swaps in the .fill variant (house -> house.fill).
    private func tabLabel(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .environment(\.symbolVariants, .none)
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                    Tab(value: MainTab.home) {
                        NavigationStack {
                            HomeScreen()
                        }
                    } label: {
                        tabLabel("Home", systemImage: "house")
                    }

                    Tab(value: MainTab.plan) {
                        NavigationStack {
                            PlanScreen()
                        }
                    } label: {
                        tabLabel("Plan", systemImage: "calendar")
                    }

                    Tab(value: MainTab.chat) {
                        NavigationStack {
                            ChatScreen()
                        }
                    } label: {
                        tabLabel("Chat", systemImage: "message.badge.waveform")
                    }

                    Tab(value: MainTab.activities) {
                        NavigationStack {
                            ActivitiesScreen()
                        }
                    } label: {
                        tabLabel("Activities", systemImage: "figure.run")
                    }

                    Tab(value: MainTab.settings) {
                        NavigationStack {
                            SettingsScreen()
                        }
                    } label: {
                        tabLabel("Settings", systemImage: "gearshape")
                    }

                    Tab(value: MainTab.search, role: .search) {
                        NavigationStack {
                            AllActivitiesScreen()
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
                    case .planChange:
                        selectedTab = .plan
                        NotificationCenter.default.post(name: .openPlanChange, object: nil)
                    case .planReveal:
                        selectedTab = .plan
                        NotificationCenter.default.post(name: .openPlanReveal, object: nil)
                    case .home:
                        selectedTab = .home
                    case .chat:
                        selectedTab = .chat
                    case .reflection:
                        selectedTab = .home
                        NotificationCenter.default.post(name: .openReflection, object: nil)
                    }
                    notificationStore.clearDeepLink()
                }
                .onReceive(NotificationCenter.default.publisher(for: .switchToActivities)) { _ in
                    selectedTab = .activities
                }
                .onReceive(NotificationCenter.default.publisher(for: .switchToChat)) { _ in
                    selectedTab = .chat
                }

            // Residue strip: settles rain/snow particles over the tab bar area.
            // Only active when weather is rain or snow — zero overhead when clear.
            if weatherStore.activeCondition != .clear && stormTabs.contains(selectedTab) {
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

