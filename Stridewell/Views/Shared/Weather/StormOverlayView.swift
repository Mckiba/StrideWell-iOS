//
//  StormOverlayView.swift
//  Stridewell
//
//  Renders the appropriate storm particle effect for the current weather
//  condition. Returns EmptyView for .clear — zero animation overhead.
//
//  Usage (HomeScreen ZStack):
//    StormOverlayView(condition: weatherStore.activeCondition)
//        .ignoresSafeArea()
//        .allowsHitTesting(false)
//

import SwiftUI

struct StormOverlayView: View {
    let condition: StormCondition
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        switch condition {
        case .clear:
            EmptyView()
        case .rain:
            ZStack {
                dimmer
                StormView(type: .rain, direction: .degrees(20), strength: 250)
            }
        case .snow:
            ZStack {
                dimmer
                StormView(type: .snow, direction: .degrees(0), strength: 150)
            }
        }
    }

    /// Thin darkening layer so the light-colored storm particles remain
    /// legible when the app is in Light mode. Subtle in Dark mode.
    private var dimmer: some View {
        Color.black
            .opacity(colorScheme == .light ? 0.22 : 0.08)
            .ignoresSafeArea()
            .allowsHitTesting(false)
    }
}
