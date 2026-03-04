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

    private var passwordsMatch: Bool { password == confirmPassword }
    private var canSubmit: Bool {
        !email.isEmpty && !password.isEmpty && !confirmPassword.isEmpty
            && passwordsMatch && !isLoading
    }

    var body: some View {
        VStack(spacing: 24) {
            // Fields
            VStack(spacing: 14) {
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)

                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)

                SecureField("Confirm password", text: $confirmPassword)
                    .textFieldStyle(.roundedBorder)
            }

            // Validation hint
            if !confirmPassword.isEmpty && !passwordsMatch {
                Text("Passwords don't match")
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // API error
            if let error = errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Submit
            Button {
                Task { await signUp() }
            } label: {
                Group {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Create account")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!canSubmit)

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
        .navigationTitle("Create account")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Registration

    private func signUp() async {
        isLoading = true
        errorMessage = nil

        // 1. Register
        let result: ApiResult<LoginResponse> = await apiClient.register(
            email: email,
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

        // 2. Check onboarding status — non-blocking; new users will have none
        let statusResult: ApiResult<OnboardingState> = await apiClient.onboardingStatus()
        if case .success(let state) = statusResult {
            onboardingStore.update(from: state)
        }

        isLoading = false
        // RootView observes authStore.isAuthenticated and re-routes automatically
    }
}
