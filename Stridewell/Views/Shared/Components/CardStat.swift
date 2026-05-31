//
//  CardStat.swift
//  Stridewell
//
//  Shared stat subview used by ActivityCard and WorkoutCard.
//

import SwiftUI

struct CardStat: View {
    let label: String
    let value: String
    /// When non-nil, both label and value render in this colour — used by the
    /// Missed plan-day card variant to grey out the whole stat in one go.
    /// Default nil preserves the existing two-tier rendering (secondary
    /// label, primary value).
    var color: Color? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.activityStatLabel)
                .foregroundStyle(color ?? AppColor.textSecondary)
                .lineLimit(1)
            Text(value)
                .font(.activityStatValue)
                .foregroundStyle(color ?? AppColor.textPrimary)
                .lineLimit(1)
        }
    }
}


struct ActivityStat: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.largeStatValue)
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(1)
            Text(label)
                .font(.activityTimestamp)
                .foregroundStyle(AppColor.textSecondary)
                .lineLimit(1)
        }
    }
}
