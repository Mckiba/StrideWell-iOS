//
//  SettingsStubScreen.swift
//  Stridewell
//
//  Placeholder for M12 (SettingsScreen — Strava connect/disconnect, sign out, delete account).
//

import SwiftUI

struct SettingsStubScreen: View {
    var body: some View {
        ZStack {
            MapBackground()
            Text("Settings screen — Milestone 12")
                .foregroundStyle(.secondary)
        }
        .navigationTitle("Settings")
    }
}
