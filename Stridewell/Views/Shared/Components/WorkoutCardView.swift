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
        HStack(alignment: .top, spacing: Spacing.md) {
            // Date column — fixed width so workout labels align across rows
            VStack(alignment: .center, spacing: 2) {
                Text(dayAbbreviation)
                    .font(.dateDay)
                    .foregroundStyle(AppColor.textSecondary)
                Text(dayNumber)
                    .font(.dateNumber)
                    .foregroundStyle(isToday ? AppColor.accent : AppColor.textPrimary)
            }
            .frame(width: 36)

            // Workout content
            VStack(alignment: .leading, spacing: 3) {
                Text(day.workout.label)
                    .font(.body.weight(isToday ? .semibold : .regular))
                    .foregroundStyle(isRest ? AppColor.textSecondary : (isToday ? AppColor.accent : AppColor.textPrimary))

                if let metric = metricLine {
                    Text(metric)
                        .font(.cardBody)
                        .foregroundStyle(AppColor.textSecondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, Spacing.sm + 2)  // 10pt — keeps rows compact
        .padding(.horizontal, Spacing.md)
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

    // MARK: - Date helpers (delegates to shared DateUtils)

    private var parsedDate: Date? { DateUtils.parse(day.date) }

    private var dayAbbreviation: String {
        guard let d = parsedDate else { return "" }
        return DateUtils.dayAbbrevFormatter.string(from: d)
    }

    private var dayNumber: String {
        guard let d = parsedDate else { return "" }
        return DateUtils.dayNumberFormatter.string(from: d)
    }
}

#Preview {
    let easy = PlanDay(
        date: "2026-03-09",
        workout: Workout(
            type: .easy,
            label: "Easy Run",
            description: nil,
            target_distance_m: 8000,
            target_duration_s: nil,
            target_pace_s_per_km: 360,
            intensity: .easy,
            notes: nil
        ),
        notes: nil
    )
    let long = PlanDay(
        date: "2026-03-14",
        workout: Workout(
            type: .long_run,
            label: "Long Run",
            description: nil,
            target_distance_m: 20000,
            target_duration_s: nil,
            target_pace_s_per_km: 390,
            intensity: .moderate,
            notes: nil
        ),
        notes: nil
    )
    let rest = PlanDay(
        date: "2026-03-10",
        workout: Workout(
            type: .rest,
            label: "Rest Day",
            description: nil,
            target_distance_m: nil,
            target_duration_s: nil,
            target_pace_s_per_km: nil,
            intensity: nil,
            notes: nil
        ),
        notes: nil
    )

    return VStack(spacing: 0) {
        WorkoutCardView(day: easy, isToday: true)
        Divider().padding(.leading, 56)
        WorkoutCardView(day: rest)
        Divider().padding(.leading, 56)
        WorkoutCardView(day: long)
    }
    .padding(.vertical)
}

