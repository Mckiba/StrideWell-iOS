//
//  LandingScreen.swift
//  Stridewell
//
//  Entry point for unauthenticated users. Static dark-gradient background,
//  Stridewell branding, and three auth paths: Apple, Google, and email.
//  Apple/Google handlers are no-ops until Supabase OAuth is wired up.
//


import SwiftUI

struct LandingScreen: View {
    
    // MARK: - State
    
    @State private var navigationPath = NavigationPath()
    @State private var showSignUp = false
    
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
                        PrimaryButton("Continue with Apple",
                                      icon: .system("applelogo"),
                                      backgroundColor: .white,
                                      foregroundColor: .black) {
                            // TODO: Supabase Apple OAuth
                        }

                        PrimaryButton("Continue with Google",
                                      icon: .asset("Google"),
                                      backgroundColor: Color(uiColor: .secondarySystemBackground),
                                      foregroundColor: Color(uiColor: .label)) {
                            // TODO: Supabase Google OAuth
                        }

                        PrimaryButton("Sign up with Email",
                                      icon: .system("envelope.fill"),
                                      backgroundColor: AppColor.accent,
                                      foregroundColor: .white) {
                            showSignUp = true
                        }
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
}
