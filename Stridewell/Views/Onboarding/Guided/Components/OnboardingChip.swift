//
//  OnboardingChip.swift
//  Stridewell
//
//  Selectable capsule chip used by the guided structured-input rows (goal, days,
//  speedwork). Selection styling matches PhaseChips.
//

import SwiftUI

struct OnboardingChip: View {

    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.cardCaption)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .frame(maxWidth: .infinity)
                .background(isSelected ? AppColor.accent.opacity(0.18) : AppColor.surfaceElevated)
                .foregroundStyle(isSelected ? AppColor.accent : AppColor.textPrimary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
