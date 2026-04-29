//
//  RunStreamChart.swift
//  Stridewell
//
//  Elevation, heart rate, and cadence stream charts for RunDetailScreen.
//

import SwiftUI
import Charts

enum StreamChartType {
    case elevation
    case heartRate
    case cadence

    var label: String {
        switch self {
        case .elevation: return "elevation"
        case .heartRate: return "heart rate"
        case .cadence:   return "cadence"
        }
    }

    var yAxisLabel: String {
        switch self {
        case .elevation: return "m"
        case .heartRate: return "bpm"
        case .cadence:   return "spm"
        }
    }
}

struct RunStreamChart: View {

    let distances: [Double]
    let values: [Double]?
    let type: StreamChartType

    var body: some View {
        if let values, !values.isEmpty, values.count == distances.count {
            chartView(values: values)
        } else {
            EmptyStateView(
                title: "No data",
                subtitle: "No \(type.label) recorded for this run."
            )
            .frame(height: 120)
        }
    }

    private func chartView(values: [Double]) -> some View {
        let points = stride(from: 0, to: min(distances.count, values.count), by: 1).map { i in
            ChartPoint(distanceMi: distances[i] / 1609.344, value: values[i])
        }

        return Chart(points) { point in
            switch type {
            case .elevation:
                AreaMark(
                    x: .value("Distance", point.distanceMi),
                    y: .value(type.yAxisLabel, point.value)
                )
                .foregroundStyle(AppColor.accent.opacity(0.25))
                LineMark(
                    x: .value("Distance", point.distanceMi),
                    y: .value(type.yAxisLabel, point.value)
                )
                .foregroundStyle(AppColor.accent)
                .lineStyle(StrokeStyle(lineWidth: 2))

            case .heartRate, .cadence:
                LineMark(
                    x: .value("Distance", point.distanceMi),
                    y: .value(type.yAxisLabel, point.value)
                )
                .foregroundStyle(AppColor.accent)
                .lineStyle(StrokeStyle(lineWidth: 2))
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                AxisValueLabel {
                    if let d = value.as(Double.self) {
                        Text(String(format: "%.1f mi", d))
                            .font(.caption2)
                    }
                }
                AxisGridLine()
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        Text("\(Int(v)) \(type.yAxisLabel)")
                            .font(.caption2)
                    }
                }
                AxisGridLine()
            }
        }
        .frame(height: 130)
    }
}

private struct ChartPoint: Identifiable {
    let id = UUID()
    let distanceMi: Double
    let value: Double
}

// MARK: - Previews

private let previewDistances: [Double] = stride(from: 0.0, to: 7242.0, by: 72.0).map { $0 }

#Preview("Elevation") {
    let alt = previewDistances.enumerated().map { i, d in
        50.0 + 20.0 * sin(Double(i) / 10.0) + 5.0 * sin(Double(i) / 3.0)
    }
    return RunStreamChart(distances: previewDistances, values: alt, type: .elevation)
        .padding()
}

#Preview("Heart Rate") {
    let hr = previewDistances.enumerated().map { i, _ in
        155.0 + 15.0 * sin(Double(i) / 8.0)
    }
    return RunStreamChart(distances: previewDistances, values: hr, type: .heartRate)
        .padding()
}

#Preview("Cadence") {
    let cad = previewDistances.map { _ in Double.random(in: 172...186) }
    return RunStreamChart(distances: previewDistances, values: cad, type: .cadence)
        .padding()
}

#Preview("No data") {
    RunStreamChart(distances: [], values: nil, type: .heartRate)
        .padding()
}
