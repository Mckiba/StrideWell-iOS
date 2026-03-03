//
//  SignInScreen.swift
//  Stridewell
//

import SwiftUI

struct SignInScreen: View {

    @Environment(\.authStore) private var authStore
    @Environment(\.apiClient) private var apiClient
    @Environment(\.onboardingStore) private var onboardingStore

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil

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
            }

            // Error
            if let error = errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Sign in button
            Button {
                Task { await signIn() }
            } label: {
                Group {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Sign in")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(email.isEmpty || password.isEmpty || isLoading)

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
        .navigationTitle("Sign in")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Sign In

    private func signIn() async {
        isLoading = true
        errorMessage = nil

        // 1. Authenticate
        let loginResult: ApiResult<LoginResponse> = await apiClient.login(
            email: email,
            password: password
        )

        switch loginResult {
        case .failure(_, let message):
            errorMessage = message
            isLoading = false
            return
        case .success(let response):
            authStore.signIn(token: response.token, userId: response.user_id)
        }

        // 2. Check onboarding status — don't block login if this fails
        let statusResult: ApiResult<OnboardingState> = await apiClient.onboardingStatus()
        if case .success(let state) = statusResult {
            onboardingStore.update(from: state)
        }

        isLoading = false
        // RootView observes authStore + onboardingStore and re-routes automatically
    }
}
