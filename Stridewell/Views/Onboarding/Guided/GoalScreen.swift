//
//  GoalScreen.swift
//  Stridewell
//
//  Captures the training goal. When the goal is a race, an optional distance-and-date
//  row is revealed.
//

import SwiftUI

struct GoalScreen: View {

    @Environment(\.apiClient) private var apiClient
    @Environment(\.onboardingStore) private var onboardingStore
    @Environment(\.onboardingCoordinator) private var coordinator

    @State private var model: IntakeChatModel?
    @State private var selectedGoal: String? = nil
    @State private var raceDistanceM: Double = 21097     // default Half
    @State private var raceDate = Date().addingTimeInterval(60 * 60 * 24 * 84) // ~12 weeks out
    @State private var raceHandled = false

    init(previewModel: IntakeChatModel? = nil) {
        _model = State(initialValue: previewModel)
    }

    private static let goals: [(label: String, value: String, phrase: String)] = [
        ("A race", "race", "to run a race"),
        ("General fitness", "fitness", "general fitness"),
        ("Build a base", "base_building", "to build a base"),
        ("Return to running", "return_to_running", "to return to running"),
    ]

    private static let distances: [(label: String, meters: Double)] = [
        ("5K", 5000), ("10K", 10000), ("Half", 21097), ("Marathon", 42195),
    ]

    var body: some View {
        Group {
            if let model {
                GuidedScreenScaffold(
                    title: "Your Goal. Our Goal",
                    model: model,
                    image: "goal"
                ) {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: Spacing.sm)],
                                  alignment: .leading, spacing: Spacing.sm) {
                            ForEach(Self.goals, id: \.value) { goal in
                                OnboardingChip(label: goal.label, isSelected: selectedGoal == goal.value) {
                                    selectGoal(goal.value, phrase: goal.phrase)
                                }
                            }
                        }
                        if selectedGoal == "race" { raceDetail }
                    }
                }
                .onChange(of: model.confirmedFields) { _, fields in
                    onboardingStore.applyConfirmedFields(fields)
                    advanceIfReady(fields)
                }
                .onChange(of: model.planBuilding) { _, building in
                    if building { coordinator.advance(using: onboardingStore, planBuilding: true) }
                }
            } else {
                ProgressView().task { setupModel() }
            }
        }
    }

    private var raceDetail: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Picker("Distance", selection: $raceDistanceM) {
                ForEach(Self.distances, id: \.meters) { Text($0.label).tag($0.meters) }
            }
            .pickerStyle(.segmented)

            DatePicker("Race date", selection: $raceDate, displayedComponents: .date)
                .font(.cardBody)

            HStack(spacing: Spacing.sm) {
                PrimaryButton("Set race", size: .small) { Task { await commitRace() } }
                Button("Skip details") { Task { await skipRaceDetails() } }
                    .font(.cardCaption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func setupModel() {
        guard let conversationId = onboardingStore.conversationId else { return }
        selectedGoal = onboardingStore.partialIntake?.goal_type
        if let d = onboardingStore.partialIntake?.goal_race_distance_m { raceDistanceM = d }
        model = IntakeChatModel(
            api: apiClient,
            conversationId: conversationId,
            screenContext: OnboardingFlow.screenContext(for: .goal)
        )
    }

    private func selectGoal(_ value: String, phrase: String) {
        selectedGoal = value
        // A race waits for the distance/date row and its "Set race" (or "Skip details")
        // before anything is sent, so we don't confirm goal_type until the athlete
        // finishes. Other goals send immediately.
        guard value != "race" else {
            raceHandled = false
            return
        }
        raceHandled = true
        Task {
            await model?.send("My goal is \(phrase).", structured: StructuredFields(goal_type: value))
        }
    }

    /// Send goal_type plus the chosen race distance and date in one turn.
    private func commitRace() async {
        let label = Self.distances.first { $0.meters == raceDistanceM }?.label ?? "race"
        let dateString = DateUtils.isoDate.string(from: raceDate)
        raceHandled = true
        await model?.send(
            "My goal is a \(label) on \(dateString).",
            structured: StructuredFields(
                goal_type: "race",
                goal_race_date: dateString,
                goal_race_distance_m: raceDistanceM
            )
        )
    }

    /// Confirm the race goal without the distance/date so the flow can advance.
    private func skipRaceDetails() async {
        raceHandled = true
        await model?.send("My goal is to run a race.", structured: StructuredFields(goal_type: "race"))
    }

    /// Advance once goal_type is confirmed — but for a race, wait until race details
    /// are handled (set or explicitly skipped) so the detail row isn't bypassed.
    private func advanceIfReady(_ fields: [String]) {
        guard OnboardingFlow.isSatisfied(.goal, confirmed: fields) else { return }
        guard raceHandled || selectedGoal != "race" else { return }
        coordinator.advance(using: onboardingStore, planBuilding: model?.planBuilding ?? false)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        GoalScreen(previewModel: .preview(
            screenContext: "goal",
            coachLine: "What are we training for?"
        ))
    }
    .environment(\.onboardingStore, OnboardingStore.preview())
    .environment(\.onboardingCoordinator, OnboardingCoordinator())
}
#endif
