//
//  DesignSystem.swift
//  Stridewell
//
//  Minimal design system — spacing, corner radii, and semantic font aliases.
//  Centralises values already used across existing screens (16, 24, 32, 48, etc.).
//

import SwiftUI

// MARK: - Spacing

enum Spacing {
    static let xs:  CGFloat = 4
    static let sm:  CGFloat = 8
    static let md:  CGFloat = 16
    static let lg:  CGFloat = 24
    static let xl:  CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius

enum CornerRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
}

// MARK: - Typography (semantic aliases over system fonts)

extension Font {
    static let screenTitle:  Font = .title2.bold()
    static let sectionTitle: Font = .headline
    static let cardTitle:    Font = .body.weight(.semibold)
    static let cardBody:     Font = .subheadline
    static let cardCaption:  Font = .caption
}
