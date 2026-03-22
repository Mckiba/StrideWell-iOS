//
//  PrimaryButton.swift
//  Stridewell
//
//  Created by McKiba Williams on 3/8/26.
//

import SwiftUI

// MARK: - ButtonSize

enum ButtonSize {
    case small
    case medium
    case large

    var font: Font {
        switch self {
        case .small:           return .body
        case .medium, .large:  return .cardTitle
        }
    }

    var verticalPadding: CGFloat {
        switch self {
        case .small:   return Spacing.xs
        case .medium:  return Spacing.sm
        case .large:   return Spacing.md
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .small:   return Spacing.sm
        case .medium:  return Spacing.lg
        case .large:   return Spacing.xl
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .small:           return CornerRadius.md
        case .medium, .large:  return CornerRadius.bubble
        }
    }
}

// MARK: - ButtonIcon

/// Typed icon source — distinguishes SF Symbols from asset-catalog images.
enum ButtonIcon {
    case system(String)   // SF Symbol   — Image(systemName:)
    case asset(String)    // Asset catalog — Image(_:)
}

// MARK: - PrimaryButton

struct PrimaryButton: View {

    // MARK: - Properties

    let title: String
    var icon: ButtonIcon? = nil           // optional leading icon
    var isEnabled: Bool = true
    var isLoading: Bool = false
    var size: ButtonSize = .medium
    var backgroundColor: Color? = nil    // explicit fill override
    var foregroundColor: Color? = nil    // explicit label/icon color override
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Body

    var body: some View {
        Button(action: {
            if isEnabled && !isLoading { action() }
        }) {
            HStack(spacing: Spacing.lg) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: resolvedForegroundColor))
                        .scaleEffect(0.8)
                } else if let icon {
                    switch icon {
                    case .system(let name):
                        Image(systemName: name)
                            .foregroundColor(resolvedForegroundColor)
                    case .asset(let name):
                        Image(name)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 18)
                    }
                }

                Text(title)
                    .font(size.font)
                    .foregroundColor(resolvedForegroundColor)
            }
            .padding(.vertical, size.verticalPadding)
            .padding(.horizontal, size.horizontalPadding)
            .frame(maxWidth: .infinity)
            .background(resolvedBackgroundColor)
            .cornerRadius(size.cornerRadius)
        }
        .disabled(!isEnabled || isLoading)
    }

    // MARK: - Color Resolution

    private var resolvedBackgroundColor: Color {
        let base = backgroundColor ?? (colorScheme == .dark ? Color.white : Color.black)
        return (!isEnabled || isLoading) ? base.opacity(0.35) : base
    }

    private var resolvedForegroundColor: Color {
        foregroundColor ?? (colorScheme == .dark ? Color.black : Color.white)
    }
}

// MARK: - Convenience Initializers

extension PrimaryButton {

    /// Default: no icon, system-inverted colors.
    init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    /// Size variant: no icon, system-inverted colors.
    init(_ title: String, size: ButtonSize, action: @escaping () -> Void) {
        self.title = title
        self.size = size
        self.action = action
    }

    /// Icon variant: leading icon (SF Symbol or asset) with explicit fill and label colors.
    init(_ title: String, icon: ButtonIcon, backgroundColor: Color, foregroundColor: Color,
         size: ButtonSize = .large, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.size = size
        self.action = action
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Spacing.md) {
        PrimaryButton("Default Button") {}

        PrimaryButton("Small Button", size: .small) {}

        PrimaryButton("Large Button", size: .large) {}

        PrimaryButton("Disabled Button") {}
            .disabled(true)

        PrimaryButton(title: "Loading Button", isLoading: true) {}

        PrimaryButton("Continue with Apple",
                      icon: .system("applelogo"),
                      backgroundColor: .white,
                      foregroundColor: .black) {}

        PrimaryButton("Continue with Google",
                      icon: .asset("Google"),
                      backgroundColor: Color(uiColor: .secondarySystemBackground),
                      foregroundColor: Color(uiColor: .label)) {}

        PrimaryButton("Sign up with Email",
                      icon: .system("envelope.fill"),
                      backgroundColor: AppColor.accent,
                      foregroundColor: .white) {}
    }
    .padding()
}
