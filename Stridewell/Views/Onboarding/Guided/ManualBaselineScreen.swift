//
//  ManualBaselineScreen.swift
//  Stridewell
//
//  S2b — "Your Starting Point" (no-Strava branch). Captures current_weekly_volume_km,
//  training_phase, active_injury via a volume slider, phase chips, and chat. Advances
//  when the three baseline fields are confirmed.
//

import SwiftUI

struct ManualBaselineScreen: View {

    @Environment(\.apiClient) private var apiClient
    @Environment(\.onboardingStore) private var onboardingStore

    @State private var model: IntakeChatModel?
    @State private var volumeDisplay: Double = 30
    @State private var selectedPhase: String?
    @State private var navigateToBridge = false
    @State private var navigateToPlanBuilding = false

    var body: some View {
        Group {
            if let model {
                GuidedScreenScaffold(
                    title: "Your Starting Point",
                    subtitle: "Tell me where your running is right now.",
                    model: model
                ) {
                    VStack(spacing: Spacing.md) {
                        VolumeSlider(displayValue: $volumeDisplay) {
                            Task { await commitVolume() }
                        }
                        PhaseChips(selected: selectedPhase) { value, label in
                            selectedPhase = value
                            Task { await commitPhase(value: value, label: label) }
                        }
                    }
                }
                .onChange(of: model.confirmedFields) { _, fields in
                    onboardingStore.applyConfirmedFields(fields)
                    if OnboardingFlow.isSatisfied(.manualBaseline, confirmed: fields) {
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
        // V2-6: the remaining topics (goal → lessons) are still collected by the V1
        // free-form interview bridge; V2-7 replaces it with S3-S6.
        .navigationDestination(isPresented: $navigateToBridge) { IntakeInterviewScreen() }
        .navigationDestination(isPresented: $navigateToPlanBuilding) { PlanBuildingScreen() }
    }

    private func setupModel() {
        guard let conversationId = onboardingStore.conversationId else { return }
        if let km = onboardingStore.partialIntake?.current_weekly_volume_km {
            volumeDisplay = OnboardingUnits.displayValue(fromKm: km).rounded()
        }
        selectedPhase = onboardingStore.partialIntake?.training_phase
        model = IntakeChatModel(
            api: apiClient,
            conversationId: conversationId,
            screenContext: OnboardingFlow.screenContext(for: .manualBaseline)
        )
    }

    private func commitVolume() async {
        let km = OnboardingUnits.km(fromDisplay: volumeDisplay)
        let text = volumeDisplay < 1
            ? "I'm not currently running."
            : "I'm running about \(Int(volumeDisplay)) \(OnboardingUnits.unitLabel) per week right now."
        await model?.send(text, structured: StructuredFields(current_weekly_volume_km: km))
    }

    private func commitPhase(value: String, label: String) async {
        await model?.send(
            "I'd say I'm in a \(label.lowercased()) phase.",
            structured: StructuredFields(training_phase: value)
        )
    }
}
