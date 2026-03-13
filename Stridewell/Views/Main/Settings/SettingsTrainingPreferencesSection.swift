//
//  SettingsTrainingPreferencesSection.swift
//  Stridewell
//

import SwiftUI

struct SettingsTrainingPreferencesSection: View {

    @Binding var unitSystem: UnitSystem
    @Binding var reflectionReminders: Bool
    @Binding var planUpdateAlerts: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Training Preferences")
                .font(.sectionTitle)

            CardView {
                VStack(spacing: 0) {
                    goalRow
                    Divider()
                    unitsRow
                    Divider()
                    reflectionToggle
                    Divider()
                    planAlertToggle
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
}

// MARK: - Preview

#Preview {
    SettingsTrainingPreferencesSection(
        unitSystem: .constant(.metric),
        reflectionReminders: .constant(true),
        planUpdateAlerts: .constant(false)
    )
    .padding()
}
