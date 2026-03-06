//
//  PlanChangeScreen.swift
//  Stridewell
//
//  M11: Renders a DecisionRecord to explain what changed in the
//  athlete's plan and why. Pushed from PlanChangeBanner tap.
//

import SwiftUI

struct PlanChangeScreen: View {

    @Environment(\.apiClient) private var apiClient
    @Environment(\.planStore) private var planStore
    @Environment(\.dismiss) private var dismiss

    @State private var screenState: ScreenState = .loading

    enum ScreenState {
        case loading
        case loaded(DecisionRecord)
        case empty
        case error(String)
    }

    var body: some View {
        ZStack {
            MapBackground()

            switch screenState {
            case .loading:
                LoadingStateView(message: "Loading changes...")

            case .empty:
                EmptyStateView(
                    title: "No changes to show",
                    subtitle: "Your plan hasn't been modified yet."
                )

            case .error(let message):
                ErrorStateView(message: message) {
                    Task { await loadDecision() }
                }

            case .loaded(let record):
                decisionContent(record)
            }
        }
        .navigationTitle("Plan Update")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadDecision() }
    }

    // MARK: - Decision Content

    private func decisionContent(_ record: DecisionRecord) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {

                // Header + timestamp
                headerSection(record)

                // Trigger badge
                triggerSection(record.trigger)

                // What changed
                if !record.diff_summary.isEmpty {
                    diffSection(record.diff_summary)
                }

                // Why it changed
                if !record.rationale_bullets.isEmpty {
                    rationaleSection(record.rationale_bullets)
                }

                // Signals used
                if let signals = record.signals_used,
                   (signals.fatigue_trend != nil || signals.injury_risk_level != nil) {
                    signalsSection(signals)
                }

                // Dismiss button
                gotItButton
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.md)
        }
    }

    // MARK: - Header

    private func headerSection(_ record: DecisionRecord) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Your plan was updated")
                    .font(.sectionTitle)
                Text(Self.formatTimestamp(record.created_at))
                    .font(.cardCaption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Trigger Badge

    private func triggerSection(_ trigger: DecisionTrigger) -> some View {
        CardView {
            HStack(spacing: Spacing.sm) {
                Image(systemName: triggerIcon(trigger))
                    .foregroundStyle(Color.accentColor)
                Text(triggerLabel(trigger))
                    .font(.cardTitle)
            }
        }
    }

    // MARK: - Diff Summary

    private func diffSection(_ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("What changed")
                .font(.sectionTitle)

            CardView {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                        HStack(alignment: .top, spacing: Spacing.sm) {
                            Text("•")
                                .foregroundStyle(.secondary)
                            Text(item)
                                .font(.cardBody)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Rationale

    private func rationaleSection(_ bullets: [String]) -> some View {
        CardView {
            DisclosureGroup("Here's why") {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    ForEach(Array(bullets.enumerated()), id: \.offset) { _, bullet in
                        HStack(alignment: .top, spacing: Spacing.sm) {
                            Text("•")
                                .foregroundStyle(.secondary)
                            Text(bullet)
                                .font(.cardBody)
                        }
                    }
                }
                .padding(.top, Spacing.sm)
            }
            .font(.cardTitle)
        }
    }

    // MARK: - Signals

    private func signalsSection(_ signals: SignalsUsed) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Signals")
                    .font(.cardCaption)
                    .foregroundStyle(.secondary)

                if let fatigue = signals.fatigue_trend {
                    HStack {
                        Text("Fatigue trend")
                            .font(.cardBody)
                        Spacer()
                        Text(fatigue.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.cardBody)
                            .foregroundStyle(.secondary)
                    }
                }

                if let injury = signals.injury_risk_level {
                    HStack {
                        Text("Injury risk")
                            .font(.cardBody)
                        Spacer()
                        Text(injury.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.cardBody)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Got It Button

    private var gotItButton: some View {
        Button {
            planStore.markPlanChangeSeen()
            dismiss()
        } label: {
            Text("Got it")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
        }
        .buttonStyle(.borderedProminent)
        .padding(.top, Spacing.sm)
    }

    // MARK: - Data Loading

    private func loadDecision() async {
        screenState = .loading

        let result = await apiClient.latestDecision()

        switch result {
        case .success(let response):
            screenState = .loaded(response.decision_record)
        case .failure(let status, let message):
            if status == 404 {
                screenState = .empty
            } else {
                screenState = .error(message)
            }
        }
    }

    // MARK: - Helpers

    private func triggerLabel(_ trigger: DecisionTrigger) -> String {
        switch trigger {
        case .new_activity:           return "Run completed"
        case .missed_workout:         return "Missed workout"
        case .reflection_submitted:   return "Reflection submitted"
        case .user_requested_recalc:  return "Recalculation requested"
        case .fatigue_flag:           return "High fatigue detected"
        case .injury_flag:            return "Injury reported"
        case .onboarding:             return "Initial plan created"
        }
    }

    private func triggerIcon(_ trigger: DecisionTrigger) -> String {
        switch trigger {
        case .new_activity:           return "figure.run"
        case .missed_workout:         return "calendar.badge.minus"
        case .reflection_submitted:   return "text.badge.checkmark"
        case .user_requested_recalc:  return "arrow.triangle.2.circlepath"
        case .fatigue_flag:           return "battery.25"
        case .injury_flag:            return "bandage"
        case .onboarding:             return "sparkles"
        }
    }

    private static func formatTimestamp(_ iso: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = isoFormatter.date(from: iso) ?? ISO8601DateFormatter().date(from: iso) else {
            return iso.prefix(10).description
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
