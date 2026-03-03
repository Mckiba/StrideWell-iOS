//
//  OnboardingContainerView.swift
//  Stridewell
//
//  M3: Replace body with GoalScreen
//

import SwiftUI

struct OnboardingContainerView: View {
    var body: some View {
        Text("Onboarding — Milestone 3")
            .foregroundStyle(.secondary)
            .navigationTitle("")
            .toolbar(.hidden, for: .navigationBar)
    }
}
