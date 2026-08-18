//
//  ActivityBannerView.swift
//  Stridewell
//

import SwiftUI

struct ActivityBannerView: View {

    let title1:    String           // bold first line (required)
    var detail:    String?  = nil   // trailing text on the title1 row, e.g. a date (optional)
    var title2:    String?  = nil   // bold second line — pass either this OR workout, not both
    var workout:   Workout? = nil   // when set, metric line (distance · pace/duration) is computed here
    let subtitle:  String?          // regular third line (required)
    var image:     Image?   = nil   // optional 60×60 thumbnail
    var onTap:     (() -> Void)? = nil   // called when the card body is tapped
    var onDismiss: (() -> Void)? = nil   // when set, renders an X button at top-trailing

    @Environment(\.settingsStore) private var settingsStore

    var body: some View {
        ZStack(alignment: .topTrailing) {
            cardContent

            // Dismiss button — only rendered when onDismiss is provided
            if let onDismiss {
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(AppColor.textPrimary.opacity(0.6))
                        .padding(6)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Card Content

    private var cardContent: some View {
        HStack(alignment: .top, spacing: Spacing.md) {

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
                        .font(.sofiaSans(size: 14, weight: .bold))
                        .foregroundStyle(AppColor.textPrimary)
                    if let detail {
                        Spacer()
                        Text(detail)
                            .font(.sofiaSans(size: 13, weight: .regular))
                            .foregroundStyle(AppColor.textPrimary)
                    }
                }

                if let line = resolvedTitle2 {
                    Text(line)
                        .font(.sofiaSans(size: 13, weight: .bold))
                        .foregroundStyle(AppColor.textPrimary)
                        .multilineTextAlignment(.leading)
                }

                if let subtitle {
                    Text(subtitle)
                        .font(.sofiaSans(size: 13, weight: .regular))
                        .foregroundStyle(AppColor.textPrimary)
                        .multilineTextAlignment(.leading)
                }
            }
        }
        .padding(Spacing.md)
        .frame(minWidth: 300, minHeight: 99, alignment: .leading)
        .background(AppColor.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
        .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
        .contentShape(Rectangle())
        .onTapGesture { onTap?() }
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
        // Prefer pace range (V2) over single pace (V1 legacy); fall back to duration when neither present.
        if let range = workout.target_pace_range {
            parts.append(FormatUtils.paceRange(min: range.min_s_per_km, max: range.max_s_per_km, unit: unit))
        } else if let p = workout.target_pace_s_per_km {
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
                title1:   "Time to check In!",
                subtitle: "Let's check in to see how you're doing.",
                image:    Image("bg1")
            )

            // All fields
            ActivityBannerView(
                title1:   "Easy Run",
                detail:   "Monday, Feb 23",
                title2:   "6 Miles",
                subtitle: "Let's talk about that last workout",
                image:    Image("bg2")
            )

            // Activity banner with callbacks
            ActivityBannerView(
                title1:    "Great work out there!",
                subtitle:  "Let's talk about that last run",
                image:     Image("bg2"),
                onTap:     { },
                onDismiss: { }
            )
            
            //Weather layour
            ActivityBannerView(
                title1:    "UV index is 7",
                title2:   "Cover Up, wear SPF and stay hydrated!",
                subtitle: "",
                image:     Image("bg2"),
                onTap:     { },
                onDismiss: { }
            )

            ActivityBannerView(
                title1:   "Lets Review the Plan",
                subtitle: "Let's discuss some changes to your plan based on the last runs you've done/reflection you've submitted ",
                image:    Image("bg2")
            )
        }
        .padding(Spacing.md)
    }
    .background(Color(uiColor: .systemGroupedBackground))
}
