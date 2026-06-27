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
    .environment(\.onboardingStore, OnboardingStore.preview(
        historySummary: StravaHistorySummary(
            avg_weekly_volume_km_4wk: 40,
            avg_weekly_volume_km_12wk: 36,
            peak_weekly_volume_km_12wk: 52,
            recent_long_run_m: 18000,
            avg_runs_per_week_4wk: 4,
            consistency_rate_12wk: 0.8,
            has_speed_work: true,
            inferred_training_phase: "base",
            volume_trend: "stable"
        )
    ))
    .environment(\.onboardingCoordinator, OnboardingCoordinator())
}
#endif
