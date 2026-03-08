//
//  StateViews.swift
//  Stridewell
//
//  Reusable loading, empty, and error state views.
//

import SwiftUI

// MARK: - Loading

struct LoadingStateView: View {
    var message: String = "Loading..."

    var body: some View {
        VStack(spacing: Spacing.md) {
            Spacer()
            ProgressView()
            Text(message)
                .font(.cardBody)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
}

// MARK: - Empty

struct EmptyStateView: View {
    let title: String
    var subtitle: String? = nil
    var actionLabel: String? = nil
    var onAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: Spacing.sm) {
            Spacer()
            Text(title)
                .font(.cardTitle)
                .foregroundStyle(.secondary)
            if let subtitle {
                Text(subtitle)
                    .font(.cardBody)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
            if let actionLabel, let onAction {
                Button(actionLabel, action: onAction)
                    .buttonStyle(.bordered)
                    .padding(.top, Spacing.sm)
            }
            Spacer()
        }
        .padding(.horizontal, Spacing.xl)
    }
}

// MARK: - Error

struct ErrorStateView: View {
    let message: String
    var onRetry: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: Spacing.sm) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text(message)
                .font(.cardBody)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
            if let onRetry {
                Button("Try again", action: onRetry)
                    .buttonStyle(.bordered)
            }
            Spacer()
        }
    }
}
