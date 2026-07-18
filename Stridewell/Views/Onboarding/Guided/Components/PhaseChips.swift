//
//  PhaseChips.swift
//  Stridewell
//
//  Optional training-phase picker for the manual baseline screen. Maps a friendly
//  label to the value the backend expects.
//

import SwiftUI

// MARK: - FlowLayout

/// Lays subviews out left-to-right, wrapping to a new line when the current line
/// runs out of horizontal space.
struct FlowLayout: Layout {

    var horizontalSpacing: CGFloat
    var verticalSpacing: CGFloat

    private struct Line {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func lines(maxWidth: CGFloat, sizes: [CGSize]) -> [Line] {
        var result: [Line] = []
        var current = Line()

        for (index, size) in sizes.enumerated() {
            let projectedWidth = current.indices.isEmpty
                ? size.width
                : current.width + horizontalSpacing + size.width

            if !current.indices.isEmpty && projectedWidth > maxWidth {
                result.append(current)
                current = Line(indices: [index], width: size.width, height: size.height)
            } else {
                current.indices.append(index)
                current.width = projectedWidth
                current.height = max(current.height, size.height)
            }
        }

        if !current.indices.isEmpty { result.append(current) }
        return result
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let maxWidth = proposal.width ?? .infinity
        let lines = lines(maxWidth: maxWidth, sizes: sizes)

        let height = lines.reduce(0) { $0 + $1.height }
            + verticalSpacing * CGFloat(max(0, lines.count - 1))
        let width = proposal.width ?? (lines.map(\.width).max() ?? 0)

        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let lines = lines(maxWidth: bounds.width, sizes: sizes)

        var y = bounds.minY
        for line in lines {
            var x = bounds.minX
            for index in line.indices {
                subviews[index].place(
                    at: CGPoint(x: x, y: y),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(sizes[index])
                )
                x += sizes[index].width + horizontalSpacing
            }
            y += line.height + verticalSpacing
        }
    }
}

// MARK: - PhaseChips

struct PhaseChips: View {

    /// Currently selected `training_phase` enum value, if any.
    let selected: String?
    /// (enumValue, label) on tap.
    var onSelect: (String, String) -> Void

    /// Uniform chip height.
    private static let chipHeight: CGFloat = 40

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

            FlowLayout(horizontalSpacing: Spacing.sm, verticalSpacing: Spacing.sm) {
                ForEach(Self.options, id: \.value) { option in
                    chip(label: option.label, value: option.value)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func chip(label: String, value: String) -> some View {
        let isSelected = selected == value
        return Button {
            onSelect(value, label)
        } label: {
            Text(label)
                .font(.cardCaption)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, Spacing.md)
                .frame(height: Self.chipHeight)
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
