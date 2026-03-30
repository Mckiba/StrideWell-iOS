//
//  SignInScreen.swift
//  Stridewell
//

import SwiftUI

struct SignInScreen: View {

    @Environment(\.authStore) private var authStore
    @Environment(\.apiClient) private var apiClient
    @Environment(\.onboardingStore) private var onboardingStore
    @Environment(\.dismiss) private var dismiss

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var forgotPassword: Bool = false

    @FocusState private var isFocused: Bool

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Heading
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Welcome Back")
                    .font(.largeTitle)
                    .fontWeight(.semibold)

                Text("Please sign in to continue.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, Spacing.xs)

            // Fields
            VStack(spacing: Spacing.sm) {
                IconTextField(hint: "Email Address", symbol: "envelope", value: $email)

                IconTextField(hint: "Password", symbol: "lock", isPassword: true, value: $password)
            }
            .padding(.top, Spacing.sm)

            // Forgot password
            Button("Forgot Password?") {
                forgotPassword = true
            }
            .font(.subheadline)
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .trailing)

            // Sign in button
            PrimaryButton(
                title: "Sign In",
                isEnabled: canSignIn, isLoading: isLoading, size: .large, action: { Task { await signIn() } }
            )

            // Error box
            if let message = errorMessage {
                errorBox(message)
            }

            // Sign up link
            HStack(spacing: Spacing.xs) {
                Text("Don't have an account?")
                    .foregroundStyle(.secondary)

                Button("Sign Up") {
                    dismiss()
                }
                .fontWeight(.semibold)
            }
            .font(.subheadline)
            .frame(maxWidth: .infinity)
            .padding(.top, Spacing.xs)

            Spacer()
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.lg)
        .allowsHitTesting(!isLoading)
        .opacity(isLoading ? 0.7 : 1)
        .focused($isFocused)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $forgotPassword) {
            ForgotPasswordScreen()
                .presentationDetents([.medium])
                .presentationBackground(Color(uiColor: .systemBackground))
        }
    }

    // MARK: - Validation

    private var canSignIn: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty && !password.isEmpty
    }

    // MARK: - Sign In

    private func signIn() async {
        isLoading = true
        errorMessage = nil

        let result: ApiResult<LoginResponse> = await apiClient.login(
            email: email.trimmingCharacters(in: .whitespaces),
            password: password
        )

        switch result {
        case .failure(_, let message):
            errorMessage = message
            isLoading = false
            return
        case .success(let response):
            authStore.signIn(token: response.token, userId: response.user_id)
        }

        // Check onboarding status — non-blocking
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
