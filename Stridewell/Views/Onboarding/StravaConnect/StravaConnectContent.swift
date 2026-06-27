//
//  StravaConnectContent.swift
//  Stridewell
//

import SwiftUI

struct StravaConnectContent: View {
    
    let screenState: ScreenState
    var onConnect: () -> Void = {}
    var onContinueWithoutStrava: () -> Void = {}   // secondary:    no Strava -> manual baseline branch
    var onSkipOnboarding: () -> Void = {}          // tertiary:     POST /onboarding/skip -> default plan
    var onContinue: () -> Void = {}                // post-connect: proceed with Strava branch
    var onRetrySession: () -> Void = {}
    var onSignOut: () -> Void = {}
    var onClose: (() -> Void)?

    @State private var showingSheet = true


    enum ScreenState: Equatable {
        case starting
        case idle
        case connecting
        case connected
        case analyzing
        case slowBackfill        // backfill is slow (>~60s) — offer to continue without waiting
        case sessionError(String)
        case error(String)
    }

    /// The "Continue without Strava" affordance only makes sense before a connection
    /// is in flight or established.
    private var showContinueWithoutStrava: Bool {
        switch screenState {
        case .idle, .error, .starting: return true
        case .connecting, .connected, .analyzing, .slowBackfill, .sessionError: return false
        }
    }
    
    var body: some View {
        ZStack {
            OnboardingBackground()
            
            VStack() {
                
                // Text("You, in Context").font(.largeTitle).padding(.vertical, 40)
                Spacer()
                
                // Modal
                ZStack(alignment: .topTrailing) {
                    
                    VStack(spacing: 10) {
                        
                        // Strava logo
                        Image("strava_logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 160, height: 65)
                            .padding(.top, 10)
                        
                        statusRow
                            .frame(height: 44)
                            .padding(.bottom, 4)
                        
                        
                        switch screenState {

                        case .starting, .connecting, .analyzing:
                            EmptyView()
                        case .connected:
                            PrimaryButton("Continue", size: .medium){
                                onContinue()
                            }.padding(.horizontal, 48)
                                .padding(.vertical, 8)
                        case .slowBackfill:
                            PrimaryButton("Continue without waiting", size: .small){
                                onContinueWithoutStrava()
                            }.padding(.horizontal, 32)
                                .padding(.vertical, 8)
                        case .sessionError:
                            PrimaryButton("Try again", size: .small){
                                onRetrySession()
                            }.padding(.horizontal, 48)
                                .padding(.vertical, 8)
                        case .idle, .error:
                            PrimaryButton("Connect", size: .medium ){
                                onConnect()
                            }                          .padding(.horizontal, 48)
                                .padding(.vertical, 8)
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 45)
                    .background(
                        Color.white.opacity(0.59)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color(hex: "#f9f0f0"), lineWidth: 3)
                    )
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.25), radius: 40, x: 0, y: 20)
                    .frame(maxWidth: 320)
                    
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Let's make this plan about You. Together.")
                        .foregroundStyle(.white)

                    Text("Connect your Strava to help us build a plan tailored to your history and goals")
                        .foregroundStyle(.white)

                    // Secondary: continue the interview without connecting Strava.
                    if showContinueWithoutStrava {
                        PrimaryButton("Continue without Strava", size: .large, action: onContinueWithoutStrava)
                        Text("You can still build a personal plan — we'll just ask a few more questions.")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.75))
                    }

                    // Tertiary: skip onboarding entirely → generic starter plan.
                    Text("Skipping the onboarding will result in a default plan. For a more personal experience the early onboarding and Strava integration is recommended.")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.75))
                        .padding(.top, 4)

                    Button("Skip onboarding", action: onSkipOnboarding)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.white.opacity(0.85))

                    Button("Sign out", action: onSignOut)
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, alignment: .leading) // expand
                .padding(20)
                
                
                .frame(maxWidth: .infinity, minHeight: 350)                .background(Color.black)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 30,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 30
                    )
                )
            }
        }
    }
    
    
    
    // MARK: - Status Row
    
    @ViewBuilder
    private var statusRow: some View {
        switch screenState {
        case .starting:
            ProgressView("Setting up your session…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        case .connecting:
            ProgressView("Opening Strava…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        case .analyzing:
            HStack(spacing: 8) {
                ProgressView()
                Text("Analyzing your run history…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        case .slowBackfill:
            Text("This is taking a moment…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        case .connected:
            Label("Strava connected", systemImage: "checkmark.circle.fill")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.green)
        case .sessionError(let message):
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
        case .error(let message):
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
        case .idle:
            EmptyView()
        }
    }
}


struct OnboardingBackground: View {
    var body: some View {
        Image("OnboardingBackground")
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

// MARK: - Previews

#Preview("Idle") {
    NavigationStack {
        StravaConnectContent(screenState: .idle)
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Connecting") {
    NavigationStack {
        StravaConnectContent(screenState: .connecting)
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Connected") {
    NavigationStack {
        StravaConnectContent(screenState: .connected)
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Analyzing") {
    NavigationStack {
        StravaConnectContent(screenState: .analyzing)
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Session Error") {
    NavigationStack {
        StravaConnectContent(screenState: .sessionError("Unable to start session. Please try again."))
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("OAuth Error") {
    NavigationStack {
        StravaConnectContent(screenState: .error("Could not connect to Strava"))
            .navigationBarTitleDisplayMode(.inline)
    }
}
