//
//  ActivityStatsRow.swift
//  Stridewell
//
//  Runs / Avg. Pace / Time totals under the Activities overview distance.
//

import SwiftUI

struct ActivityStatsRow: View {

    let totals: RunSummaryTotals

    @Environment(\.settingsStore) private var settingsStore

    var body: some View {
        HStack(alignment: .top) {
            OverviewStat(label: "Runs", value: "\(totals.run_count)")
            Spacer()
            OverviewStat(label: "Avg. Pace", value: paceValue)
            Spacer()
            OverviewStat(label: "Time", value: totals.run_count == 0 ? "0" : FormatUtils.duration(totals.duration_s))
        }
    }

    private var paceValue: String {
        if let pace = totals.avg_pace_s_per_km {
            return FormatUtils.pace(pace, unit: settingsStore.unitSystem)
        }
        return totals.run_count == 0 ? "0" : "—"
    }
}

private struct OverviewStat: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(value)
                .font(.activityOverviewStatValue)
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(1)
            Text(label)
                .font(.activityOverviewStatLabel)
                .foregroundStyle(AppColor.textSecondary)
                .lineLimit(1)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(alignment: .leading, spacing: Spacing.xl) {
        ActivityStatsRow(totals: RunSummaryTotals(
            distance_m: 32_186,
            run_count: 5,
            duration_s: 10_800,
            avg_pace_s_per_km: 335.6
        ))
        ActivityStatsRow(totals: RunSummaryTotals(
            distance_m: 0,
            run_count: 0,
            duration_s: 0,
            avg_pace_s_per_km: nil
        ))
    }
    .padding()
}
