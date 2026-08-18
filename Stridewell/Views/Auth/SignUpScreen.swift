//
//  SignUpScreen.swift
//  Stridewell
//

import SwiftUI

struct SignUpScreen: View {

    @Environment(\.authStore) private var authStore
    @Environment(\.apiClient) private var apiClient
    @Environment(\.onboardingStore) private var onboardingStore

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil

    @FocusState private var isFocused: Bool

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Heading
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Let's get you started!")
                    .font(.title)
                    .fontWeight(.semibold)

                Text("It's quick and easy.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, Spacing.xs)

            // Fields
            VStack(spacing: Spacing.sm) {
                IconTextField(hint: "Email Address", symbol: "envelope", value: $email)

                IconTextField(hint: "Password", symbol: "lock", isPassword: true, value: $password)

                IconTextField(hint: "Confirm Password", symbol: "lock", isPassword: true, value: $confirmPassword)
            }
            .padding(.top, Spacing.sm)

            // Error box
            if let message = errorMessage {
                errorBox(message)
            }

            // Create account button
            PrimaryButton(
                title: "Create Account",
                isEnabled: canSubmit, isLoading: isLoading, size: .large, action: { Task { await signUp() } }
            )

            Spacer()

            // Terms
            Text("By creating an account, you agree to our [Terms](https://stridewell.app/terms) and [Privacy Policy](https://stridewell.app/privacy)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.lg)
        .allowsHitTesting(!isLoading)
        .opacity(isLoading ? 0.7 : 1)
        .focused($isFocused)
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    // MARK: - Validation

    private var canSubmit: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty
    }

    // MARK: - Sign Up

    private func signUp() async {
        isLoading = true
        errorMessage = nil

        guard password == confirmPassword else {
            errorMessage = "Passwords don't match"
            isLoading = false
            return
        }

        let result: ApiResult<AuthSessionResponse> = await apiClient.register(
            email: email.trimmingCharacters(in: .whitespaces),
            password: password
        )

        switch result {
        case .failure(_, let message):
            errorMessage = message
            isLoading = false
            return
        case .success(let response):
            authStore.signIn(session: response)
        }

        // Check onboarding status — non-blocking; new users will have none
        let statusResult: ApiResult<OnboardingState> = await apiClient.onboardingStatus()
        if case .success(let state) = statusResult {
            onboardingStore.update(from: state)
        }

        isLoading = false
        // RootView observes authStore.isAuthenticated and re-routes automatically
    }

    // MARK: - Error Box

    @ViewBuilder
    private func errorBox(_ message: String) -> some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(message)
                .font(.callout)
        }
        .foregroundStyle(AppColor.destructive)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.sm)
        .background(AppColor.destructive.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
    }
}
