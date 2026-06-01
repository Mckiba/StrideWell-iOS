//
//  WeatherBannerView.swift
//  Stridewell
//
//  Weather/home card. Renders a bold
//  headline (title1), a bold advice line (title2), and a themed thumbnail.
//

import SwiftUI

struct WeatherBannerView: View {

    let title1: String          // bold headline, e.g. "High UV (10)"
    let title2: String          // advice line, e.g. "Wear sunscreen."
    var image: Image? = nil     // themed 60×60 thumbnail
    var onTap: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {

            if let image {
                image
                    .renderingMode(.template)   // tint the glyph: black (light) / white (dark)
                    .resizable()
                    .scaledToFit()              // fit vector icons whole, no cropping
                    .frame(width: 60, height: 60)
                    .foregroundStyle(AppColor.textPrimary)
            }

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(title1)
                    .font(.sofiaSans(size: 14, weight: .bold))
                    .foregroundStyle(AppColor.textPrimary)

                if !title2.isEmpty {
                    Text(title2)
                        .font(.sofiaSans(size: 13, weight: .bold))
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
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: Spacing.md) {
            WeatherBannerView(
                title1: "High UV (10)",
                title2: "Wear sunscreen.",
                image:  Image("bg2"),
                onTap:  { }
            )
            WeatherBannerView(
                title1: "Severe Thunderstorm Warning",
                title2: "Tap to learn more.",
                image:  Image("bg2"),
                onTap:  { }
            )
            WeatherBannerView(
                title1: "Sunset at 8:14 PM",
                title2: "Bring a headlamp.",
                image:  Image("bg1")
            )
        }
        .padding(Spacing.md)
    }
    .background(Color(uiColor: .systemGroupedBackground))
}
