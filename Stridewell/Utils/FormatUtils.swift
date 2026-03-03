//
//  FormatUtils.swift
//  Stridewell
//

import Foundation

/// Pure formatting utilities for workout display values.
/// All methods are stateless and side-effect free.
enum FormatUtils {

    /// Converts metres to a display string in kilometres.
    /// - Example: `8000 → "8.0 km"`, `12500 → "12.5 km"`
    static func distance(_ metres: Double) -> String {
        let km = metres / 1000.0
        return String(format: "%.1f km", km)
    }

    /// Converts seconds-per-kilometre to a "m:ss /km" pace string.
    /// - Example: `330 → "5:30 /km"`, `240 → "4:00 /km"`
    static func pace(_ secondsPerKm: Double) -> String {
        let total = Int(secondsPerKm.rounded())
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%d:%02d /km", minutes, seconds)
    }

    /// Converts total seconds to a duration string.
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
