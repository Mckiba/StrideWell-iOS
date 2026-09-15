//
//  ActivityVolumeChart.swift
//  Stridewell
//
//  Distance per bucket for the selected Activities period: days for a week or
//  month, months for a year, years for all time. Tapping a bar shows a callout
//  above the chart: the run's card for a single-run bucket, otherwise the
//  bucket's distance and run count.
//

import SwiftUI
import Charts

struct ActivityVolumeChart: View {

    let range: ActivityRange
    let buckets: [RunSummaryBucket]
    let loadRun: (RunSummaryBucket) async -> Run?
    let onOpenRun: (Run) -> Void

    @Environment(\.settingsStore) private var settingsStore

    @State private var selectedKey: String? = nil
    @State private var selectedRun: Run? = nil

    private var unit: UnitSystem { settingsStore.unitSystem }

    private var selectedBucket: RunSummaryBucket? {
        selectedKey.flatMap { key in buckets.first { $0.key == key } }
    }

    /// Largest bucket in display units, floored at 1 so an empty period still draws a grid.
    private var peak: Double {
        max(buckets.map { FormatUtils.distanceValue($0.distance_m, unit: unit) }.max() ?? 0, 1)
    }

    var body: some View {
        chart
            .frame(height: 140)
            .overlay(alignment: .top) {
                if let bucket = selectedBucket {
                    callout(for: bucket)
                        .alignmentGuide(.top) { d in d[.bottom] + Spacing.sm }
                        .transition(.opacity)
                }
            }
            .animation(.easeOut(duration: 0.15), value: selectedKey)
            .task(id: selectedKey) {
                selectedRun = nil
                guard let bucket = selectedBucket, bucket.run_count == 1 else { return }
                let run = await loadRun(bucket)
                guard !Task.isCancelled else { return }
                selectedRun = run
            }
            .onChange(of: buckets.map(\.key)) { _, _ in
                selectedKey = nil
            }
    }

    // MARK: - Chart

    private var chart: some View {
        Chart(buckets) { bucket in
            BarMark(
                x: .value("Period", bucket.key),
                y: .value("Distance", FormatUtils.distanceValue(bucket.distance_m, unit: unit))
            )
            .cornerRadius(2)
            .foregroundStyle(AppColor.accent.opacity(selectedKey == nil || selectedKey == bucket.key ? 1 : 0.35))
        }
        .chartYScale(domain: 0...(peak * 1.15))
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 6)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(AppColor.chartGrid)
            }
        }
        .chartXAxis {
            AxisMarks(values: labeledKeys) { value in
                AxisValueLabel {
                    if let key = value.as(String.self) {
                        Text(DateUtils.bucketAxisLabel(for: range, key: key))
                            .font(.activityStatLabel)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                }
            }
        }
        .chartPlotStyle { plot in
            plot.border(AppColor.chartGrid, width: 0.5)
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        select(at: location, proxy: proxy, geometry: geometry)
                    }
            }
        }
    }

    /// Keys that get an x-axis label; a month labels every 7th day to avoid crowding.
    private var labeledKeys: [String] {
        guard range == .month else { return buckets.map(\.key) }
        return buckets.enumerated().filter { $0.offset % 7 == 0 }.map(\.element.key)
    }

    /// Selects the tapped bar. Tapping the selected bar, an empty bucket, or
    /// outside the plot clears the selection.
    private func select(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) {
        guard let plotFrame = proxy.plotFrame else { return }
        let x = location.x - geometry[plotFrame].origin.x
        guard let key: String = proxy.value(atX: x),
              key != selectedKey,
              let bucket = buckets.first(where: { $0.key == key }),
              bucket.run_count > 0
        else {
            selectedKey = nil
            return
        }
        selectedKey = key
    }

    // MARK: - Callout

    @ViewBuilder
    private func callout(for bucket: RunSummaryBucket) -> some View {
        if bucket.run_count == 1, let run = selectedRun {
            ActivityCard(run: run)
                .onTapGesture { onOpenRun(run) }
        } else {
            CardView(padding: Spacing.sm) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(DateUtils.bucketTitle(for: range, key: bucket.key))
                        .font(.activityName)
                        .foregroundStyle(AppColor.textPrimary)
                    Text("\(FormatUtils.distance(bucket.distance_m, unit: unit)), \(bucket.run_count) \(bucket.run_count == 1 ? "run" : "runs")")
                        .font(.activityStatLabel)
                        .foregroundStyle(AppColor.textSecondary)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Week") {
    let days = ["2026-09-14", "2026-09-15", "2026-09-16", "2026-09-17", "2026-09-18", "2026-09-19", "2026-09-20"]
    let distances: [Double] = [8_046, 0, 12_874, 4_828, 0, 19_312, 6_437]
    let buckets = zip(days, distances).map { day, distance in
        RunSummaryBucket(key: day, distance_m: distance, run_count: distance > 0 ? 1 : 0, run_id: nil)
    }
    ActivityVolumeChart(range: .week, buckets: buckets, loadRun: { _ in nil }, onOpenRun: { _ in })
        .padding(.horizontal)
        .padding(.top, 120)
}

#Preview("Year") {
    let distances: [Double] = [96_000, 112_000, 128_000, 80_000, 144_000, 160_000,
                               136_000, 150_000, 64_000, 0, 0, 0]
    let buckets = distances.enumerated().map { index, distance in
        RunSummaryBucket(
            key: String(format: "2026-%02d", index + 1),
            distance_m: distance,
            run_count: Int(distance / 8_000),
            run_id: nil
        )
    }
    ActivityVolumeChart(range: .year, buckets: buckets, loadRun: { _ in nil }, onOpenRun: { _ in })
        .padding(.horizontal)
        .padding(.top, 120)
}

#Preview("Empty month") {
    let buckets = (1...30).map { day in
        RunSummaryBucket(key: String(format: "2026-09-%02d", day), distance_m: 0, run_count: 0, run_id: nil)
    }
    ActivityVolumeChart(range: .month, buckets: buckets, loadRun: { _ in nil }, onOpenRun: { _ in })
        .padding()
}
