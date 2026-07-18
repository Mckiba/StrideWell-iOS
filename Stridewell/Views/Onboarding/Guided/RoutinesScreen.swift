//
//  RoutinesScreen.swift
//  Stridewell
//
//  Captures how many days a week the athlete can run, which days, and the preferred
//  long-run day, via a day selector.
//

import SwiftUI

struct RoutinesScreen: View {

    @Environment(\.apiClient) private var apiClient
    @Environment(\.onboardingStore) private var onboardingStore
    @Environment(\.onboardingCoordinator) private var coordinator

    @State private var model: IntakeChatModel?
    @State private var selectedDays: Set<String> = []
    @State private var longRunDay: String? = nil

    init(previewModel: IntakeChatModel? = nil) {
        _model = State(initialValue: previewModel)
    }

    private static let days: [(short: String, value: String)] = [
        ("Mon", "monday"), ("Tue", "tuesday"), ("Wed", "wednesday"),
        ("Thu", "thursday"), ("Fri", "friday"), ("Sat", "saturday"), ("Sun", "sunday"),
    ]

    var body: some View {
        Group {
            if let model {
                GuidedScreenScaffold(
                    title: "Routines",
                    model: model,
                    image: "routines"
                ) {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.xs), count: 7),
                                  spacing: Spacing.xs) {
                            ForEach(Self.days, id: \.value) { day in
                                OnboardingChip(label: day.short, isSelected: selectedDays.contains(day.value)) {
                                    toggleDay(day.value)
                                }
                            }
                        }

                        if !selectedDays.isEmpty {
                            HStack {
                                Text("Long run").font(.cardCaption).foregroundStyle(.secondary)
                                Spacer()
                                Picker("Long run", selection: $longRunDay) {
                                    Text("None").tag(String?.none)
                                    ForEach(orderedSelectedDays, id: \.self) { value in
                                        Text(shortLabel(value)).tag(String?.some(value))
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                            PrimaryButton("Set schedule", size: .small) { Task { await commit() } }
                        }
                    }
                }
                .onChange(of: model.confirmedFields) { _, fields in
                    onboardingStore.applyConfirmedFields(fields)
                    if OnboardingFlow.isSatisfied(.routines, confirmed: fields) {
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

    private var orderedSelectedDays: [String] {
        Self.days.map(\.value).filter { selectedDays.contains($0) }
    }

    private func shortLabel(_ value: String) -> String {
        Self.days.first { $0.value == value }?.short ?? value.capitalized
    }

    private func toggleDay(_ value: String) {
        if selectedDays.contains(value) {
            selectedDays.remove(value)
            if longRunDay == value { longRunDay = nil }
        } else {
            selectedDays.insert(value)
        }
    }

    private func setupModel() {
        guard let conversationId = onboardingStore.conversationId else { return }
        if let names = onboardingStore.partialIntake?.available_day_names { selectedDays = Set(names) }
        longRunDay = onboardingStore.partialIntake?.preferred_long_run_day
        model = IntakeChatModel(
            api: apiClient,
            conversationId: conversationId,
            screenContext: OnboardingFlow.screenContext(for: .routines)
        )
    }

    private func commit() async {
        let days = orderedSelectedDays
        guard !days.isEmpty else { return }
        let dayList = days.map { shortLabel($0) }.joined(separator: ", ")
        var text = "I can run \(days.count) day\(days.count == 1 ? "" : "s") a week — \(dayList)"
        if let longRunDay { text += ", with my long run on \(shortLabel(longRunDay))" }
        text += "."

        await model?.send(text, structured: StructuredFields(
            available_days_per_week: days.count,
            available_day_names: days,
            preferred_long_run_day: longRunDay
        ))
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        RoutinesScreen(previewModel: .preview(
            screenContext: "routines",
            coachLine: "Which days can you run, and when's your long run?"
        ))
    }
    .environment(\.onboardingStore, OnboardingStore.preview())
    .environment(\.onboardingCoordinator, OnboardingCoordinator())
}
#endif
