//
//  ActivityBannerView.swift
//  Stridewell
//

import SwiftUI

struct ActivityBannerView: View {

    let title1:   String        // bold first line (required)
    var detail:   String? = nil // trailing text on the title1 row, e.g. a date (optional)
    var title2:   String? = nil // bold second line (optional)
    let subtitle: String?        // regular third line (required)
    var image:    Image? = nil  // optional 60×60 thumbnail

    var body: some View {
        HStack( spacing: Spacing.md) {

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

                // title1 row — detail pushed to trailing edge when present
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

                if let title2 {
                    Text(title2)
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
        .frame(minWidth: 277)
        // No maxWidth: .infinity — card hugs its content width
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
        .shadow(color: Color.black.opacity(0.25), radius: 30, x: 0, y: 4)
        .environment(\.colorScheme, .light)
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
