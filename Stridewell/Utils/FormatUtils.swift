//
//  FormatUtils.swift
//  Stridewell
//

import Foundation

// MARK: - UnitSystem

/// The unit system used for displaying distances and paces throughout the app.
enum UnitSystem: String {
    case metric   = "metric"
    case imperial = "imperial"
}

// MARK: - FormatUtils

/// Pure formatting utilities for workout display values.
/// All methods are stateless and side-effect free.
enum FormatUtils {

    // MARK: - Distance

    /// Converts metres to a display string in the given unit system.
    /// - Metric:   `8000 → "8.0 km"`,  `12500 → "12.5 km"`
    /// - Imperial: `8000 → "5.0 mi"`,  `12500 → "7.8 mi"`
    static func distance(_ metres: Double, unit: UnitSystem = .metric) -> String {
        switch unit {
        case .metric:
            let km = metres / 1000.0
            return String(format: "%.1f km", km)
        case .imperial:
            let miles = metres / 1609.344
            return String(format: "%.1f mi", miles)
        }
    }

    // MARK: - Pace

    /// Converts seconds-per-kilometre to a pace string in the given unit system.
    /// - Metric:   `330 → "5:30 /km"`,  `240 → "4:00 /km"`
    /// - Imperial: `330 → "8:51 /mi"`,  `240 → "6:26 /mi"`
    static func pace(_ secondsPerKm: Double, unit: UnitSystem = .metric) -> String {
        switch unit {
        case .metric:
            let total = Int(secondsPerKm.rounded())
            let minutes = total / 60
            let seconds = total % 60
            return String(format: "%d:%02d /km", minutes, seconds)
        case .imperial:
            let secondsPerMile = secondsPerKm * 1.60934
            let total = Int(secondsPerMile.rounded())
            let minutes = total / 60
            let seconds = total % 60
            return String(format: "%d:%02d /mi", minutes, seconds)
        }
    }

    // MARK: - Duration

    /// Converts total seconds to a duration string. Unit-system independent.
    /// - Under 1 hour: `"mm:ss"` — e.g. `2700 → "45:00"`
    /// - 1 hour or more: `"h:mm"` — e.g. `5400 → "1:30"`
    static func duration(_ totalSeconds: Int) -> String {
        if totalSeconds < 3600 {
            let m = totalSeconds / 60
            let s = totalSeconds % 60
            return String(format: "%d:%02d", m, s)
        } else {
            let h = totalSeconds / 3600
            let m = (totalSeconds % 3600) / 60
            return String(format: "%d:%02d", h, m)
        }
    }
}
