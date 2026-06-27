//
//  LessonsScreen.swift
//  Stridewell
//
//  S6 — "The Lessons". Captures what_hasnt_worked (free text — no chips would flatten
//  it). When intake completes the backend returns plan_building → advance to S7.
//

import SwiftUI

struct LessonsScreen: View {

    @Environment(\.apiClient) private var apiClient
    @Environment(\.onboardingStore) private var onboardingStore
    @Environment(\.onboardingCoordinator) private var coordinator

    @State private var model: IntakeChatModel?

    var body: some View {
        Group {
            if let model {
                GuidedScreenScaffold(
                    title: "The Lessons",
                    subtitle: "What hasn't worked for you before?",
                    model: model
                ) {
                    Button {
                        Task { await model.send("Nothing really comes to mind.") }
                    } label: {
                        Text("Nothing comes to mind")
                            .font(.cardCaption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .onChange(of: model.confirmedFields) { _, fields in
                    onboardingStore.applyConfirmedFields(fields)
                    if OnboardingFlow.isSatisfied(.lessons, confirmed: fields) {
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
            screenContext: OnboardingFlow.screenContext(for: .lessons)
        )
    }
}
