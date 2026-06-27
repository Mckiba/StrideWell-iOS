//
//  HistorySummaryCard.swift
//  Stridewell
//
//  Read-only summary of the computed Strava history shown on S2a (HistoryConfirm).
//  The athlete confirms or corrects these values through the chat — there are no
//  controls here (a toggle would invite contradicting Strava without explanation).
//  All distances render in the athlete's unit preference.
//

import SwiftUI

struct HistorySummaryCard: View {

    let summary: StravaHistorySummary

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("From your Strava")
                    .font(.cardTitle)

                HStack(alignment: .top) {
                    stat("Weekly avg", volume(summary.avg_weekly_volume_km_4wk))
                    Spacer()
                    stat("Peak week", volume(summary.peak_weekly_volume_km_12wk))
                    Spacer()
                    stat("Runs / wk", runsPerWeek)
                }

                if let phase = phaseLabel {
                    Text("Looks like a \(phase) phase — sound right?")
                        .font(.cardCaption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Pieces

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.cardTitle)
            Text(label).font(.cardCaption).foregroundStyle(.secondary)
        }
    }

    private func volume(_ km: Double?) -> String {
        guard let km else { return "—" }
        let value = OnboardingUnits.displayValue(fromKm: km)
        return OnboardingUnits.formatted(displayValue: value)
    }

    private var runsPerWeek: String {
        guard let runs = summary.avg_runs_per_week_4wk else { return "—" }
        return String(format: "%.1f", runs)
    }

    private var phaseLabel: String? {
        guard let phase = summary.inferred_training_phase,
              phase != "insufficient_data" else { return nil }
        return phase.replacingOccurrences(of: "_", with: " ")
    }
}
