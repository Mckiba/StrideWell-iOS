//
//  WorkoutCardView.swift
//  Stridewell
//

import SwiftUI

struct WorkoutCard: View {

    let day: PlanDay
    var isToday: Bool = false

    @Environment(\.settingsStore) private var settingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {

            HStack(alignment: .center) {
                Text(day.workout.label)
                    .font(.activityName)
                    .foregroundStyle(AppColor.textPrimary)
                Spacer()
                Text(cardDate)
                    .font(.activityTimestamp)
                    .foregroundStyle(AppColor.textPrimary)
            }

            // Row 2: three stat columns (hidden for rest/recovery)
            if !isRest {
                HStack(spacing: Spacing.lg) {
                    CardStat(label: "DISTANCE",    value: distanceValue)
                    Spacer()
                    CardStat(label: "TIME",        value: timeValue)
                    Spacer()
                    CardStat(label: "TARGET PACE", value: paceValue)
                }
            }

            // Row 3: notes / description
            if let notes = notesLine {
                Text(notes)
                    .font(.activityStatLabel)
                    .foregroundStyle(AppColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity,minHeight:40, alignment: .leading)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.xs)
        .background(AppColor.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        .shadow(color: .black.opacity(0.10), radius: 8, x: 0, y: 2)
    }

    // MARK: - Computed

    private var isRest: Bool {
        day.workout.type == .rest || day.workout.type == .recovery
    }

    private var distanceValue: String {
        guard let d = day.workout.target_distance_m else { return "-" }
        return FormatUtils.distance(d, unit: settingsStore.unitSystem)
    }

    private var timeValue: String {
        guard let dur = day.workout.target_duration_s else { return "-" }
        return FormatUtils.duration(dur)
    }

    private var paceValue: String {
        guard let p = day.workout.target_pace_s_per_km else { return "-" }
        return FormatUtils.pace(p, unit: settingsStore.unitSystem)
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
            WorkoutCard(day: easy, isToday: true)
            WorkoutCard(day: rest)
            WorkoutCard(day: long)
        }
        .padding()
    }
    .background(Color(uiColor: .systemGroupedBackground))
}
