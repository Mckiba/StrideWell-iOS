//
//  SplitsTableView.swift
//  Stridewell
//
//  Per-mile splits table used in RunDetailScreen.
//

import SwiftUI

struct SplitsTableView: View {

    let splits: [RunSplit]
    let unit: UnitSystem

    var body: some View {
        if splits.isEmpty {
            EmptyStateView(
                title: "No splits",
                subtitle: "Splits will appear here once the run has GPS data."
            )
        } else {
            VStack(spacing: 0) {
                headerRow
                Divider()
                ForEach(splits) { split in
                    splitRow(split)
                    if split.id != splits.last?.id {
                        Divider().padding(.leading, Spacing.md)
                    }
                }
            }
        }
    }

    private var headerRow: some View {
        HStack {
            Text("MILE")
                .frame(width: 44, alignment: .leading)
            Spacer()
            Text("PACE")
                .frame(width: 80, alignment: .trailing)
            Text("ELEV")
                .frame(width: 52, alignment: .trailing)
        }
        .font(.cardCaption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }

    private func splitRow(_ split: RunSplit) -> some View {
        HStack {
            Text("\(split.index)")
                .font(.activityTimestamp)
                .frame(width: 44, alignment: .leading)
            Spacer()
            Text(FormatUtils.pace(split.avg_pace_s_per_km, unit: unit))
                .font(.activityTimestamp)
                .frame(width: 80, alignment: .trailing)
            Text(elevationLabel(split.elevation_gain_m))
                .font(.activityTimestamp)
                .foregroundStyle(.secondary)
                .frame(width: 52, alignment: .trailing)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }

    private func elevationLabel(_ gain: Double?) -> String {
        guard let gain, gain != 0 else { return "—" }
        let sign = gain > 0 ? "+" : ""
        return "\(sign)\(Int(gain.rounded()))m"
    }
}

// MARK: - Previews

#Preview("With splits") {
    let splits: [RunSplit] = [
        RunSplit(index: 1, distance_m: 1609.344, duration_s: 479, avg_pace_s_per_km: 298, avg_hr_bpm: 162, avg_cadence_spm: 178, elevation_gain_m: 12.0, source: "lap"),
        RunSplit(index: 2, distance_m: 1609.344, duration_s: 461, avg_pace_s_per_km: 286, avg_hr_bpm: 168, avg_cadence_spm: 182, elevation_gain_m: nil, source: "lap"),
        RunSplit(index: 3, distance_m: 1609.344, duration_s: 445, avg_pace_s_per_km: 277, avg_hr_bpm: 174, avg_cadence_spm: 185, elevation_gain_m: -4.0, source: "lap"),
        RunSplit(index: 4, distance_m: 1609.344, duration_s: 431, avg_pace_s_per_km: 268, avg_hr_bpm: 179, avg_cadence_spm: 188, elevation_gain_m: nil, source: "lap"),
    ]
    return SplitsTableView(splits: splits, unit: .imperial)
        .padding(.vertical)
}

#Preview("Empty") {
    SplitsTableView(splits: [], unit: .metric)
        .padding()
}
