//
//  WeeklySummaryScreen.swift
//  Stridewell
//
//  V2 Phase 2 — GET /analysis/weekly?start=YYYY-MM-DD. Shows volume, compliance,
//  long run, quality sessions, and volume delta vs the previous week. Reached
//  from PlanScreen — the week defaults to the week the athlete is currently
//  viewing on the plan.
//

import SwiftUI

struct WeeklySummaryScreen: View {

    /// Monday of the week to summarise.
    let monday: Date

    @Environment(\.apiClient) private var apiClient
    @Environment(\.settingsStore) private var settingsStore

    @State private var screenState: LoadableState<WeeklySummary> = .loading

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                switch screenState {
                case .loading:
                    LoadingStateView(message: "Loading weekly summary...")
                        .frame(minHeight: 240)

                case .empty:
                    EmptyStateView(
                        title: "Nothing yet this week",
                        subtitle: "Once you start logging runs, your summary will appear here."
                    )
                    .frame(minHeight: 240)

                case .error(let message):
                    ErrorStateView(message: message) {
                        Task { await load() }
                    }
                    .frame(minHeight: 240)

                case .loaded(let summary):
                    loadedSections(summary)
                }
            }
            .padding(Spacing.md)
        }
        .navigationTitle(DateUtils.weekRangeLabel(monday: monday))
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    // MARK: - Loading

    private func load() async {
        screenState = .loading
        let startKey = DateUtils.format(monday)
        switch await apiClient.weeklySummary(weekStart: startKey) {
        case .success(let summary):
            if summary.run_count == 0 && summary.planned_run_count == 0 {
                screenState = .empty
            } else {
                screenState = .loaded(summary)
            }
        case .failure(let status, let message):
            if status == 404 {
                screenState = .empty
            } else {
                screenState = .error(message)
            }
        }
    }

    // MARK: - Loaded Sections

    @ViewBuilder
    private func loadedSections(_ summary: WeeklySummary) -> some View {
        overviewCard(summary)
        if let long = summary.long_run {
            longRunCard(long)
        }
        if !summary.quality_sessions.isEmpty {
            qualitySessionsCard(summary.quality_sessions)
        }
        fatigueCard(summary)
    }

    // MARK: - Overview

    private func overviewCard(_ s: WeeklySummary) -> some View {
        let unit = settingsStore.unitSystem
        let compliancePct = Int((s.compliance_rate * 100).rounded())
        return CardView {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Overview")
                    .font(.cardTitle)

                HStack(spacing: Spacing.lg) {
                    CardStat(
                        label: "DISTANCE",
                        value: FormatUtils.distance(s.total_distance_m, unit: unit)
                    )
                    Spacer()
                    CardStat(
                        label: "TIME",
                        value: FormatUtils.duration(s.total_duration_s)
                    )
                    Spacer()
                    CardStat(
                        label: "RUNS",
                        value: "\(s.run_count)"
                    )
                }
                .padding(.top, Spacing.xs)

                Divider()

                keyValueRow(
                    "Compliance",
                    "\(s.run_count)/\(s.planned_run_count) · \(compliancePct)%"
                )
                if let avgEasy = s.avg_easy_pace_s_per_km {
                    keyValueRow("Avg easy pace", FormatUtils.pace(avgEasy, unit: unit))
                }
                if let deltaPct = s.volume_vs_previous_week_pct {
                    keyValueRow("Vs last week", signedPercent(deltaPct))
                }
            }
        }
    }

    // MARK: - Long Run

    private func longRunCard(_ long: WeeklyLongRun) -> some View {
        let unit = settingsStore.unitSystem
        return CardView {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Long Run")
                    .font(.cardTitle)
                keyValueRow("Date", DateUtils.planDayDate(long.date))
                keyValueRow("Distance", FormatUtils.distance(long.distance_m, unit: unit))
                keyValueRow("Avg pace", FormatUtils.pace(long.pace_s_per_km, unit: unit))
            }
        }
    }

    // MARK: - Quality Sessions

    private func qualitySessionsCard(_ sessions: [WeeklyQualitySession]) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Quality Sessions")
                    .font(.cardTitle)
                ForEach(sessions) { session in
                    HStack {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text(session.type.replacingOccurrences(of: "_", with: " ").capitalized)
                                .font(.cardBody)
                            Text(DateUtils.planDayDate(session.date))
                                .font(.cardCaption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        qualityBadge(session.execution_quality)
                    }
                    if session.id != sessions.last?.id {
                        Divider()
                    }
                }
            }
        }
    }

    private func qualityBadge(_ quality: String) -> some View {
        let color: Color = {
            switch quality.lowercased() {
            case "excellent": return .green
            case "good": return .accentColor
            case "fair": return .orange
            case "poor": return .red
            default: return .gray
            }
        }()
        return Text(quality.capitalized)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    // MARK: - Fatigue

    private func fatigueCard(_ s: WeeklySummary) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Fatigue Trend")
                    .font(.cardTitle)
                Text(s.fatigue_trend)
                    .font(.cardBody)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Helpers

    private func keyValueRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.cardBody)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.cardBody.weight(.semibold))
        }
    }

    private func signedPercent(_ pct: Double) -> String {
        let rounded = pct.rounded()
        if rounded == 0 { return "0%" }
        let sign = rounded > 0 ? "+" : ""
        return "\(sign)\(Int(rounded))%"
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        WeeklySummaryScreen(monday: DateUtils.mondayOfWeek(containing: Date()))
    }
}
