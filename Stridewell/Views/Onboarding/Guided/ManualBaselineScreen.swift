//
//  ManualBaselineScreen.swift
//  Stridewell
//
//  Baseline screen shown when Strava isn't connected. Captures weekly volume, training
//  phase, and injury status via a slider, phase chips, and chat, then moves on once all
//  three are confirmed.
//

import SwiftUI

struct ManualBaselineScreen: View {

    @Environment(\.apiClient) private var apiClient
    @Environment(\.onboardingStore) private var onboardingStore
    @Environment(\.onboardingCoordinator) private var coordinator

    @State private var model: IntakeChatModel?
    @State private var volumeDisplay: Double = 30
    @State private var selectedPhase: String?

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
