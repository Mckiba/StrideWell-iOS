//
//  SpeedworkScreen.swift
//  Stridewell
//
//  Captures whether the athlete has done structured speed work, plus an optional
//  "already following a plan" toggle. The coordinator skips this screen when that
//  answer was already given earlier.
//

import SwiftUI

struct SpeedworkScreen: View {

    @Environment(\.apiClient) private var apiClient
    @Environment(\.onboardingStore) private var onboardingStore
    @Environment(\.onboardingCoordinator) private var coordinator

    @State private var model: IntakeChatModel?
    @State private var selection: Bool? = nil
    @State private var followingPlan = false

    init(previewModel: IntakeChatModel? = nil) {
        _model = State(initialValue: previewModel)
    }

    var body: some View {
        Group {
            if let model {
                GuidedScreenScaffold(
                    title: "The Work",
                    subtitle: "Have you done structured speed work before?",
                    model: model
                ) {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack(spacing: Spacing.sm) {
                            OnboardingChip(label: "I've done speed work", isSelected: selection == true) {
                                select(true)
                            }
                            OnboardingChip(label: "I haven't", isSelected: selection == false) {
                                select(false)
                            }
                        }

                        Toggle(isOn: $followingPlan) {
                            Text("I'm currently following another plan")
                                .font(.cardCaption)
                        }
                        .onChange(of: followingPlan) { _, on in
                            if on { Task { await commitFollowingPlan() } }
                        }
                    }
                }
                .onChange(of: model.confirmedFields) { _, fields in
                    onboardingStore.applyConfirmedFields(fields)
                    if OnboardingFlow.isSatisfied(.speedwork, confirmed: fields) {
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
        selection = onboardingStore.partialIntake?.has_done_speedwork
        followingPlan = onboardingStore.partialIntake?.following_existing_plan ?? false
        model = IntakeChatModel(
            api: apiClient,
            conversationId: conversationId,
            screenContext: OnboardingFlow.screenContext(for: .speedwork)
        )
    }

    private func select(_ value: Bool) {
        selection = value
        let text = value
            ? "I've done structured speed workouts before."
            : "I haven't done structured speed workouts."
        Task { await model?.send(text, structured: StructuredFields(has_done_speedwork: value)) }
    }

    private func commitFollowingPlan() async {
        await model?.send(
            "I'm currently following another training plan.",
            structured: StructuredFields(following_existing_plan: true)
        )
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        SpeedworkScreen(previewModel: .preview(
            screenContext: "speedwork",
            coachLine: "Have you done structured speed work before?"
        ))
    }
    .environment(\.onboardingStore, OnboardingStore.preview())
    .environment(\.onboardingCoordinator, OnboardingCoordinator())
}
#endif
