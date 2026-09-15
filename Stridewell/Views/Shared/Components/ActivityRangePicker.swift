//
//  ActivityRangePicker.swift
//  Stridewell
//
//  Capsule W / M / Y / All selector for the Activities overview. The selected
//  segment gets an accent pill that slides between options.
//

import SwiftUI

struct ActivityRangePicker: View {

    @Binding var selection: ActivityRange

    @Namespace private var pillNamespace

    private let segmentWidth: CGFloat = 50

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(ActivityRange.allCases.enumerated()), id: \.element) { index, range in
                if index > 0 {
                    Spacer(minLength: 0)
                }
                segment(range)
            }
        }
        .padding(0.5)
        .frame(height: 30)
        .background(AppColor.cardSurface, in: Capsule())
        .overlay(Capsule().strokeBorder(AppColor.textPrimary.opacity(0.1), lineWidth: 0.5))
        .sensoryFeedback(.selection, trigger: selection)
    }

    private func segment(_ range: ActivityRange) -> some View {
        let isSelected = range == selection
        return Button {
            withAnimation(.snappy(duration: 0.25)) { selection = range }
        } label: {
            Text(range.shortLabel)
                .font(.activityRangeLabel)
                .foregroundStyle(AppColor.textPrimary)
                .frame(width: segmentWidth)
                .frame(maxHeight: .infinity)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(AppColor.accent)
                            .matchedGeometryEffect(id: "pill", in: pillNamespace)
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(range.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    @Previewable @State var range: ActivityRange = .week
    ActivityRangePicker(selection: $range)
        .padding()
}
