//
//  SettingsConnectedAccountsSection.swift
//  Stridewell
//

import SwiftUI

struct SettingsConnectedAccountsSection: View {

    let stravaState: SettingsStore.StravaState
    var onConnect: () -> Void = {}
    var onReconnect: () -> Void = {}
    var onDisconnect: () -> Void = {}
    var onRetry: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Connected Accounts")
                .font(.sectionTitle)

            CardView {
                stravaRow
            }
        }
    }

    // MARK: - Strava Row

    @ViewBuilder
    private var stravaRow: some View {
        switch stravaState {
        case .loading:
            HStack {
                stravaIcon
                Text("Checking connection…")
                    .font(.cardBody)
                    .foregroundStyle(.secondary)
                Spacer()
                ProgressView()
            }

        case .disconnected:
            HStack {
                stravaIcon
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Strava")
                        .font(.cardTitle)
                    Text("Not connected")
                        .font(.cardCaption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Connect", action: onConnect)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }

        case .connected(_, let scope):
            HStack {
                stravaIcon
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Strava")
                        .font(.cardTitle)
                    Text(connectedSubtitle(scope: scope))
                        .font(.cardCaption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Disconnect", action: onDisconnect)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(.red)
            }

        case .expired:
            HStack {
                stravaIcon
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Strava")
                        .font(.cardTitle)
                    Text("Connection expired")
                        .font(.cardCaption)
                        .foregroundStyle(.orange)
                }
                Spacer()
                Button("Reconnect", action: onReconnect)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }

        case .connecting:
            HStack {
                stravaIcon
                Text("Connecting to Strava…")
                    .font(.cardBody)
                    .foregroundStyle(.secondary)
                Spacer()
                ProgressView()
            }

        case .disconnecting:
            HStack {
                stravaIcon
                Text("Disconnecting…")
                    .font(.cardBody)
                    .foregroundStyle(.secondary)
                Spacer()
                ProgressView()
            }

        case .error(let message):
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    stravaIcon
                    Text("Strava")
                        .font(.cardTitle)
                    Spacer()
                    Button("Retry", action: onRetry)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
                Text(message)
                    .font(.cardCaption)
                    .foregroundStyle(.red)
            }
        }
    }

    // MARK: - Helpers

    private var stravaIcon: some View {
        Image(systemName: "figure.run.circle.fill")
            .font(.title2)
            .foregroundStyle(.orange)
    }

    private func connectedSubtitle(scope: String?) -> String {
        if let scope {
            return "Connected (\(scope))"
        }
        return "Connected"
    }
}

// MARK: - Previews

#Preview("Disconnected") {
    SettingsConnectedAccountsSection(stravaState: .disconnected)
        .padding()
}

#Preview("Connected") {
    SettingsConnectedAccountsSection(
        stravaState: .connected(expiresAt: "2026-06-01T00:00:00Z", scope: "activity:read_all")
    )
    .padding()
}

#Preview("Expired") {
    SettingsConnectedAccountsSection(
        stravaState: .expired(expiresAt: "2025-01-01T00:00:00Z", scope: "activity:read_all")
    )
    .padding()
}

#Preview("Error") {
    SettingsConnectedAccountsSection(stravaState: .error("Network error"))
        .padding()
}

#Preview("Loading") {
    SettingsConnectedAccountsSection(stravaState: .loading)
        .padding()
}
