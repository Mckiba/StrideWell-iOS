//
//  WorkoutCardView.swift
//  Stridewell
//
//  Minimal workout row — no badges or icons per V1 design spec.
//  Used on PlanRevealScreen (M6), HomeScreen (M7), and PlanScreen (M8).
//

import SwiftUI

struct WorkoutCardView: View {

    let day: PlanDay
    var isToday: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Date column — fixed width so workout labels align across rows
            VStack(alignment: .center, spacing: 2) {
                Text(dayAbbreviation)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                Text(dayNumber)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(isToday ? Color.accentColor : Color.primary)
            }
            .frame(width: 36)

            // Workout content
            VStack(alignment: .leading, spacing: 3) {
                Text(day.workout.label)
                    .font(.body.weight(isToday ? .semibold : .regular))
                    .foregroundStyle(isRest ? Color.secondary : (isToday ? Color.accentColor : Color.primary))

                if let metric = metricLine {
                    Text(metric)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }

    // MARK: - Computed

    private var isRest: Bool {
        day.workout.type == .rest || day.workout.type == .recovery
    }

    /// First available metric: distance, then pace, then duration.
    private var metricLine: String? {
        if isRest { return nil }
        var parts: [String] = []
        if let d = day.workout.target_distance_m {
            parts.append(FormatUtils.distance(d))
        }
        if let p = day.workout.target_pace_s_per_km {
            parts.append(FormatUtils.pace(p))
        } else if let dur = day.workout.target_duration_s {
            parts.append(FormatUtils.duration(dur))
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    // MARK: - Date helpers

    private var parsedDate: Date? {
        Self.dateParser.date(from: day.date)
    }

    private var dayAbbreviation: String {
        guard let d = parsedDate else { return "" }
        return Self.dayFormatter.string(from: d)
    }

    private var dayNumber: String {
        guard let d = parsedDate else { return "" }
        return Self.numberFormatter.string(from: d)
    }

    private static let dateParser: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE"   // "Mon", "Tue", …
        return f
    }()

    private static let numberFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d"     // "3", "14", …
        return f
    }()
}
