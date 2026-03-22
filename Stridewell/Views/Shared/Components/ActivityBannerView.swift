//
//  ActivityBannerView.swift
//  Stridewell
//

import SwiftUI

struct ActivityBannerView: View {

    let title1:   String           // bold first line (required)
    var detail:   String?  = nil   // trailing text on the title1 row, e.g. a date (optional)
    var title2:   String?  = nil   // bold second line — pass either this OR workout, not both
    var workout:  Workout? = nil   // when set, metric line (distance · pace/duration) is computed here
    let subtitle: String?          // regular third line (required)
    var image:    Image?   = nil   // optional 60×60 thumbnail

    @Environment(\.settingsStore) private var settingsStore

    var body: some View {
        HStack(spacing: Spacing.md) {

            // Thumbnail — only rendered when an image is provided
            if let image {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
            }

            // Text column
            VStack(alignment: .leading, spacing: Spacing.sm) {

                HStack {
                    Text(title1)
                        .font(.sofiaSans(size: 12, weight: .bold))
                        .foregroundStyle(AppColor.textPrimary)
                    if let detail {
                        Spacer()
                        Text(detail)
                            .font(.sofiaSans(size: 12, weight: .regular))
                            .foregroundStyle(AppColor.textPrimary)
                    }
                }

                if let line = resolvedTitle2 {
                    Text(line)
                        .font(.sofiaSans(size: 12, weight: .bold))
                        .foregroundStyle(AppColor.textPrimary)
                        .multilineTextAlignment(.center)
                }

                if let subtitle{
                    Text(subtitle)
                        .font(.sofiaSans(size: 12, weight: .regular))
                        .foregroundStyle(AppColor.textPrimary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
        .shadow(color: Color.black.opacity(0.25), radius: 30, x: 0, y: 4)
    }

    // MARK: - Computed

    /// Returns `title2` if set directly, otherwise derives the metric line from `workout`.
    private var resolvedTitle2: String? {
        if let title2 { return title2 }
        return metricLine
    }

    /// Builds "distance · pace" or "distance · duration" from the workout targets,
    /// formatted for the user's current unit system.
    private var metricLine: String? {
        guard let workout else { return nil }
        let unit = settingsStore.unitSystem
        var parts: [String] = []
        if let d = workout.target_distance_m {
            parts.append(FormatUtils.distance(d, unit: unit))
        }
        if let p = workout.target_pace_s_per_km {
            parts.append(FormatUtils.pace(p, unit: unit))
        } else if let dur = workout.target_duration_s {
            parts.append(FormatUtils.duration(dur))
        }
        return parts.isEmpty ? nil : parts.joined(separator: "  ·  ")
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: Spacing.md) {

            // title1 only + subtitle
            ActivityBannerView(
                title1:   "Daily Check-in",
                subtitle: "How are you feeling today?"
            )

            // title1 + detail (date) + subtitle — expands to full width
            ActivityBannerView(
                title1:   "Great Workout!",
                detail:   "March 7",
                subtitle: "Let's talk about that last workout"
            )

            // All fields
            ActivityBannerView(
                title1:   "Easy Run",
                detail:   "Monday, Feb 23",
                title2:   "Keep it up!",
                subtitle: "Let's talk about that last workout",
                image:    Image("bg2")
            )
        }
        .padding(Spacing.md)
    }
    .background(Color(uiColor: .systemGroupedBackground))
}
