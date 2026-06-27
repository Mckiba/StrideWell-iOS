//
//  OnboardingContainerView.swift
//  Stridewell
//
//  Hosts the guided-flow navigation stack. S1 (StravaConnectScreen) is the root;
//  the coordinator pushes S2-S8 onto the path as `confirmed_fields` advance.
//

import SwiftUI

struct OnboardingContainerView: View {

    @State private var coordinator = OnboardingCoordinator()

    var body: some View {
        @Bindable var coordinator = coordinator
        NavigationStack(path: $coordinator.path) {
            StravaConnectScreen()
                .navigationDestination(for: OnboardingScreen.self) { screen in
                    destination(for: screen)
                }
        }
        .environment(\.onboardingCoordinator, coordinator)
    }

    @ViewBuilder
    private func destination(for screen: OnboardingScreen) -> some View {
        switch screen {
        case .integrations:   StravaConnectScreen()
        case .historyConfirm: HistoryConfirmScreen()
        case .manualBaseline: ManualBaselineScreen()
        case .goal:           GoalScreen()
        case .routines:       RoutinesScreen()
        case .speedwork:      SpeedworkScreen()
        case .lessons:        LessonsScreen()
        case .planBuilding:   PlanBuildingScreen()
        case .planReveal:     PlanRevealScreen()
        }
    }
}
