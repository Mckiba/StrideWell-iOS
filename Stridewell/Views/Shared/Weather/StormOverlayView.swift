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

    var body: some View {
        switch condition {
        case .clear:
            EmptyView()
        case .rain:
            StormView(type: .rain, direction: .degrees(20), strength: 250)
        case .snow:
            StormView(type: .snow, direction: .degrees(0), strength: 150)
        }
    }
}
