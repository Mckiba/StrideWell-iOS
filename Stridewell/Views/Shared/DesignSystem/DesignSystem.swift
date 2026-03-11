//
//  DesignSystem.swift
//  Stridewell
//
//  Design tokens — spacing, corner radii, semantic font aliases, and semantic
//  color aliases. All raw system values should be referenced through these
//  constants so visual changes require editing only this file.
//

import SwiftUI

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
    static let surface:          Color = Color(uiColor: .systemBackground)
    static let surfaceElevated:  Color = Color(uiColor: .secondarySystemBackground)
    static let surfaceTertiary:  Color = Color(uiColor: .tertiarySystemBackground)
    static let textPrimary:      Color = .primary
    static let textSecondary:    Color = .secondary
    static let textTertiary:     Color = Color(uiColor: .tertiaryLabel)
    static let accent:           Color = .accentColor
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

    // MARK: - Activity Card Typography (Inter)
    static let activityTimestamp: Font = .inter(size: 12, weight: .bold)   // date + time stamp
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
