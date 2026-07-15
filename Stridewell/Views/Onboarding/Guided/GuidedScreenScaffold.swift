//
//  GuidedScreenScaffold.swift
//  Stridewell
//
//  Shared layout for the onboarding intake screens: full-bleed background, large
//  title, and a bottom sheet holding the screen's input controls above the chat.
//

import SwiftUI

struct GuidedScreenScaffold<Inputs: View>: View {

    let title: String
    let model: IntakeChatModel
    let image: String
    @ViewBuilder var structuredInputs: () -> Inputs

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
    }

    private var sheet: some View {
        VStack(spacing: 0) {
            structuredInputs()
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.md)

            IntakeChatView(model: model)
                .padding(.bottom, Spacing.lg)

        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: UIScreen.main.bounds.height * 0.52)
        // The fill extends under the home indicator, but the content (including the
        // chat input bar) stays inside the safe area so it's always visible and rises
        // with the keyboard.
        .background {
            UnevenRoundedRectangle(topLeadingRadius: 30, topTrailingRadius: 30)
                .fill(AppColor.surface)
                .ignoresSafeArea(edges: .bottom)
        }
    }
}
