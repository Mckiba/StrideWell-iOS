//
//  GuidedScreenScaffold.swift
//  Stridewell
//
//  Shared layout for the onboarding intake screens: full-bleed background, large
//  title, and a bottom sheet holding the screen's input controls above the chat.
//  The sheet has a grab handle and can be dragged between a collapsed and an
//  expanded height, snapping to whichever is nearer on release.
//

import SwiftUI

struct GuidedScreenScaffold<Inputs: View>: View {

    let title: String
    let model: IntakeChatModel
    let image: String
    @ViewBuilder var structuredInputs: () -> Inputs

    /// Resting heights of the sheet, as fractions of the screen height.
    private let collapsedFraction: CGFloat = 0.52
    private let expandedFraction: CGFloat = 0.9

    @State private var expanded = false
    /// Live finger delta during a drag (0 at rest). Positive = dragging down.
    @State private var dragOffset: CGFloat = 0

    private var screenHeight: CGFloat { UIScreen.main.bounds.height }
    private var collapsedHeight: CGFloat { screenHeight * collapsedFraction }
    private var expandedHeight: CGFloat { screenHeight * expandedFraction }
    private var restingHeight: CGFloat { expanded ? expandedHeight : collapsedHeight }

    /// Live sheet height: the resting height offset by the in-progress drag, clamped
    /// between the two detents. Dragging up (negative offset) makes it taller.
    private var sheetHeight: CGFloat {
        min(max(restingHeight - dragOffset, collapsedHeight), expandedHeight)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            OnboardingBackground(image: image)

            VStack(alignment: .center, spacing: 0) {
                Text(title)
                    .font(.system(size: 50, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.lg)

                Spacer(minLength: Spacing.md)

                sheet
            }
        }
        // The navigation stack's back button is left visible so the athlete can return
        // to an earlier screen; re-answering simply overwrites the earlier value.
        .task { await model.startIfNeeded() }
        // Expand as soon as the athlete acts on the sheet — a sent turn (tapping a
        // control or the send button) doesn't fit at the collapsed height alongside
        // the coach's reply and the controls.
        .onChange(of: model.phase) { _, phase in
            if phase == .waiting { expand() }
        }
    }

    private var sheet: some View {
        VStack(spacing: 0) {
            grabHandle
                .contentShape(Rectangle())
                .gesture(dragGesture)

            structuredInputs()
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.sm)

            IntakeChatView(model: model, onInteract: expand)
                .padding(.bottom, Spacing.lg)
        }
        .frame(maxWidth: .infinity)
        .frame(height: sheetHeight)
        // The fill extends under the home indicator, but the content (including the
        // chat input bar) stays inside the safe area so it's always visible and rises
        // with the keyboard.
        .background {
            UnevenRoundedRectangle(topLeadingRadius: 30, topTrailingRadius: 30)
                .fill(AppColor.surface)
                .ignoresSafeArea(edges: .bottom)
        }
    }

    private var grabHandle: some View {
        Capsule()
            .fill(Color(.systemGray3))
            .frame(width: 40, height: 5)
            .frame(maxWidth: .infinity)
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.xs)
    }

    /// Drag on the handle to resize; on release, snap to the nearer detent — or the
    /// flick direction when the gesture ends with momentum. Measured in the global
    /// coordinate space so resizing the sheet (which moves the handle under the
    /// finger) doesn't feed back into the translation and cause jitter. The offset is
    /// tracked (not `@GestureState`) so the release resets it and flips the detent in
    /// one animation transaction — a single smooth interpolation rather than two
    /// competing springs.
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 1, coordinateSpace: .global)
            .onChanged { value in
                dragOffset = value.translation.height
            }
            .onEnded { value in
                let releasedHeight = restingHeight - value.translation.height
                let flick = value.predictedEndTranslation.height
                let shouldExpand: Bool
                if flick < -80 {
                    shouldExpand = true
                } else if flick > 80 {
                    shouldExpand = false
                } else {
                    shouldExpand = releasedHeight > (collapsedHeight + expandedHeight) / 2
                }
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    expanded = shouldExpand
                    dragOffset = 0
                }
            }
    }

    private func expand() {
        guard !expanded else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            expanded = true
        }
    }
}
