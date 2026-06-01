//
//  SnapCarousel.swift
//  Stridewell
//
//  Generic snap carousel — center-snaps each card with adjacent cards
//  peeking on both sides. Accepts any @ViewBuilder content.
//
//  Usage:
//    SnapCarousel(items: myItems) { item in
//        SomeCardView(item: item)
//    }
//

import SwiftUI

// MARK: - SnapCarousel

struct SnapCarousel<Item: Identifiable, Content: View>: View {

    let items: [Item]
    var cardWidth: CGFloat = 300   // matches ActivityBannerView default
    var cardHeight: CGFloat = 99   // constrains GeometryReader height
    @ViewBuilder let content: (Item) -> Content

    @State private var scrollPosition: Item.ID?

    /// 0-based index of the currently centred card.
    private var currentIndex: Int {
        guard let pos = scrollPosition else { return 0 }
        return items.firstIndex(where: { $0.id == pos }) ?? 0
    }

    var body: some View {
        VStack(spacing: Spacing.sm) {
            GeometryReader { proxy in
                // Side inset that places a cardWidth-wide card in the centre.
                // Falls back to Spacing.md so the leading card still has breathing room.
                let sideInset = max(Spacing.md, (proxy.size.width - cardWidth) / 2)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.md) {
                        ForEach(items) { item in
                            content(item)
                                .frame(width: cardWidth)
                                .id(item.id)
                        }
                    }
                    .scrollTargetLayout()
                    .padding(.horizontal, sideInset)
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $scrollPosition)
            }
            .frame(height: cardHeight)
            .onAppear {
                // Seed position so the first card is centred on appear.
                if scrollPosition == nil {
                    scrollPosition = items.first?.id
                }
            }

            if items.count > 1 {
                paginationDashes
            }
        }
        .background(.clear)
    }

    // MARK: - Pagination dashes

    private var paginationDashes: some View {
        HStack(spacing: 6) {
            ForEach(0..<items.count, id: \.self) { i in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(i == currentIndex
                          ? AppColor.textPrimary
                          : AppColor.textPrimary.opacity(0.25))
                    .frame(width: 24, height: 3)
            }
        }
    }
}

// MARK: - BannerItem

/// Distinguishes which card view a BannerItem renders as in the carousel.
enum BannerKind {
    case standard   // ActivityBannerView (plan change / activity / reflection)
    case weather    // WeatherBannerView (home/weather cards)
}

/// Convenience data model for banner-style carousel cards.
/// Not required by SnapCarousel — any Identifiable type works.
struct BannerItem: Identifiable {
    let id: String
    let title1: String
    let subtitle: String
    let image: Image
    let onTap: () -> Void
    var onDismiss: (() -> Void)? = nil
    /// Renders as WeatherBannerView when `.weather`; uses `title2` as the advice line.
    var kind: BannerKind = .standard
    var title2: String? = nil
}

// MARK: - Preview

#Preview {
    let items: [BannerItem] = [
        BannerItem(id: "a", title1: "Great work out there!", subtitle: "Let's talk about that last run", image: Image("bg2"), onTap: {}, onDismiss: {}),
        BannerItem(id: "b", title1: "Let's Review the Plan", subtitle: "Your plan has been updated", image: Image("bg1"), onTap: {}, onDismiss: {}),
        BannerItem(id: "c", title1: "Time to check In!", subtitle: "Lets check in to see how you're doing", image: Image("bg1"), onTap: {}),
    ]

    VStack {
        Spacer()
        SnapCarousel(items: items) { item in
            ActivityBannerView(
                title1:    item.title1,
                subtitle:  item.subtitle,
                image:     item.image,
                onTap:     item.onTap,
                onDismiss: item.onDismiss
            )
        }
        Spacer()
    }
    .background(Color(uiColor: .systemGroupedBackground))
}
