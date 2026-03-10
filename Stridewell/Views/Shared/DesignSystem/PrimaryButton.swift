//
//  PrimaryButton.swift
//  Stridewell
//
//  Created by McKiba Williams on 3/8/26.
//


import SwiftUI


struct PrimaryButton: View {

    // MARK: - Properties

    let title: String
    let action: () -> Void
    var isEnabled: Bool = true
    var isLoading: Bool = false
    var size: ButtonSize = .medium

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Button Sizes

    enum ButtonSize {
        case small
        case medium
        case large

        var font: Font {
            switch self {
            case .small:
                return .body
            case .medium, .large:
                return .cardTitle
            }
        }

        var verticalPadding: CGFloat {
            switch self {
            case .small:
                return Spacing.xs // 12px
            case .medium:
                return Spacing.sm // 16px
            case .large:
                return Spacing.md // 20px
            }
        }

        var horizontalPadding: CGFloat {
            switch self {
            case .small:
                return Spacing.sm // 16px
            case .medium:
                return Spacing.lg // 24px
            case .large:
                return Spacing.xl // 32px
            }
        }

        var cornerRadius: CGFloat {
            switch self {
            case .small:
                return CornerRadius.md // 12px
            case .medium, .large:
                return CornerRadius.bubble // 12px
            }
        }
    }

    // MARK: - Body

    var body: some View {
        Button(action: {
            if isEnabled && !isLoading {
                action()
            }
        }) {
            HStack(spacing: Spacing.xs) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: foregroundColor))
                        .scaleEffect(0.8)
                }

                Text(title)
                    .font(size.font)
                    .foregroundColor(foregroundColor)
            }
            .padding(.vertical, size.verticalPadding)
            .padding(.horizontal, size.horizontalPadding)
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
            .cornerRadius(size.cornerRadius)
        }
        .disabled(!isEnabled || isLoading)
    }

    // MARK: - Computed Properties

    /// Inverts the system background: black in light mode, white in dark mode.
    private var baseColor: Color {
        colorScheme == .dark ? Color.white : Color.black
    }

    /// Button fill — dimmed when disabled or loading.
    private var backgroundColor: Color {
        (!isEnabled || isLoading) ? baseColor.opacity(0.35) : baseColor
    }

    /// Label/spinner color — always contrasts against `backgroundColor`.
    private var foregroundColor: Color {
        colorScheme == .dark ? Color.black : Color.white
    }
}

// MARK: - Convenience Initializers

extension PrimaryButton {

    /// Create a primary button with default settings
    init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    /// Create a primary button with custom size
    init(_ title: String, size: ButtonSize, action: @escaping () -> Void) {
        self.title = title
        self.size = size
        self.action = action
    }
}

// MARK: - Login Button Component
struct LoginButton: View {
    let icon: String
    let text: String
    let backgroundColor: Color
    let foregroundColor: Color
    let action: () async -> Void
    
    @State private var isLoading = false
    
    var body: some View {
        Button {
            Task {
                isLoading = true
                await action()
                isLoading = false
            }
        } label: {
            HStack(spacing: Spacing.xs) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: foregroundColor))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: icon)
                }
                
                Text(text)
            }
            .font(.cardTitle)
            .foregroundColor(foregroundColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.lg)
            .background(backgroundColor, in: .rect(cornerRadius: CornerRadius.bubble))
        }
        .disabled(isLoading)
        .animation(.easeInOut(duration: 0.25), value: isLoading)
    }
}



// MARK: - Preview

#Preview {
    VStack(spacing: Spacing.md) {
        PrimaryButton("Small Button", size: .small) {
            print("Small button tapped")
        }
        
        PrimaryButton("Large Button Disabled", size: .large) {
            print("Small button tapped")
        }.disabled(true)


        PrimaryButton("Medium Button (Default)", size: .medium) {
            print("Medium button tapped")
        }

        PrimaryButton("Large Button", size: .large) {
            print("Large button tapped")
        }

        PrimaryButton("Disabled Button") {
            print("This shouldn't print")
        }
        .disabled(true)

        PrimaryButton(
            title: "Loading Button",
            action: {},
            isLoading: true
        )
    }
    .padding()
}
