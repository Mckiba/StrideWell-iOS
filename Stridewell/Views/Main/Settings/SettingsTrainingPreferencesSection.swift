//
//  SettingsTrainingPreferencesSection.swift
//  Stridewell
//

import SwiftUI

struct SettingsTrainingPreferencesSection: View {

    @Binding var unitSystem: UnitSystem
    @Binding var reflectionReminders: Bool
    @Binding var planUpdateAlerts: Bool
    @Binding var appTheme: AppTheme
    /// Overrides the live WeatherKit condition for preview purposes.
    /// nil = use live weather; .rain/.snow = force that effect on the dashboard.
    @Binding var weatherPreview: StormCondition?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Training Preferences")
                .font(.sectionTitle)

            CardView {
                VStack(spacing: 0) {
                    goalRow
                    Divider()
                    fitnessProfileRow
                    Divider()
                    unitsRow
                    Divider()
                    themeRow
                    Divider()
                    reflectionToggle
                    Divider()
                    planAlertToggle
                    Divider()
                    weatherPreviewRow
                }
            }
        }
    }

    // MARK: - Rows

    private var goalRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Goal")
                    .font(.cardTitle)
                Text("Set via chat with your coach")
                    .font(.cardCaption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.cardCaption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, Spacing.sm)
    }

    private var fitnessProfileRow: some View {
        NavigationLink {
            FitnessProfileScreen()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Fitness Profile")
                        .font(.cardTitle)
                        .foregroundStyle(.primary)
                    Text("Threshold pace, zones, history")
                        .font(.cardCaption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.cardCaption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, Spacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var unitsRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Units")
                    .font(.cardTitle)
                Text("Distance and pace display")
                    .font(.cardCaption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Picker("Units", selection: $unitSystem) {
                Text("km").tag(UnitSystem.metric)
                Text("mi").tag(UnitSystem.imperial)
            }
            .pickerStyle(.segmented)
            .fixedSize()
        }
        .padding(.vertical, Spacing.sm)
    }

    private var themeRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Appearance")
                    .font(.cardTitle)
                Text("App colour scheme")
                    .font(.cardCaption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Picker("Appearance", selection: $appTheme) {
                ForEach(AppTheme.allCases, id: \.self) { theme in
                    Text(theme.label).tag(theme)
                }
            }
            .pickerStyle(.segmented)
            .fixedSize()
        }
        .padding(.vertical, Spacing.sm)
    }

    private var reflectionToggle: some View {
        Toggle(isOn: $reflectionReminders) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Reflection reminders")
                    .font(.cardTitle)
                Text("Daily check-in notifications")
                    .font(.cardCaption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, Spacing.sm)
    }

    private var planAlertToggle: some View {
        Toggle(isOn: $planUpdateAlerts) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Plan update alerts")
                    .font(.cardTitle)
                Text("Notified when your plan changes")
                    .font(.cardCaption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, Spacing.sm)
    }

    private var weatherPreviewRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Weather Preview")
                    .font(.cardTitle)
                Text("Force rain or snow effect on the dashboard")
                    .font(.cardCaption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Picker("Weather Preview", selection: $weatherPreview) {
                Text("Off").tag(StormCondition?.none)
                Text("Rain").tag(StormCondition?.some(.rain))
                Text("Snow").tag(StormCondition?.some(.snow))
            }
            .pickerStyle(.segmented)
            .fixedSize()
        }
        .padding(.vertical, Spacing.sm)
    }
}

// MARK: - Preview

#Preview {
    SettingsTrainingPreferencesSection(
        unitSystem: .constant(.metric),
        reflectionReminders: .constant(true),
        planUpdateAlerts: .constant(false),
        appTheme: .constant(.device),
        weatherPreview: .constant(nil)
    )
    .padding()
}
