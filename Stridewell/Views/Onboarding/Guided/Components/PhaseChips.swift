//
//  PhaseChips.swift
//  Stridewell
//
//  Optional training-phase picker for the manual baseline screen. Maps a friendly
//  label to the value the backend expects.
//

import SwiftUI

struct PhaseChips: View {

    /// Currently selected `training_phase` enum value, if any.
    let selected: String?
    /// (enumValue, label) on tap.
    var onSelect: (String, String) -> Void

    /// (label, enum) — order mirrors the spec's chip row.
    static let options: [(label: String, value: String)] = [
        ("Base", "base"),
        ("Building up", "build"),
        ("Peaking", "peak"),
        ("Recovering", "recovery"),
        ("Coming back from injury", "return_from_injury"),
        ("No structure", "unstructured"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Training phase (optional)")
                .font(.cardCaption)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: Spacing.sm)],
                      alignment: .leading,
                      spacing: Spacing.sm) {
                ForEach(Self.options, id: \.value) { option in
                    chip(label: option.label, value: option.value)
                }
            }
        }
    }

    private func chip(label: String, value: String) -> some View {
        let isSelected = selected == value
        return Button {
            onSelect(value, label)
        } label: {
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

#Preview {
    PhaseChips(selected: "base", onSelect: { _, _ in })
        .padding()
}
