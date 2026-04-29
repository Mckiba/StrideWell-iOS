//
//  RunAnalysisSections.swift
//  Stridewell
//
//  Reusable analysis section views shared by RunAnalysisScreen and RunDetailScreen.
//

import SwiftUI

struct RunAnalysisSections: View {

    let data: RunAnalysisData
    let status: String?
    let unit: UnitSystem

    var body: some View {
        if status?.lowercased() == "partial" {
                HStack(alignment: .center, spacing: Spacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.orange)
                    Text("Partial analysis: some metrics are still unavailable.")
                        .font(.cardBody)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            
        }
        if let pva = data.planned_vs_actual {
            plannedVsActualSection(pva)
        }
        if let exec = data.execution_analysis {
            executionSection(exec)
        }
        if let hr = data.hr_analysis {
            hrSection(hr)
        }
//        if let trend = data.trend_context {
//            trendSection(trend)
//        }
        if data.planned_vs_actual == nil,
           data.execution_analysis == nil,
           data.hr_analysis == nil,
           data.trend_context == nil {
            CardView {
                Text("No analysis details available for this run.")
                    .font(.cardBody)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Planned vs Actual

    private func plannedVsActualSection(_ pva: PlannedVsActual) -> some View {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Text("Planned vs Actual")
                        .font(.cardTitle)
                    Spacer()
                    Text(pva.completed_as_planned ? "On plan" : "Off plan")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            (pva.completed_as_planned ? Color.green : Color.orange).opacity(0.15)
                        )
                        .foregroundStyle(pva.completed_as_planned ? Color.green : Color.orange)
                        .clipShape(Capsule())
                }
                if let d = pva.distance_delta_m {
                    keyValueRow("Distance", signed(d, suffix: "m"))
                }
                if let p = pva.pace_delta_s_per_km {
                    keyValueRow("Pace", signed(p, suffix: "s/km"))
                }
                Text(pva.notes)
                    .font(.cardBody)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        
    }

    // MARK: - Execution

    private func executionSection(_ exec: ExecutionAnalysis) -> some View {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Execution")
                    .font(.cardTitle)

                if let quality = exec.execution_quality {
                    keyValueRow("Quality", quality.score.capitalized)
                    if !quality.factors.isEmpty {
                        Text(quality.factors.joined(separator: " · "))
                            .font(.cardCaption)
                            .foregroundStyle(.secondary)
                    }
                }

                keyValueRow(
                    "Pace consistency",
                    exec.pace_consistency.classification.replacingOccurrences(of: "_", with: " ").capitalized
                )
                keyValueRow(
                    "Split profile",
                    exec.pace_consistency.split_profile.capitalized
                )
                keyValueRow(
                    "First half",
                    FormatUtils.pace(exec.pace_consistency.first_half_avg_pace_s_per_km, unit: unit)
                )
                keyValueRow(
                    "Second half",
                    FormatUtils.pace(exec.pace_consistency.second_half_avg_pace_s_per_km, unit: unit)
                )

                if let stopRatio = exec.stop_ratio, stopRatio > 0 {
                    keyValueRow("Stopped time", percent(stopRatio))
                }
            }
    }

    // MARK: - HR

    private func hrSection(_ hr: HRAnalysis) -> some View {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Heart Rate")
                    .font(.cardTitle)

                keyValueRow("Average", "\(hr.avg_hr_bpm) bpm")
                if let maxHr = hr.max_hr_bpm {
                    keyValueRow("Max", "\(maxHr) bpm")
                }

                if let drift = hr.cardiac_drift {
                    keyValueRow(
                        "Cardiac drift",
                        String(format: "%+.1f%% %@", drift.drift_pct, drift.significant ? "(significant)" : "")
                            .trimmingCharacters(in: .whitespaces)
                    )
                    Text(drift.interpretation)
                        .font(.cardCaption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let zones = hr.zone_distribution {
                    zoneBar(zones)
                    if let note = zones.zone_note {
                        Text(note)
                            .font(.cardCaption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                if let eff = hr.efficiency {
                    keyValueRow("Efficiency trend", eff.trend.replacingOccurrences(of: "_", with: " ").capitalized)
                }
            }
        
    }

    private func zoneBar(_ z: HRZoneDistribution) -> some View {
        let segments: [(label: String, pct: Double, color: Color)] = [
            ("Z1", z.zone_1_pct, .blue),
            ("Z2", z.zone_2_pct, .green),
            ("Z3", z.zone_3_pct, .yellow),
            ("Z4", z.zone_4_pct, .orange),
            ("Z5", z.zone_5_pct, .red),
        ]
        return VStack(alignment: .leading, spacing: Spacing.xs) {
            GeometryReader { geo in
                HStack(spacing: 1) {
                    ForEach(segments.indices, id: \.self) { i in
                        let seg = segments[i]
                        Rectangle()
                            .fill(seg.color.opacity(0.8))
                            .frame(width: max(0, geo.size.width * CGFloat(seg.pct / 100.0)))
                    }
                }
            }
            .frame(height: 8)
            .clipShape(RoundedRectangle(cornerRadius: 4))

            HStack {
                ForEach(segments.indices, id: \.self) { i in
                    let seg = segments[i]
                    Text("\(seg.label) \(Int(seg.pct.rounded()))%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    if i < segments.count - 1 { Spacer() }
                }
            }
        }
    }

    // MARK: - Trend

    private func trendSection(_ trend: TrendContext) -> some View {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Trends")
                    .font(.cardTitle)

                keyValueRow(
                    "This week",
                    String(format: "%.1f km · %d runs", trend.weekly_volume.current_week_km, trend.runs_this_week)
                )
                keyValueRow(
                    "Last week",
                    String(format: "%.1f km · %d runs", trend.weekly_volume.previous_week_km, trend.runs_last_week)
                )
                keyValueRow(
                    "4-week avg",
                    String(format: "%.1f km", trend.weekly_volume.four_week_avg_km)
                )
                keyValueRow(
                    "Volume trend",
                    trend.weekly_volume.trend.replacingOccurrences(of: "_", with: " ").capitalized
                )

                if let note = trend.pace_trend.note {
                    Text(note)
                        .font(.cardCaption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                keyValueRow(
                    "Compliance (14 days)",
                    "\(trend.compliance_last_14_days.completed)/\(trend.compliance_last_14_days.planned) · \(Int((trend.compliance_last_14_days.rate * 100).rounded()))%"
                )
                if trend.streak_days > 0 {
                    keyValueRow("Streak", "\(trend.streak_days) days")
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

    private func signed(_ value: Double, suffix: String) -> String {
        let rounded = value.rounded()
        if rounded == 0 { return "0 \(suffix)" }
        let sign = rounded > 0 ? "+" : ""
        return "\(sign)\(Int(rounded)) \(suffix)"
    }

    private func percent(_ fraction: Double) -> String {
        return "\(Int((fraction * 100).rounded()))%"
    }
}
