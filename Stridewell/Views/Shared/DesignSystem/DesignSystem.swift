//
//  DesignSystem.swift
//  Stridewell
//
//  Design tokens — spacing, corner radii, semantic font aliases, and semantic
//  color aliases. All raw system values should be referenced through these
//  constants so visual changes require editing only this file.
//

import SwiftUI
import UIKit

// MARK: - Spacing

enum Spacing {
    static let xs:  CGFloat = 4
    static let sm:  CGFloat = 8
    static let md:  CGFloat = 16
    static let lg:  CGFloat = 24
    static let xl:  CGFloat = 32
    static let xl2: CGFloat = 20  // icon-to-content gap (ActivityCard)
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius

enum CornerRadius {
    static let sm:     CGFloat = 8    // buttons, tags, small chips
    static let md:     CGFloat = 12   // cards (CardView default)
    static let lg:     CGFloat = 16   // sheets, large containers
    static let bubble: CGFloat = 18   // chat bubbles
    static let input:  CGFloat = 20   // text input fields
}

// MARK: - Semantic Colors

/// Semantic color tokens. Using these instead of raw system color names means
/// any palette change only requires editing this enum.
enum AppColor {
    // Adaptive system surfaces — automatically correct in both modes
    static let surface:             Color = Color(uiColor: .systemBackground)
    static let surfaceElevated:     Color = Color(uiColor: .secondarySystemBackground)
    static let surfaceTertiary:     Color = Color(uiColor: .tertiarySystemBackground)

    // Card surface: white in light mode, deep charcoal (#1E1E1E) in dark mode
    static let cardSurface: Color = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark ? UIColor(hex: "#1E1E1E") : .white
    })

    // Adaptive text
    static let textPrimary:      Color = .primary
    static let textSecondary:    Color = .secondary
    static let textTertiary:     Color = Color(uiColor: .tertiaryLabel)

    // Accent: #289FFF in light, #5E9CFF (higher contrast) in dark
    static let accent: Color = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark ? UIColor(hex: "#5E9CFF") : UIColor(hex: "#289FFF")
    })

    // Progress bar empty segment: light gray in light, subtle charcoal in dark
    static let progressTrackEmpty: Color = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark ? UIColor(hex: "#38383A") : UIColor(hex: "#E8E8E8")
    })

    static let destructive:      Color = .red
}

// MARK: - Typography (semantic aliases over system fonts)

extension Font {
    // Screens & navigation
    static let screenTitle:  Font = .title2.bold()
    static let sectionTitle: Font = .headline

    // Cards & list rows
    static let cardTitle:    Font = .body.weight(.semibold)
    static let cardBody:     Font = .subheadline
    static let cardCaption:  Font = .caption

    // Workout date column (WorkoutCardView)
    static let dateDay:      Font = .caption2.weight(.medium)   // "Mon"
    static let dateNumber:   Font = .callout.weight(.semibold)  // "3"

    // MARK: - Inter Custom Font
    /// Returns an Inter font at the given size and weight.
    /// Requires Inter .ttf files registered in Info.plist (UIAppFonts).
    static func inter(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch weight {
        case .bold:     return .custom("Inter-Bold",     size: size)
        case .semibold: return .custom("Inter-SemiBold", size: size)
        case .medium:   return .custom("Inter-Medium",   size: size)
        default:        return .custom("Inter-Regular",  size: size)
        }
    }
    
    
    // MARK: - Sofia Sans Custom Font
    /// Returns a Sofia Sans font at the given size and weight.
    /// Requires SofiaSans-{Regular,Medium,SemiBold,Bold}.ttf registered in Info.plist.
    static func sofiaSans(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch weight {
        case .bold:     return .custom("SofiaSans-Bold",     size: size)
        case .semibold: return .custom("SofiaSans-SemiBold", size: size)
        case .medium:   return .custom("SofiaSans-Medium",   size: size)
        default:        return .custom("SofiaSans-Regular",  size: size)
        }
    }

    // MARK: - Activity Card Typography (Inter)
    static let activityTimestamp: Font = .sofiaSans(size: 12, weight: .bold)   // date + time stamp
    static let activityName:      Font = .inter(size: 12, weight: .bold)   // run name
    static let activityStatLabel: Font = .inter(size: 10)                  // "DISTANCE" / "TIME" / "AVG PACE"
    static let activityStatValue: Font = .inter(size: 11, weight: .bold)   // "4.8 km" / "26:08" / "5:30 /km"
}

// MARK: - Color Hex Initialiser

extension Color {
    /// Initialise a Color from a hex string, e.g. `Color(hex: "#FC4C02")`.
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xff) / 255
        let g = Double((int >> 8)  & 0xff) / 255
        let b = Double(int         & 0xff) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}

// MARK: - UIColor Hex / RGB Initialisers
// Mirrors the Color(hex:) pattern above for UIKit contexts (e.g. Core Graphics rendering).

extension UIColor {
    /// Initialise from a hex string with an optional alpha component.
    /// e.g. `UIColor(hex: "#FC4C02", alpha: 0.75)`
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = CGFloat((int >> 16) & 0xff) / 255
        let g = CGFloat((int >> 8)  & 0xff) / 255
        let b = CGFloat(int         & 0xff) / 255
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }

    /// Initialise from 0–255 integer RGB values with an optional alpha component.
    /// e.g. `UIColor(r: 252, g: 76, b: 2, alpha: 0.75)`
    convenience init(r: Int, g: Int, b: Int, alpha: CGFloat = 1.0) {
        self.init(
            red:   CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue:  CGFloat(b) / 255,
            alpha: alpha
        )
    }
}

