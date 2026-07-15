//
//  HistoryConfirmScreen.swift
//  Stridewell
//
//  Baseline screen shown when Strava is connected. Shows the computed history and
//  confirms weekly volume, training phase, and injury status through chat. There are
//  no controls; corrections happen in the conversation.
//

import SwiftUI

struct HistoryConfirmScreen: View {

    @Environment(\.apiClient) private var apiClient
    @Environment(\.onboardingStore) private var onboardingStore
    @Environment(\.onboardingCoordinator) private var coordinator

    @State private var model: IntakeChatModel?

    init(previewModel: IntakeChatModel? = nil) {
        _model = State(initialValue: previewModel)
    }

    var body: some View {
        Group {
            if let model {
                GuidedScreenScaffold(
                    title: "You in Focus",
                    model: model,
                    image: "history_confirm"
                ) {
                    if let summary = onboardingStore.historySummary {
                        HistorySummaryCard(summary: summary)
                    }
                }
                .onChange(of: model.confirmedFields) { _, fields in
                    onboardingStore.applyConfirmedFields(fields)
                    if OnboardingFlow.isSatisfied(.historyConfirm, confirmed: fields) {
                        coordinator.advance(using: onboardingStore, planBuilding: model.planBuilding)
                    }
                }
                .onChange(of: model.planBuilding) { _, building in
                    if building { coordinator.advance(using: onboardingStore, planBuilding: true) }
                }
            } else {
                ProgressView().task { setupModel() }
            }
        }
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

#if DEBUG
#Preview {
    NavigationStack {
        HistoryConfirmScreen(
            previewModel: .preview(
                screenContext: "history_confirm",
                coachLine: "You've been averaging about 40 km a week with a solid base. Does that match how you're feeling?"
            )
        )
    }
    .environment(\.onboardingStore, OnboardingStore.preview(historySummary: .previewWithSeries))
    .environment(\.onboardingCoordinator, OnboardingCoordinator())
}
#endif
