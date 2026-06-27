//
//  HistoryConfirmScreen.swift
//  Stridewell
//
//  S2a — "You in Focus" (Strava branch). Shows the computed history summary and
//  confirms current_weekly_volume_km, training_phase, active_injury through chat.
//  No structured controls here — corrections flow through the conversation.
//

import SwiftUI

struct HistoryConfirmScreen: View {

    @Environment(\.apiClient) private var apiClient
    @Environment(\.onboardingStore) private var onboardingStore

    @State private var model: IntakeChatModel?
    @State private var navigateToBridge = false
    @State private var navigateToPlanBuilding = false

    var body: some View {
        Group {
            if let model {
                GuidedScreenScaffold(
                    title: "You in Focus",
                    subtitle: "Here's what your recent training looks like.",
                    model: model
                ) {
                    if let summary = onboardingStore.historySummary {
                        HistorySummaryCard(summary: summary)
                    }
                }
                .onChange(of: model.confirmedFields) { _, fields in
                    onboardingStore.applyConfirmedFields(fields)
                    if OnboardingFlow.isSatisfied(.historyConfirm, confirmed: fields) {
                        navigateToBridge = true
                    }
                }
                .onChange(of: model.planBuilding) { _, building in
                    if building { navigateToPlanBuilding = true }
                }
            } else {
                ProgressView().task { setupModel() }
            }
        }
        .navigationDestination(isPresented: $navigateToBridge) { IntakeInterviewScreen() }
        .navigationDestination(isPresented: $navigateToPlanBuilding) { PlanBuildingScreen() }
    }

    private func setupModel() {
        guard let conversationId = onboardingStore.conversationId else { return }
        model = IntakeChatModel(
            api: apiClient,
            conversationId: conversationId,
            screenContext: OnboardingFlow.screenContext(for: .historyConfirm)
        )
    }
}
