//
//  FitnessProfileScreen.swift
//  Stridewell
//
//  V2 Phase 2 — displays the athlete's current fitness profile: threshold pace
//  estimate, confidence, method/source, computed pace zones, HR zones when
//  available, and the history of prior estimates.
//
//  Loaded from GET /profile/fitness. A 404 means no profile exists yet (not
//  enough race or training data for the backend to infer one) — we render a
//  friendly empty state explaining what will unlock personalised paces.
//

import SwiftUI

struct FitnessProfileScreen: View {

    @Environment(\.apiClient) private var apiClient
    @Environment(\.settingsStore) private var settingsStore

    @State private var screenState: LoadableState<FitnessProfile> = .loading

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                switch screenState {
                case .loading:
                    LoadingStateView(message: "Loading fitness profile...")
                        .frame(minHeight: 240)

                case .empty:
                    EmptyStateView(
                        title: "Profile not ready yet",
                        subtitle: "Log a race or accumulate enough training runs and your training paces will personalise automatically."
                    )
                    .frame(minHeight: 240)

                case .error(let message):
                    ErrorStateView(message: message) {
                        Task { await load() }
                    }
                    .frame(minHeight: 240)

                case .loaded(let profile):
                    loadedSections(profile)
                }
            }
            .padding(Spacing.md)
        }
        .navigationTitle("Fitness Profile")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    // MARK: - Loading

    private func load() async {
        screenState = .loading
        switch await apiClient.fitnessProfile() {
        case .success(let profile):
            screenState = .loaded(profile)
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
    private func loadedSections(_ profile: FitnessProfile) -> some View {
        thresholdCard(profile)
        if let zones = profile.pace_zones {
            paceZonesCard(zones)
        }
        if let hr = profile.hr_zones {
            hrZonesCard(hr)
        }
        if !profile.history.isEmpty {
            historyCard(profile.history)
        }
    }

    // MARK: - Threshold Card

    private func thresholdCard(_ profile: FitnessProfile) -> some View {
        let unit = settingsStore.unitSystem
        return CardView {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Threshold Pace")
                    .font(.cardTitle)

                if let threshold = profile.estimated_threshold_pace_s_per_km {
                    Text(FormatUtils.pace(threshold, unit: unit))
                        .font(.title2.weight(.bold))
                } else {
                    Text("—")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.secondary)
                }

                if let confidence = profile.confidence {
                    confidenceBadge(confidence)
                }

                if let method = profile.estimation_method {
                    keyValueRow("Method", method.replacingOccurrences(of: "_", with: " ").capitalized)
                }
                if let date = profile.estimation_date {
                    keyValueRow("As of", date)
                }
                if let source = profile.estimation_source {
                    Text(source)
                        .font(.cardCaption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func confidenceBadge(_ confidence: String) -> some View {
        let color: Color = {
            switch confidence.lowercased() {
            case "high": return .green
            case "medium": return .orange
            default: return .gray
            }
        }()
        return Text(confidence.capitalized + " confidence")
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    // MARK: - Pace Zones

    private func paceZonesCard(_ zones: PaceZones) -> some View {
        let unit = settingsStore.unitSystem
        let rows: [(String, PaceRange)] = [
            ("Recovery", zones.recovery),
            ("Easy", zones.easy),
            ("Moderate", zones.moderate),
            ("Tempo", zones.tempo),
            ("Threshold", zones.threshold),
            ("Interval", zones.interval),
            ("Repetition", zones.repetition),
        ]
        return CardView {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Pace Zones")
                    .font(.cardTitle)
                ForEach(rows, id: \.0) { row in
                    keyValueRow(
                        row.0,
                        FormatUtils.paceRange(
                            min: row.1.min_s_per_km,
                            max: row.1.max_s_per_km,
                            unit: unit
                        )
                    )
                }
            }
        }
    }

    // MARK: - HR Zones

    private func hrZonesCard(_ hr: HRZones) -> some View {
        let rows: [(String, HRRange)] = [
            ("Zone 1 — Recovery", hr.zone_1),
            ("Zone 2 — Easy", hr.zone_2),
            ("Zone 3 — Tempo", hr.zone_3),
            ("Zone 4 — Threshold", hr.zone_4),
            ("Zone 5 — VO2max", hr.zone_5),
        ]
        return CardView {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Heart Rate Zones")
                    .font(.cardTitle)
                keyValueRow("Max HR", "\(hr.max_hr_bpm) bpm")
                keyValueRow(
                    "Source",
                    hr.max_hr_source.replacingOccurrences(of: "_", with: " ").capitalized
                )
                Divider()
                ForEach(rows, id: \.0) { row in
                    keyValueRow(row.0, "\(row.1.min_bpm)–\(row.1.max_bpm) bpm")
                }
            }
        }
    }

    // MARK: - History

    private func historyCard(_ history: [FitnessProfileHistoryEntry]) -> some View {
        let unit = settingsStore.unitSystem
        return CardView {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("History")
                    .font(.cardTitle)
                ForEach(history) { entry in
                    HStack {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text(entry.date)
                                .font(.cardBody)
                            Text(entry.method.replacingOccurrences(of: "_", with: " ").capitalized)
                                .font(.cardCaption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(FormatUtils.pace(entry.threshold_pace_s_per_km, unit: unit))
                            .font(.cardBody.weight(.semibold))
                    }
                    if entry.id != history.last?.id {
                        Divider()
                    }
                }
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
}

// MARK: - Preview

#Preview {
    NavigationStack {
        FitnessProfileScreen()
    }
}
