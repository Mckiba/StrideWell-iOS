//
//  WeatherCardImage.swift
//  Stridewell
//
//  Maps a backend `icon` string to a themed weather thumbnail (Assets/Weather).
//

import SwiftUI
import UIKit

enum WeatherCardImage {

    /// Themed asset name (Assets.xcassets/Weather) for a backend icon string.
    static func assetName(for icon: String) -> String {
        switch icon {
        case "exclamation_circle":     return "extreme_weather"
        case "rain_cloud":             return "rain-icon"
        case "sun_max":                return "uv-index"
        case "wind":                   return "wind"
        case "thermometer_sun":        return "sun"
        case "thermometer_snowflake":  return "extreme_cold"
        case "sun_setting":            return "sunset"
        case "moon":                   return "moon"
        default:                       return "sun"
        }
    }

    /// Themed image for a backend icon, falling back to a placeholder if the
    /// asset is missing.
    static func image(for icon: String) -> Image {
        let name = assetName(for: icon)
        if UIImage(named: name) != nil { return Image(name) }
        return Image("bg2")
    }
}
