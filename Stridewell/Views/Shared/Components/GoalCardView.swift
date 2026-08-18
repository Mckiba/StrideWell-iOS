//
//  GoalCardView.swift
//  Stridewell
//
//  Goal Card — shows the user's training goal, race date, week progress,
//  and total miles run since plan start.
//


import SwiftUI

struct GoalCardView: View {

    let summary: GoalSummary

    @Environment(\.settingsStore) private var settingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {

            // Row 1: Goal name
            Text(summary.goalName)
                .font(.sofiaSans(size: 24, weight: .bold))
                .foregroundStyle(AppColor.textPrimary)

            // Row 2: Race date (optional)
            if let raceDate = summary.formattedRaceDate {
                Text(raceDate)
                    .font(.sofiaSans(size: 18, weight: .regular))
                    .foregroundStyle(AppColor.textSecondary)
            }

            // Row 3: Week progress bar
            progressBar
                .padding(.vertical, Spacing.xs)

            // Rows 4 + 5: Stats grid
            HStack(alignment: .top) {
                // Weeks completed
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Weeks Completed")
                        .font(.sofiaSans(size: 12, weight: .regular))
                        .foregroundStyle(AppColor.textSecondary)
                    Text("\(summary.weeksCompleted)/\(summary.totalWeeks)")
                        .font(.sofiaSans(size: 20, weight: .bold))
                        .foregroundStyle(AppColor.textPrimary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: Spacing.xs) {
                    Text("Distance Completed")
                        .font(.sofiaSans(size: 12, weight: .regular))
                        .foregroundStyle(AppColor.textSecondary)
                    Text(FormatUtils.distance(summary.distance_completed_m, unit: settingsStore.unitSystem))
                        .font(.sofiaSans(size: 20, weight: .bold))
                        .foregroundStyle(AppColor.textPrimary)
                }
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.input))
        .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 4)
    }

    // MARK: - Segmented Progress Bar
    // One rounded pill per week — filled pills = weeks completed.

    private var progressBar: some View {
        HStack(spacing: 4) {
            ForEach(0..<max(summary.totalWeeks, 1), id: \.self) { index in
                RoundedRectangle(cornerRadius: 4)
                    .fill(index < summary.weeksCompleted ? AppColor.accent : AppColor.progressTrackEmpty)
                    .frame(height: 8)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let summary = GoalSummary(
        goal_type: "race",
        goal_race_date: "2026-10-04",
        goal_race_distance_m: 21097.5,
        goal_race_distance_label: "Half marathon",
        plan_start_date: "2026-08-03",
        horizon_days: 63,
        weeks_elapsed: 4,
        weeks_remaining: 5,
        runs_completed: 18,
        runs_planned_to_date: 21,
        distance_completed_m: 134000
    )
    let noRaceGoal = GoalSummary(
        goal_type: "fitness",
        goal_race_date: nil,
        goal_race_distance_m: nil,
        goal_race_distance_label: nil,
        plan_start_date: "2026-08-03",
        horizon_days: 42,
        weeks_elapsed: 2,
        weeks_remaining: 4,
        runs_completed: 10,
        runs_planned_to_date: 12,
        distance_completed_m: 128748
    )

    return ScrollView {
        VStack(spacing: Spacing.md) {
            GoalCardView(summary: summary)
            GoalCardView(summary: noRaceGoal)
        }
        .padding(Spacing.md)
    }
    .background(Color(uiColor: .systemGroupedBackground))
}
