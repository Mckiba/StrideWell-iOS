//
//  OnboardingUnits.swift
//  Stridewell
//
//  Distance unit handling for guided onboarding. The athlete picks mi or km in the
//  first onboarding step (stored under the same key as Settings); intake values are
//  always stored/sent in km.
//

import Foundation

enum OnboardingUnits {

    static let kmPerMile = 1.609344

    /// UserDefaults key shared with SettingsStore.unitSystem.
    private static let unitSystemKey = "Settings.unitSystem"

    /// True when the athlete's chosen unit is imperial. Reads the preference set in
    /// the onboarding unit step / Settings, falling back to device locale when unset.
    static var usesMiles: Bool {
        if let raw = UserDefaults.standard.string(forKey: unitSystemKey),
           let unit = UnitSystem(rawValue: raw) {
            return unit == .imperial
        }
        return Locale.current.measurementSystem != .metric
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
