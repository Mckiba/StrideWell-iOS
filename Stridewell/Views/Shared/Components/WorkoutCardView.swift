//
//  WorkoutCardView.swift
//  Stridewell
//

import SwiftUI

struct WorkoutCardView: View {

    let day: PlanDay
    var isToday: Bool = false

    @Environment(\.settingsStore) private var settingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {

            // Row 1: label (left) + date (right)
            HStack(alignment: .center) {
                Text(day.workout.label)
                    .font(.activityName)
                    .foregroundStyle(AppColor.textPrimary)
                Spacer()
                Text(cardDate)
                    .font(.activityTimestamp)
                    .foregroundStyle(AppColor.textPrimary)
            }

            // Row 2: metric (distance · pace or duration)
            if let metric = metricLine {
                Text(metric)
                    .font(.activityStatLabel)
                    .foregroundStyle(AppColor.textPrimary)
            }

            // Row 3: notes / description
            if let notes = notesLine {
                Text(notes)
                    .font(.activityStatLabel)
                    .foregroundStyle(AppColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        .shadow(color: Color.black.opacity(0.14), radius: 15, x: 0, y: 12)
        .contentShape(Rectangle())
    }

    // MARK: - Computed

    private var isRest: Bool {
        day.workout.type == .rest || day.workout.type == .recovery
    }

    private var metricLine: String? {
        if isRest { return nil }
        let unit = settingsStore.unitSystem
        var parts: [String] = []
        if let d = day.workout.target_distance_m {
            parts.append(FormatUtils.distance(d, unit: unit))
        }
        if let p = day.workout.target_pace_s_per_km {
            parts.append(FormatUtils.pace(p, unit: unit))
        } else if let dur = day.workout.target_duration_s {
            parts.append(FormatUtils.duration(dur))
        }
        return parts.isEmpty ? nil : parts.joined(separator: "  ·  ")
    }

    private var notesLine: String? {
        day.workout.notes ?? day.workout.description
    }

    private var cardDate: String {
        guard let d = DateUtils.parse(day.date) else { return "" }
        return DateUtils.workoutCardDateFormatter.string(from: d)
    }
}

#Preview {
    let easy = PlanDay(
        date: "2026-03-09",
        workout: Workout(
            type: .easy,
            label: "Easy Run",
            description: "Flat route is ideal",
            target_distance_m: 9656,
            target_duration_s: nil,
            target_pace_s_per_km: 360,
            intensity: .easy,
            notes: "Try to keep hr below 150bpm"
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

    return ScrollView {
        VStack(spacing: 12) {
            WorkoutCardView(day: easy, isToday: true)
            WorkoutCardView(day: rest)
            WorkoutCardView(day: long)
        }
        .padding()
    }
    .background(Color(uiColor: .systemGroupedBackground))
}
