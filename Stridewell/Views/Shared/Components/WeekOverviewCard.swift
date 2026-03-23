//
//  WeekOverviewCard.swift
//  Stridewell
//
//  Weekly summary card shown on PlanScreen below the week navigator.
//  Displays planned vs actual workout count and distance for the week.
//  Segment bars (one per non-rest planned day) fill accent when a matching
//  synced run exists for that day.
//

import SwiftUI

struct WeekOverviewCard: View {

    let days: [PlanDay]
    let weekRuns: [Run]
    let monday: Date
    let unit: UnitSystem

    // MARK: - Computed

    private var workoutDays: [PlanDay] {
        days.filter { $0.workout.type != .rest }
    }

    private var plannedDistanceM: Double {
        workoutDays.compactMap(\.workout.target_distance_m).reduce(0, +)
    }

    private var completedDistanceM: Double {
        weekRuns.compactMap(\.distance_m).reduce(0, +)
    }

    private func isCompleted(_ day: PlanDay) -> Bool {
        weekRuns.contains { run in
            guard let runDate = DateUtils.parseISO8601(run.start_time) else { return false }
            return DateUtils.format(runDate) == day.date
        }
    }

    /// "4.2 /13.0 mi" or "0 /13.0 mi"
    private var distanceLabel: String {
        let divisor: Double = unit == .imperial ? 1609.344 : 1000.0
        let actualValue = completedDistanceM / divisor
        let actualStr = actualValue < 0.05 ? "0" : String(format: "%.1f", actualValue)
        let plannedStr = FormatUtils.distance(plannedDistanceM, unit: unit)
        return "\(actualStr) /\(plannedStr)"
    }

    // MARK: - Body

    var body: some View {
        CardView {
            VStack(spacing: Spacing.sm) {
                headerRow
                if !workoutDays.isEmpty {
                    segmentRow
                }
                statsRow
            }
        }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack {
            Text("Overview")
                .font(.cardTitle)
            Spacer()
            Text(DateUtils.weekRangeLabel(monday: monday))
                .font(.sofiaSans(size: 16, weight: .regular))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Segment Bars

    private var segmentRow: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(workoutDays) { day in
                Capsule()
                    .fill(isCompleted(day) ? AppColor.accent : Color(.systemGray5))
                    .frame(height: 4)
            }
        }
    }

    // MARK: - Stats

    private var statsRow: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text("WORKOUTS")
                    .font(.cardCaption)
                    .foregroundStyle(.secondary)
                Text("\(weekRuns.count)/\(workoutDays.count)")
                    .font(.sofiaSans(size: 14, weight: .bold))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("DISTANCE")
                    .font(.cardCaption)
                    .foregroundStyle(.secondary)
                Text(distanceLabel)
                    .font(.sofiaSans(size: 14, weight: .bold))
            }
        }
    }
}

// MARK: - Preview

#Preview("No completions") {
    let monday = DateUtils.mondayOfWeek(containing: Date())

    let days: [PlanDay] = [
        PlanDay(date: DateUtils.format(monday),
                workout: Workout(type: .easy, label: "Easy Run", description: nil,
                                 target_distance_m: 8_047, target_duration_s: nil,
                                 target_pace_s_per_km: nil, intensity: .easy, notes: nil),
                notes: nil),
        PlanDay(date: DateUtils.format(Calendar.current.date(byAdding: .day, value: 1, to: monday)!),
                workout: Workout(type: .rest, label: "Rest", description: nil,
                                 target_distance_m: nil, target_duration_s: nil,
                                 target_pace_s_per_km: nil, intensity: nil, notes: nil),
                notes: nil),
        PlanDay(date: DateUtils.format(Calendar.current.date(byAdding: .day, value: 2, to: monday)!),
                workout: Workout(type: .tempo, label: "Tempo Run", description: nil,
                                 target_distance_m: 6_437, target_duration_s: nil,
                                 target_pace_s_per_km: nil, intensity: .hard, notes: nil),
                notes: nil),
        PlanDay(date: DateUtils.format(Calendar.current.date(byAdding: .day, value: 6, to: monday)!),
                workout: Workout(type: .long_run, label: "Long Run", description: nil,
                                 target_distance_m: 16_093, target_duration_s: nil,
                                 target_pace_s_per_km: nil, intensity: .moderate, notes: nil),
                notes: nil),
    ]

    WeekOverviewCard(days: days, weekRuns: [], monday: monday, unit: .imperial)
        .padding()
}

#Preview("With completions") {
    let monday = DateUtils.mondayOfWeek(containing: Date())

    let days: [PlanDay] = [
        PlanDay(date: DateUtils.format(monday),
                workout: Workout(type: .easy, label: "Easy Run", description: nil,
                                 target_distance_m: 8_047, target_duration_s: nil,
                                 target_pace_s_per_km: nil, intensity: .easy, notes: nil),
                notes: nil),
        PlanDay(date: DateUtils.format(Calendar.current.date(byAdding: .day, value: 2, to: monday)!),
                workout: Workout(type: .tempo, label: "Tempo Run", description: nil,
                                 target_distance_m: 6_437, target_duration_s: nil,
                                 target_pace_s_per_km: nil, intensity: .hard, notes: nil),
                notes: nil),
        PlanDay(date: DateUtils.format(Calendar.current.date(byAdding: .day, value: 6, to: monday)!),
                workout: Workout(type: .long_run, label: "Long Run", description: nil,
                                 target_distance_m: 16_093, target_duration_s: nil,
                                 target_pace_s_per_km: nil, intensity: .moderate, notes: nil),
                notes: nil),
    ]

    // One completed run on Monday
    let completedRun = Run(id: "r1", provider: "strava", sport_type: "Run",
                           title: "Morning Run",
                           start_time: DateUtils.format(monday) + "T07:30:00Z",
                           distance_m: 8_200, duration_s: 2_600,
                           avg_pace_s_per_km: 317, elevation_gain_m: 45, route: nil)

    WeekOverviewCard(days: days, weekRuns: [completedRun], monday: monday, unit: .imperial)
        .padding()
}
