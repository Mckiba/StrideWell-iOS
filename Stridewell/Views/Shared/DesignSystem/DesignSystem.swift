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

    // MARK: Plan-day card border tokens
    /// Bottom-stroke colour for the default (planned, upcoming) PlanDay card.
    /// Muted blue from Figma node 688:1099.
    static let cardBorderDefault: Color = Color(hex: "#4183B9")

    /// Bottom-stroke colour for Completed/Modified PlanDay cards and the
    /// Recent Activity feed's ActivityCard. Reuses the brand `accent`.
    static let cardBorderCompleted: Color = accent

    /// Bottom-stroke colour for Missed PlanDay cards. Same warm grey used for
    /// the missed-state text below.
    static let cardBorderMissed: Color = Color(hex: "#A6A6A6")

    /// Text colour for Missed PlanDay cards — every label and value renders
    /// at this colour so the whole card reads "this day passed without a run".
    static let textMissed: Color = Color(hex: "#A6A6A6")

    /// Light grey divider that separates the planned-stats block from the
    /// actual-stats block in the Completed card variant.
    static let cardDivider: Color = Color(hex: "#D9D9D9")
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

    // MARK: - Activity Card Typography
    static let activityTimestamp: Font = .sofiaSans(size: 12, weight: .regular)   // date + time stamp
    static let activityName:      Font = .sofiaSans(size: 14, weight: .bold)   // run name
    static let activityStatLabel: Font = .sofiaSans(size: 12)                  // "DISTANCE" / "TIME" / "AVG PACE"
    static let activityStatValue: Font = .sofiaSans(size: 12, weight: .bold)   // "4.8 km" / "26:08" / "5:30 /km"
    static let largeStatValue:  Font = .sofiaSans(size: 20, weight: .bold)
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

// MARK: Card bottom-stroke modifier

/// Conditionally applies `cardBottomStroke(AppColor.cardBorderCompleted)` when
/// `isPlanLinked` is true. Used by ActivityCard so only runs that fulfilled a
/// planned workout show the accent stroke — historical/unlinked runs stay plain.
struct PlanLinkedStrokeModifier: ViewModifier {
    let isPlanLinked: Bool
    func body(content: Content) -> some View {
        if isPlanLinked {
            content.cardBottomStroke(AppColor.cardBorderCompleted)
        } else {
            content
        }
    }
}

extension View {
    /// Wraps the view's bottom edge with a coloured "lipstick" stroke that
    /// curves with the card's `cornerRadius` (Figma node 688:1099).
    ///
    /// Implementation: the view is padded `height` from the bottom, and a
    /// fully-rounded rectangle in `color` is painted behind. The stroke band
    /// + corner curves peek out below the (already-rounded) card surface.
    ///
    /// Apply **after** the card's own `.background` and `.clipShape`, before
    /// `.shadow`. The view passed in should already be the rounded card.
    func cardBottomStroke(
        _ color: Color,
        height: CGFloat = 3,
        cornerRadius: CGFloat = CornerRadius.md
    ) -> some View {
        self
            .padding(.bottom, height)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(color)
            )
    }

    /// Optional variant — applies the stroke only when `color` is non-nil so
    /// planned/rest cards render with no stroke at all.
    @ViewBuilder
    func cardBottomStroke(
        _ color: Color?,
        height: CGFloat = 3,
        cornerRadius: CGFloat = CornerRadius.md
    ) -> some View {
        if let color {
            cardBottomStroke(color, height: height, cornerRadius: cornerRadius)
        } else {
            self
        }
    }
}

