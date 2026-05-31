//
//  ActivityCard.swift
//  Stridewell
//
//  Displays a single completed run with a route thumbnail, timestamp,
//  run name, and key stats (distance, time, avg pace).
//

import SwiftUI

struct ActivityCard: View {

    let run: Run

    @Environment(\.settingsStore) private var settingsStore

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.xl2) {
            RouteThumbnailView(run: run)
            VStack(alignment: .leading, spacing: Spacing.xs) {
                timestampRow
                Text(run.title ?? run.sport_type.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.activityName)
                    .foregroundStyle(AppColor.textPrimary)
                statsRow
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.xs)
        .background(AppColor.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        // Only plan-linked runs get the accent stroke. Historical runs,
        // cross-training, and anything outside the active plan render plain.
//        .modifier(PlanLinkedStrokeModifier(isPlanLinked: run.plan_day_date != nil))
        .shadow(color: .black.opacity(0.10), radius: 8, x: 0, y: 2)
    }

    private var timestampRow: some View {
        HStack {
            Text(DateUtils.activityDate(run.start_time))
            Spacer()
            Text(DateUtils.activityTime(run.start_time))
        }
        .font(.activityTimestamp)
        .textCase(.uppercase)
        .foregroundStyle(AppColor.textPrimary)
    }

    private var statsRow: some View {
        let unit = settingsStore.unitSystem
        return HStack(spacing: Spacing.lg) {
            CardStat(label: "DISTANCE", value: FormatUtils.distance(run.distance_m, unit: unit))
            Spacer()

            CardStat(label: "TIME",     value: FormatUtils.duration(run.duration_s))
            Spacer()

            CardStat(label: "AVG PACE", value: run.avg_pace_s_per_km.map { FormatUtils.pace($0, unit: unit) } ?? "—")
        }
    }
}

// MARK: - Preview

#Preview {
    let unlinked = Run(
        id: "1",
        provider: "strava",
        sport_type: "Run",
        title: "Seattle Running",
        start_time: "2025-02-18T18:16:00Z",
        distance_m: 4_850,
        duration_s: 1_568,
        avg_pace_s_per_km: 323,
        elevation_gain_m: 42,
        route: RunRoute(summary_polyline: "o}mlHlariVoBiC{A{B_BaCuBeDyF_Jw@yAeAuBmAaCkBuDeBkDoAsB}@cBqAeCqBiEiBkD{BkEaC_FuAgC"),
        plan_day_date: nil
    )
    let linked = Run(
        id: "2",
        provider: "strava",
        sport_type: "Run",
        title: "Long Run",
        start_time: "2025-02-19T08:00:00Z",
        distance_m: 20_100,
        duration_s: 7_200,
        avg_pace_s_per_km: 358,
        elevation_gain_m: 180,
        route: RunRoute(summary_polyline: "o}mlHlariVoBiC{A{B_BaCuBeDyF_Jw@yAeAuBmAaCkBuDeBkDoAsB}@cBqAeCqBiEiBkD{BkEaC_FuAgC"),
        plan_day_date: "2025-02-19"
    )
    VStack(spacing: 12) {
        ActivityCard(run: unlinked)  // no stroke — historical run
        ActivityCard(run: linked)    // accent stroke — completed plan day
    }
    .padding()
}
