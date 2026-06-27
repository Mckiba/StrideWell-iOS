//
//  OnboardingCoordinator.swift
//  Stridewell
//
//  Drives the guided-flow navigation stack. Advancement is computed from
//  `confirmed_fields` via OnboardingFlow's skip-ahead loop — screens whose fields
//  were volunteered early are skipped (spec §4.3). S1 is the stack root; S2-S8 are
//  pushed onto `path`.
//

import Foundation
import Observation

@Observable
final class OnboardingCoordinator {

    var path: [OnboardingScreen] = []

    /// Push the first unsatisfied intake screen, or plan-building once intake is done.
    /// Recomputes the baseline branch from the store each time — never stored.
    func advance(using store: OnboardingStore, planBuilding: Bool) {
        if planBuilding {
            push(.planBuilding)
            return
        }
        let branch = OnboardingFlow.baselineBranch(
            stravaConnected: store.stravaConnected,
            historySummary: store.historySummary
        )
        if let next = OnboardingFlow.firstUnsatisfied(branch: branch, confirmed: store.confirmedFields) {
            push(next)
        } else {
            push(.planBuilding)
        }
    }

    func goToPlanReveal() {
        push(.planReveal)
    }

    func reset() {
        path = []
    }

    private func push(_ screen: OnboardingScreen) {
        guard path.last != screen else { return }
        path.append(screen)
    }
}
