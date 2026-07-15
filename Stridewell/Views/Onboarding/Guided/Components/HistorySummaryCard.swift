//
//  HistorySummaryCard.swift
//  Stridewell
//
//  Summary of the computed Strava history: a 12-week volume chart with the current
//  week highlighted, plus weekly-average, peak-week, and runs-per-week stats. The
//  athlete confirms or corrects these values through the chat rather than with
//  controls. Distances render in the athlete's unit.
//

import SwiftUI
import Charts

struct HistorySummaryCard: View {

    let summary: StravaHistorySummary

    /// Strava brand orange — the chart shows Strava-sourced data.
    private static let lineColor = Color(hex: "#FC4C02")

    private struct ChartPoint: Identifiable {
        let weekStart: Date
        let volume: Double   // display units (mi or km)
        var id: Date { weekStart }
    }

    /// Week series converted to dates and display units. Empty when the summary
    /// predates the series field.
    private var points: [ChartPoint] {
        (summary.weekly_volumes ?? []).compactMap { week in
            guard let date = DateUtils.parse(week.week_start) else { return nil }
            return ChartPoint(
                weekStart: date,
                volume: OnboardingUnits.displayValue(fromKm: week.volume_km)
            )
        }
    }

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("From your Strava")
                    .font(.cardTitle)

                if points.count >= 2 {
                    volumeChart
                }

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

    // MARK: - Chart

    /// Y-axis top: the biggest week, with headroom so the peak point isn't clipped.
    private var peakDisplay: Double {
        max(points.map(\.volume).max() ?? 0, 1)
    }

    private var volumeChart: some View {
        Chart {
            ForEach(points) { point in
                AreaMark(
                    x: .value("Week", point.weekStart),
                    y: .value("Volume", point.volume)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Self.lineColor.opacity(0.30), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                LineMark(
                    x: .value("Week", point.weekStart),
                    y: .value("Volume", point.volume)
                )
                .foregroundStyle(Self.lineColor)
                .lineStyle(StrokeStyle(lineWidth: 2.5, lineJoin: .round))

                PointMark(
                    x: .value("Week", point.weekStart),
                    y: .value("Volume", point.volume)
                )
                .foregroundStyle(Self.lineColor)
                .symbolSize(45)
            }

            // Emphasize the most recent week and label its value.
            if let last = points.last {
                PointMark(
                    x: .value("Week", last.weekStart),
                    y: .value("Volume", last.volume)
                )
                .foregroundStyle(Self.lineColor)
                .symbolSize(150)
                .annotation(position: .top, alignment: .center) {
                    Text(OnboardingUnits.formatted(displayValue: last.volume))
                        .font(.cardCaption.bold())
                        .foregroundStyle(AppColor.textPrimary)
                }
            }
        }
        .chartYScale(domain: 0...(peakDisplay * 1.2))
        .chartXAxis {
            AxisMarks(values: .stride(by: .month)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month(.abbreviated))
                    .font(.cardCaption)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: [0, peakDisplay / 2, peakDisplay]) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let volume = value.as(Double.self) {
                        Text(OnboardingUnits.formatted(displayValue: volume))
                            .font(.cardCaption)
                    }
                }
            }
        }
        .frame(height: 150)
    }

    // MARK: - Stats

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

#if DEBUG
extension StravaHistorySummary {
    /// Sample summary with a 12-week series for previews.
    static var previewWithSeries: StravaHistorySummary {
        let volumes: [Double] = [0, 30, 55, 28, 32, 22, 18, 15, 32, 4, 20, 11]
        let monday = DateUtils.mondayOfWeek(containing: Date())
        let weeks = volumes.enumerated().map { index, km in
            let start = Calendar.current.date(
                byAdding: .weekOfYear,
                value: index - volumes.count,
                to: monday
            ) ?? monday
            return HistoryWeekVolume(week_start: DateUtils.format(start), volume_km: km)
        }
        return StravaHistorySummary(
            avg_weekly_volume_km_4wk: 40,
            avg_weekly_volume_km_12wk: 36,
            peak_weekly_volume_km_12wk: 55,
            recent_long_run_m: 18000,
            avg_runs_per_week_4wk: 4,
            consistency_rate_12wk: 0.8,
            has_speed_work: true,
            inferred_training_phase: "base",
            volume_trend: "stable",
            weekly_volumes: weeks
        )
    }
}

#Preview("With chart") {
    HistorySummaryCard(summary: .previewWithSeries)
        .padding()
}

#Preview("Stats only") {
    HistorySummaryCard(summary: StravaHistorySummary(
        avg_weekly_volume_km_4wk: 40,
        avg_weekly_volume_km_12wk: 36,
        peak_weekly_volume_km_12wk: 52,
        recent_long_run_m: 18000,
        avg_runs_per_week_4wk: 4,
        consistency_rate_12wk: 0.8,
        has_speed_work: true,
        inferred_training_phase: "base",
        volume_trend: "stable"
    ))
    .padding()
}
#endif
