//
//  PlanBuildingContent.swift
//  Stridewell
//

import SwiftUI

struct PlanBuildingContent: View {

    let errorMessage: String?
    var onRetry: () -> Void = {}

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 72))
                .foregroundStyle(.tint)
                .symbolEffect(.variableColor.iterative, isActive: errorMessage == nil)

            VStack(spacing: 8) {
                Text("Building your plan")
                    .font(.title2.bold())
                Text("Your coach is putting together a training plan built around your goals. This usually takes a few seconds.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let errorMessage {
                VStack(spacing: 12) {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                    Button("Try again", action: onRetry)
                        .buttonStyle(.bordered)
                        .controlSize(.regular)
                }
                .transition(.opacity)
            } else {
                ProgressView()
                    .transition(.opacity)
            }

            Spacer()
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            OnboardingBackground()
            Rectangle().fill(.ultraThinMaterial).ignoresSafeArea()
        }
        .animation(.easeInOut(duration: 0.2), value: errorMessage)
    }
}

// MARK: - Previews

#Preview("Loading") {
    NavigationStack {
        PlanBuildingContent(errorMessage: nil)
            .navigationTitle("Building your plan")
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Error") {
    NavigationStack {
        PlanBuildingContent(errorMessage: "Something went wrong. Please try again.")
            .navigationTitle("Building your plan")
            .navigationBarTitleDisplayMode(.inline)
    }
}
