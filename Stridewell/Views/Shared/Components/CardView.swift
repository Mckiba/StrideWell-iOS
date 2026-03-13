//
//  CardView.swift
//  Stridewell
//
//  Reusable card container — consistent background, rounding, and padding.
//  Use `padding: 0` when wrapping views that supply their own insets (e.g. WorkoutCardView).
//

import SwiftUI

struct CardView<Content: View>: View {
    var padding: CGFloat = Spacing.md
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColor.cardSurface)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
            .shadow(color: .black.opacity(0.10), radius: 8, x: 0, y: 2)
    }
}
