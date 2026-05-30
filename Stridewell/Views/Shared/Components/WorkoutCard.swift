//
//  WorkoutCard.swift
//  Stridewell
//
//
//    • Planned/Rest (default) — compact stacked layout,
//    • Completed/Modified — route thumbnail + planned stats on top, divider,
//      actual stats from `day.linkedRun` underneath, accent-blue bottom stroke.
//    • Missed — Greyed out planned layout.

import SwiftUI

struct WorkoutCard: View {

    let day: PlanDay
    var isToday: Bool = false

    @Environment(\.settingsStore) private var settingsStore

    var body: some View {
        cardContent
            .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.xs)
            .background(AppColor.cardSurface)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
            .cardBottomStroke(strokeColor)
            .shadow(color: .black.opacity(0.10), radius: 8, x: 0, y: 2)
    }

    // MARK: - Variant routing

    @ViewBuilder
    private var cardContent: some View {
        switch effectiveStatus {
        case .completed, .modified:
            // Backend contract: a completed/modified day always carries linkedRun.
            // If somehow nil (backend regression), defensively fall back to the
            // planned layout so the screen never crashes.
            if let run = day.linkedRun {
                completedLayout(run: run)
            } else {
                plannedLayout(textColor: AppColor.textPrimary)
            }
        case .missed:
            plannedLayout(textColor: AppColor.textMissed)
        case .planned, .rest:
            plannedLayout(textColor: AppColor.textPrimary)
        }
    }

    // MARK: - Planned / Missed layout (also fallback for rest)

    private func plannedLayout(textColor: Color) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .center) {
                Text(day.workout.label)
                    .font(.activityName)
                    .foregroundStyle(textColor)
                Spacer()
                Text(cardDate)
                    .font(.activityTimestamp)
                    .foregroundStyle(textColor)
            }

            if !isRest {
                HStack(spacing: Spacing.lg) {
                    CardStat(label: "DISTANCE",    value: distanceValue, color: textColor)
                    Spacer()
                    CardStat(label: "TIME",        value: timeValue, color: textColor)
                    Spacer()
                    CardStat(label: "TARGET PACE", value: paceValue, color: textColor)
                }
            }

            if let notes = notesLine {
                Text(notes)
                    .font(.activityStatLabel)
                    .foregroundStyle(textColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Completed / Modified layout

    private func completedLayout(run: Run) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .top, spacing: Spacing.sm) {
                RouteThumbnailView(run: run, size: CGSize(width: 55, height: 55))
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack(alignment: .center) {
                        Text(day.workout.label)
                            .font(.activityName)
                            .foregroundStyle(AppColor.textPrimary)
                        Spacer()
                        Text(cardDate)
                            .font(.activityTimestamp)
                            .foregroundStyle(AppColor.textPrimary)
                    }

                    HStack(spacing: Spacing.lg) {
                        CardStat(label: "DISTANCE",    value: distanceValue)
                        Spacer()
                        CardStat(label: "TIME",        value: timeValue)
                        Spacer()
                        CardStat(label: "TARGET PACE", value: paceValue)
                    }

                    if let notes = notesLine {
                        Text(notes)
                            .font(.activityStatLabel)
                            .foregroundStyle(AppColor.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            Rectangle()
                .fill(AppColor.textSecondary).opacity(0.10)
                .frame(height: 1)
            
            
          
            // Actual run stats — what the athlete did
            HStack(spacing: Spacing.lg) {
                CardStat(label: "DISTANCE", value: actualDistance(run))
                Spacer()
                CardStat(label: "TIME",     value: actualTime(run))
                Spacer()
                CardStat(label: "AVG PACE", value: actualPace(run))
            }
        }
    }

    // MARK: - State derivation

    private var effectiveStatus: PlanDay.Status {
        // Rest workouts always render as .rest regardless of any DB-reported
        // status (e.g. `modified` because the athlete ran on a rest day is
        // surfaced via the stroke colour route choice below, not here — see
        // `strokeColor`).
        if day.workout.type == .rest { return .rest }
        return day.status ?? .planned
    }

    private var strokeColor: Color {
        switch effectiveStatus {
        case .completed, .modified: return AppColor.cardBorderCompleted
        case .missed:               return AppColor.cardBorderMissed
        case .planned, .rest:       return AppColor.surface
        }
    }

    private var isRest: Bool {
        day.workout.type == .rest || day.workout.type == .recovery
    }

    // MARK: - Planned-side computed values

    private var distanceValue: String {
        guard let d = day.workout.target_distance_m else { return "-" }
        return FormatUtils.distance(d, unit: settingsStore.unitSystem)
    }

    private var timeValue: String {
        guard let dur = day.workout.target_duration_s else { return "-" }
        return FormatUtils.duration(dur)
    }

    private var paceValue: String {
        let unit = settingsStore.unitSystem
        if let range = day.workout.target_pace_range {
            return FormatUtils.paceRange(min: range.min_s_per_km, max: range.max_s_per_km, unit: unit)
        }
        guard let p = day.workout.target_pace_s_per_km else { return "-" }
        return FormatUtils.pace(p, unit: unit)
    }

    private var notesLine: String? {
        day.workout.notes ?? day.workout.description
    }

    private var cardDate: String {
        guard let d = DateUtils.parse(day.date) else { return "" }
        return DateUtils.workoutCardDateFormatter.string(from: d)
    }

    // MARK: - Actual-side computed values (from linkedRun)

    private func actualDistance(_ run: Run) -> String {
        FormatUtils.distance(run.distance_m, unit: settingsStore.unitSystem)
    }

    private func actualTime(_ run: Run) -> String {
        FormatUtils.duration(run.duration_s)
    }

    private func actualPace(_ run: Run) -> String {
        guard let pace = run.avg_pace_s_per_km else { return "—" }
        return FormatUtils.pace(pace, unit: settingsStore.unitSystem)
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
        notes: nil,
        status: .planned
    )
    let completedRun = Run(
        id: "run_done",
        provider: "strava",
        sport_type: "Run",
        title: "Lake Loop",
        start_time: "2026-03-08T15:30:00Z",
        distance_m: 5050,
        duration_s: 1620,
        avg_pace_s_per_km: 321,
        elevation_gain_m: 12,
        route: RunRoute(summary_polyline: "o}mlHlariVoBiC{A{B_BaCuBeDyF_Jw@yAeAuBmAaCkBuDeBkDoAsB}@cBqAeCqBiEiBkD{BkEaC_FuAgC")
    )
    let completed = PlanDay(
        date: "2026-03-08",
        workout: Workout(
            type: .easy,
            label: "Easy Run",
            description: "Flat route is ideal",
            target_distance_m: 5000,
            target_duration_s: 1500,
            target_pace_s_per_km: 300,
            intensity: .easy,
            notes: "Try to keep hr below 150bpm"
        ),
        notes: nil,
        status: .completed,
        runId: "run_done",
        linkedRun: completedRun
    )
    let missed = PlanDay(
        date: "2026-03-07",
        workout: Workout(
            type: .easy,
            label: "Easy Run",
            description: "Flat route is ideal",
            target_distance_m: 5000,
            target_duration_s: 1500,
            target_pace_s_per_km: 300,
            intensity: .easy,
            notes: "Try to keep hr below 150bpm"
        ),
        notes: nil,
        status: .missed
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
        notes: nil,
        status: .rest
    )

    ScrollView {
        VStack(spacing: 12) {
            WorkoutCard(day: easy, isToday: true)
            WorkoutCard(day: completed)
            WorkoutCard(day: missed)
            WorkoutCard(day: rest)
        }
        .padding()
    }
    .background(Color(uiColor: .systemGroupedBackground))
}
