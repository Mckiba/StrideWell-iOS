//
//  WelcomeScreen.swift
//  Stridewell
//

import SwiftUI

struct WelcomeScreen: View {

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Brand
            VStack(spacing: 12) {
                Text("Stridewell")
                    .font(.system(size: 42, weight: .bold))
                Text("Your AI running coach")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Actions
            VStack(spacing: 12) {
                NavigationLink(destination: SignUpScreen()) {
                    Text("Get started")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                NavigationLink(destination: SignInScreen()) {
                    Text("Sign in")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}
