//
//  SettingsAccountSection.swift
//  Stridewell
//

import SwiftUI

struct SettingsAccountSection: View {

    let isSigningOut: Bool
    let deleteState: SettingsStore.DeleteState
    var onSignOut: () -> Void = {}
    var onDeleteAccount: () -> Void = {}
    var onExportData: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Account")
                .font(.sectionTitle)

            CardView {
                VStack(spacing: 0) {
                    signOutRow
                    Divider()
                    exportRow
                    Divider()
                    deleteRow

                    if case .error(let message) = deleteState {
                        Text(message)
                            .font(.cardCaption)
                            .foregroundStyle(.red)
                            .padding(.top, Spacing.sm)
                    }
                }
            }
        }
    }

    // MARK: - Rows

    private var signOutRow: some View {
        Button(action: onSignOut) {
            HStack {
                Text("Sign out")
                    .font(.cardTitle)
                    .foregroundStyle(.primary)
                Spacer()
                if isSigningOut {
                    ProgressView()
                }
            }
            .padding(.vertical, Spacing.sm)
        }
        .disabled(isSigningOut)
    }

    private var exportRow: some View {
        Button(action: onExportData) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Export data")
                        .font(.cardTitle)
                        .foregroundStyle(.primary)
                    Text("Coming soon")
                        .font(.cardCaption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.vertical, Spacing.sm)
        }
        .disabled(true)
    }

    private var deleteRow: some View {
        Button(action: onDeleteAccount) {
            HStack {
                Text("Delete account")
                    .font(.cardTitle)
                    .foregroundStyle(.red)
                Spacer()
                if case .deleting = deleteState {
                    ProgressView()
                }
            }
            .padding(.vertical, Spacing.sm)
        }
        .disabled(deleteState == .deleting)
    }
}

// MARK: - Previews

#Preview("Idle") {
    SettingsAccountSection(
        isSigningOut: false,
        deleteState: .idle
    )
    .padding()
}

#Preview("Deleting") {
    SettingsAccountSection(
        isSigningOut: false,
        deleteState: .deleting
    )
    .padding()
}

#Preview("Delete Error") {
    SettingsAccountSection(
        isSigningOut: false,
        deleteState: .error("Something went wrong. Please try again.")
    )
    .padding()
}
