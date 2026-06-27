//
//  OnboardingUnits.swift
//  Stridewell
//
//  Distance unit handling for guided onboarding. The athlete sees mi or km by
//  locale; intake values are always stored/sent in km.
//

import Foundation

enum OnboardingUnits {

    static let kmPerMile = 1.609344

    /// True when the device locale prefers imperial distances.
    static var usesMiles: Bool {
        Locale.current.measurementSystem != .metric
    }

    static var unitLabel: String { usesMiles ? "mi" : "km" }

    /// Convert km → the athlete's display unit.
    static func displayValue(fromKm km: Double) -> Double {
        usesMiles ? km / kmPerMile : km
    }

    /// Convert a value in the athlete's display unit → km.
    static func km(fromDisplay value: Double) -> Double {
        usesMiles ? value * kmPerMile : value
    }

    /// Slider upper bound in the display unit (~100 mi / ~160 km per week).
    static var weeklyVolumeMax: Double { usesMiles ? 100 : 160 }

    /// "25 mi" / "40 km" — value already in display units.
    static func formatted(displayValue value: Double) -> String {
        "\(Int(value.rounded())) \(unitLabel)"
    }
}
