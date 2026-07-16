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

                // Distance completed
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
        goal_race_date: "2026-10-04",
        goal_race_distance_m: 21097.5,
        plan_start_date: "2026-08-03",
        horizon_days: 63,
        distance_completed_m: 459027.8
    )
    let noRaceGoal = GoalSummary(
        goal_race_date: nil,
        goal_race_distance_m: nil,
        plan_start_date: "2026-08-03",
        horizon_days: 42,
        distance_completed_m: 128748.0
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
