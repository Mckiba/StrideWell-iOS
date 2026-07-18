//
//  UnitPreferenceScreen.swift
//  Stridewell
//
//  First onboarding step. The athlete picks metric or imperial before the guided
//  intake begins, so the whole flow — and the Coach — speaks in their unit. The
//  choice is stored locally (shared with Settings) and synced to the backend.
//

import SwiftUI

struct UnitPreferenceScreen: View {

    @Environment(\.settingsStore) private var settingsStore
    @Environment(\.apiClient) private var apiClient
    @Environment(\.onboardingCoordinator) private var coordinator

    /// Seeded from device locale so US athletes land on Imperial by default.
    @State private var selection: UnitSystem =
        Locale.current.measurementSystem == .metric ? .metric : .imperial

    private let mutedGray = Color(hex: "#4C4C4C")

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Text("What's your unit preference")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.top, Spacing.xxl)

                Spacer().frame(height: Spacing.xxl)

                UnitWheelPicker(selection: $selection)

                Spacer().frame(height: Spacing.xl)

                unitDisplay

                Spacer().frame(height: Spacing.xl)

                Text("This can be updated later in the app settings")
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Spacer()

                PrimaryButton(title: "Begin", size: .large,
                              backgroundColor: .white, foregroundColor: .black) {
                    begin()
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xl)
        }
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Unit display example

    /// Mirrors the athlete's selection: "km" over "min / km" (or the mi variants).
    private var unitDisplay: some View {
        VStack(spacing: Spacing.sm) {
            Text(selection.distanceUnit)
                .font(.body)
                .foregroundStyle(mutedGray)

            VStack(spacing: 10) {
                rule
                HStack {
                    Text("min")
                    Spacer()
                    Text("/")
                    Spacer()
                    Text(selection.distanceUnit)
                }
                .font(.body)
                .foregroundStyle(mutedGray)
                rule
            }
        }
        .frame(width: 201)
    }

    private var rule: some View {
        Rectangle().fill(mutedGray).frame(height: 1)
    }

    // MARK: - Actions

    private func begin() {
        // Write the local value synchronously so OnboardingUnits (read by later
        // screens) reflects the choice immediately, then best-effort sync to the
        // backend so the Coach converses in this unit.
        settingsStore.unitSystem = selection
        Task { _ = await apiClient.setMeasurementSystem(selection) }
        coordinator.path.append(.integrations)
    }
}

// MARK: - Wheel Picker

/// Vertical two-option selector matching the Figma: the two labels stacked with a
/// static rule between them; the selected one is accent-tinted.
private struct UnitWheelPicker: View {

    @Binding var selection: UnitSystem

    var body: some View {
        VStack(spacing: Spacing.md) {
            option(.imperial)
            Rectangle()
                .fill(Color.white.opacity(0.18))
                .frame(width: 143, height: 1)
            option(.metric)
        }
    }

    private func option(_ unit: UnitSystem) -> some View {
        Text(unit.pickerTitle)
            .font(.body)
            .foregroundStyle(selection == unit ? AppColor.accent : Color.white.opacity(0.9))
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.15)) { selection = unit }
            }
    }
}

// MARK: - UnitSystem labels

private extension UnitSystem {
    var pickerTitle: String { self == .imperial ? "Imperial" : "Metric" }
    var distanceUnit: String { self == .imperial ? "mi" : "km" }
}

// MARK: - Preview

#Preview {
    UnitPreferenceScreen()
}
