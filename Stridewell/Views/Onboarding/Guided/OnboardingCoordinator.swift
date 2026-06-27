//
//  OnboardingCoordinator.swift
//  Stridewell
//
//  Owns the onboarding navigation stack. The connect screen is the root; the
//  remaining screens are pushed onto `path`. The next screen is whichever one still
//  has unconfirmed fields, so screens already answered are skipped.
//

import Foundation
import Observation

@Observable
final class OnboardingCoordinator {

    var path: [OnboardingScreen] = []

    /// Move to the next screen that still needs input, or to plan building once intake
    /// is finished. The baseline screen is recomputed from the store on each call.
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
