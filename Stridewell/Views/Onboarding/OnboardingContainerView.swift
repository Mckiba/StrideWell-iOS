//
//  OnboardingContainerView.swift
//  Stridewell
//
//  Hosts the onboarding navigation stack. The unit-preference step is the root;
//  it pushes the connect screen, and the coordinator pushes the rest of the
//  screens as fields get confirmed.
//

import SwiftUI

struct OnboardingContainerView: View {

    @State private var coordinator = OnboardingCoordinator()

    var body: some View {
        @Bindable var coordinator = coordinator
        NavigationStack(path: $coordinator.path) {
            UnitPreferenceScreen()
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
