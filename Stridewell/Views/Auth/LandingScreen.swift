//
//  LandingScreen.swift
//  Stridewell
//
//  Entry point for unauthenticated users. Static dark-gradient background,
//  Stridewell branding, and three auth paths: Apple, Google, and email.
//


import CryptoKit
import GoogleSignIn
import SwiftUI

struct LandingScreen: View {

    // MARK: - Environment

    @Environment(\.authStore) private var authStore
    @Environment(\.apiClient) private var apiClient
    @Environment(\.onboardingStore) private var onboardingStore

    // MARK: - State

    @State private var navigationPath = NavigationPath()
    @State private var showSignUp = false
    @State private var isLoadingApple = false
    @State private var isLoadingGoogle = false
    @State private var errorMessage: String? = nil
    @State private var appleSignInHandler = AppleSignInHandler()

    // MARK: - Body

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                // Static dark gradient — no animation
                LinearGradient(
                    colors: [Color(hex: "#0D1117"), Color.black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    // Branding
                    VStack(spacing: Spacing.sm) {
                        Text("Stridewell")
                            .font(.system(size: 42, weight: .bold))
                            .foregroundStyle(.white)

                        Text("Your AI running coach")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.7))
                    }

                    Spacer()

                    // Auth buttons
                    VStack(spacing: Spacing.md) {
                        PrimaryButton(
                            title: "Continue with Apple",
                            icon: .system("applelogo"),
                            isEnabled: !isLoadingApple && !isLoadingGoogle,
                            isLoading: isLoadingApple,
                            size: .large,
                            backgroundColor: .white,
                            foregroundColor: .black,
                            action: { Task { await handleAppleSignIn() } }
                        )

                        PrimaryButton(
                            title: "Continue with Google",
                            icon: .asset("Google"),
                            isEnabled: !isLoadingApple && !isLoadingGoogle,
                            isLoading: isLoadingGoogle,
                            size: .large,
                            backgroundColor: Color(uiColor: .secondarySystemBackground),
                            foregroundColor: Color(uiColor: .label),
                            action: { Task { await handleGoogleSignIn() } }
                        )

                        PrimaryButton("Sign up with Email",
                                      icon: .system("envelope.fill"),
                                      backgroundColor: AppColor.accent,
                                      foregroundColor: .white) {
                            showSignUp = true
                        }
                        .disabled(isLoadingApple || isLoadingGoogle)
                    }

                    // Error message
                    if let message = errorMessage {
                        Text(message)
                            .font(.subheadline)
                            .foregroundStyle(AppColor.destructive)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Spacing.lg)
                            .padding(.top, Spacing.sm)
                    }

                    // Sign-in link
                    Button {
                        navigationPath.append("signin")
                    } label: {
                        Text("Already have an account? **Log in**")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                    }
                    .padding(.top, Spacing.sm)
                    .disabled(isLoadingApple || isLoadingGoogle)

                    // Terms
                    Text("By continuing, you agree to our [Terms](https://stridewell.app/terms) and [Privacy Policy](https://stridewell.app/privacy)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.top, Spacing.xs)
                        .padding(.bottom, Spacing.xxl)
                }
                .padding(.horizontal, Spacing.md)
            }
            .navigationBarHidden(true)
            .navigationDestination(for: String.self) { destination in
                if destination == "signin" {
                    SignInScreen()
                }
            }
        }
        .sheet(isPresented: $showSignUp) {
            SignUpScreen()
                .presentationDetents([.medium, .large])
                .presentationBackground(Color(uiColor: .systemBackground))
        }
    }

    // MARK: - Apple Sign-In

    private func handleAppleSignIn() async {
        isLoadingApple = true
        errorMessage = nil

        guard let credential = await appleSignInHandler.signIn() else {
            // User cancelled — not an error
            isLoadingApple = false
            return
        }

        let result = await apiClient.appleSignIn(
            idToken: credential.identityToken,
            nonce: credential.rawNonce
        )
        await finalize(result: result) { isLoadingApple = $0 }
    }

    // MARK: - Google Sign-In

    private func handleGoogleSignIn() async {
        isLoadingGoogle = true
        errorMessage = nil

        guard
            let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
            let rootVC = scene.windows.first(where: \.isKeyWindow)?.rootViewController
        else {
            errorMessage = "Unable to present Google Sign-In"
            isLoadingGoogle = false
            return
        }

        let rawNonce = generateNonce()

        do {
            let gidResult = try await GIDSignIn.sharedInstance.signIn(
                withPresenting: rootVC,
                hint: nil,
                additionalScopes: nil,
                nonce: sha256(rawNonce)   // Google stores SHA-256 of nonce in the token
            )
            guard let idToken = gidResult.user.idToken?.tokenString else {
                errorMessage = "Google Sign-In failed: missing ID token"
                isLoadingGoogle = false
                return
            }
            let result = await apiClient.googleSignIn(idToken: idToken, nonce: rawNonce)
            await finalize(result: result) { isLoadingGoogle = $0 }
        } catch {
            let nsError = error as NSError
            // GIDSignInError.canceled — user tapped Cancel — is not a real error
            if nsError.domain != "com.google.GIDSignIn" || nsError.code != -5 {
                errorMessage = error.localizedDescription
            }
            isLoadingGoogle = false
        }
    }

    // MARK: - Nonce Helpers (Google Sign-In)

    private func generateNonce(length: Int = 32) -> String {
        var randomBytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        return Data(randomBytes)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8))
            .compactMap { String(format: "%02x", $0) }
            .joined()
    }

    // MARK: - Shared Post-Auth Flow

    private func finalize(result: ApiResult<LoginResponse>, setLoading: (Bool) -> Void) async {
        switch result {
        case .failure(_, let message):
            errorMessage = message
            setLoading(false)
            return
        case .success(let response):
            authStore.signIn(token: response.token, userId: response.user_id)
        }

        let statusResult = await apiClient.onboardingStatus()
        if case .success(let state) = statusResult {
            onboardingStore.update(from: state)
        }

        setLoading(false)
        // RootView observes authStore.isAuthenticated and re-routes automatically
    }
}
