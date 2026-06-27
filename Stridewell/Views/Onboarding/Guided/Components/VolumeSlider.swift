//
//  VolumeSlider.swift
//  Stridewell
//
//  Weekly-volume picker for the manual baseline screen. Displays in the athlete's unit;
//  0 means "not currently running". The parent converts to km.
//

import SwiftUI

struct VolumeSlider: View {

    /// Value in the athlete's display unit (mi or km).
    @Binding var displayValue: Double
    var onCommit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Weekly volume")
                    .font(.cardTitle)
                Spacer()
                Text(valueLabel)
                    .font(.cardBody)
                    .foregroundStyle(.secondary)
            }

            Slider(value: $displayValue, in: 0...OnboardingUnits.weeklyVolumeMax, step: 1)

            HStack {
                Text("Not running")
                    .font(.cardCaption)
                    .foregroundStyle(.tertiary)
                Spacer()
                Text("\(Int(OnboardingUnits.weeklyVolumeMax)) \(OnboardingUnits.unitLabel)")
                    .font(.cardCaption)
                    .foregroundStyle(.tertiary)
            }

            PrimaryButton("Set weekly volume", size: .small, action: onCommit)
        }
    }

    private var valueLabel: String {
        displayValue < 1
            ? "Not currently running"
            : "\(Int(displayValue)) \(OnboardingUnits.unitLabel)/wk"
    }
}

#Preview {
    VolumeSlider(displayValue: .constant(25), onCommit: {})
        .padding()
}
