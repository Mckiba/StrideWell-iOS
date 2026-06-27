//
//  GuidedScreenScaffold.swift
//  Stridewell
//
//  Shared layout for the guided intake screens (S2-S6): full-bleed background,
//  oversized title, and a bottom sheet hosting the structured-input accelerators
//  (above) and the conversational surface (below).
//

import SwiftUI

struct GuidedScreenScaffold<Inputs: View>: View {

    let title: String
    var subtitle: String? = nil
    let model: IntakeChatModel
    @ViewBuilder var structuredInputs: () -> Inputs

    var body: some View {
        ZStack(alignment: .bottom) {
            OnboardingBackground()

            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.white)
                    if let subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.lg)

                Spacer(minLength: Spacing.md)

                sheet
            }
        }
        .navigationBarBackButtonHidden(true)
        .task { await model.startIfNeeded() }
    }

    private var sheet: some View {
        VStack(spacing: 0) {
            let inputs = structuredInputs()
            inputs
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.md)

            IntakeChatView(model: model)
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: UIScreen.main.bounds.height * 0.72)
        .background(AppColor.surface)
        .clipShape(
            UnevenRoundedRectangle(topLeadingRadius: 30, topTrailingRadius: 30)
        )
        .ignoresSafeArea(edges: .bottom)
    }
}
