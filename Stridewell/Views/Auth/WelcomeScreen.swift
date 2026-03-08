//
//  WelcomeScreen.swift
//  Stridewell
//

import SwiftUI

struct WelcomeScreen: View {

    @State private var showSignUp = false
    @State private var showSignIn = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Brand
            VStack(spacing: Spacing.sm) {
                Text("Stridewell")
                    .font(.system(size: 42, weight: .bold))
                Text("Your AI running coach")
                    .font(.title3)
                    .foregroundStyle(AppColor.textSecondary)
            }

            Spacer()

            // Actions
            VStack(spacing: Spacing.sm) {
                Button { showSignUp = true } label: {
                    Text("Get started").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button { showSignIn = true } label: {
                    Text("Sign in").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xxl)
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $showSignUp) { SignUpScreen() }
        .navigationDestination(isPresented: $showSignIn) { SignInScreen() }
    }
}
