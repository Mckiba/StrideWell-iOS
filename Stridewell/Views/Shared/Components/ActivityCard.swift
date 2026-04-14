//
//  ActivityCard.swift
//  Stridewell
//
//  Displays a single completed run with a route thumbnail, timestamp,
//  run name, and key stats (distance, time, avg pace).
//

import SwiftUI
import CoreLocation

struct ActivityCard: View {

    let run: Run

    @Environment(\.settingsStore) private var settingsStore
    @State private var routeCoordinates: [CLLocationCoordinate2D] = []

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.xl2) {
            routeThumbnail
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
        .shadow(color: .black.opacity(0.10), radius: 8, x: 0, y: 2)
        .task {
            if let encoded = run.route?.summary_polyline, !encoded.isEmpty {
                routeCoordinates = await Task.detached(priority: .utility) {
                    await PolylineDecoder.decode(encoded)
                }.value
            }
        }
    }

    // MARK: - Route Thumbnail

    private var routeThumbnail: some View {
        Group {
            if routeCoordinates.count > 1 {
                RoutePathShape(coordinates: routeCoordinates)
                    .stroke(AppColor.accent, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
            } else {
                // Placeholder shown while decoding or when no polyline is available.
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .stroke(AppColor.textTertiary, lineWidth: 1)
            }
        }
        .frame(width: 32, height: 34)
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
    let sample = Run(
        id: "1",
        provider: "strava",
        sport_type: "Run",
        title: "Seattle Running" as String?,
        start_time: "2025-02-18T18:16:00Z",
        distance_m: 4_850,
        duration_s: 1_568,
        avg_pace_s_per_km: 323,
        elevation_gain_m: 42,
        route: RunRoute(summary_polyline: "o}mlHlariVoBiC{A{B_BaCuBeDyF_Jw@yAeAuBmAaCkBuDeBkDoAsB}@cBqAeCqBiEiBkD{BkEaC_FuAgC")
    )
    ActivityCard(run: sample)
        .padding()
}
