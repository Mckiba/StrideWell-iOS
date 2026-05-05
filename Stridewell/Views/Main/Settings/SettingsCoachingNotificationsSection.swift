//
//  SettingsCoachingNotificationsSection.swift
//  Stridewell
//

import SwiftUI

struct SettingsCoachingNotificationsSection: View {

    @Binding var proactiveEnabled: Bool
    @Binding var trainingMilestoneEnabled: Bool
    @Binding var trainingConcernEnabled: Bool
    @Binding var upcomingEventEnabled: Bool
    @Binding var reengagementEnabled: Bool
    @Binding var planFollowupEnabled: Bool
    @Binding var quietHoursEnabled: Bool
    @Binding var quietHoursStart: String
    @Binding var quietHoursEnd: String
    let timezone: String
    let syncError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Coaching Notifications")
                .font(.sectionTitle)

            CardView {
                VStack(spacing: 0) {
                    Toggle(isOn: $proactiveEnabled) {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Enable coaching notifications")
                                .font(.cardTitle)
                            Text("Receive proactive coach check-ins based on your training.")
                                .font(.cardCaption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, Spacing.sm)

                    Divider()

                    Toggle(isOn: $trainingMilestoneEnabled) {
                        rowText(
                            "Training milestones",
                            "Consistency, breakthrough workouts, fitness improvements"
                        )
                    }
                    .padding(.vertical, Spacing.sm)
                    .disabled(!proactiveEnabled)

                    Divider()

                    Toggle(isOn: $trainingConcernEnabled) {
                        rowText(
                            "Training concerns",
                            "Early flags for strain, drift, or risk patterns"
                        )
                    }
                    .padding(.vertical, Spacing.sm)
                    .disabled(!proactiveEnabled)

                    Divider()

                    Toggle(isOn: $upcomingEventEnabled) {
                        rowText(
                            "Upcoming events",
                            "Timing alerts around race and plan events"
                        )
                    }
                    .padding(.vertical, Spacing.sm)
                    .disabled(!proactiveEnabled)

                    Divider()

                    Toggle(isOn: $reengagementEnabled) {
                        rowText(
                            "Re-engagement",
                            "Check-ins after extended inactivity"
                        )
                    }
                    .padding(.vertical, Spacing.sm)
                    .disabled(!proactiveEnabled)

                    Divider()

                    Toggle(isOn: $planFollowupEnabled) {
                        rowText(
                            "Plan follow-up",
                            "Missed-key-session and block-drift follow-ups"
                        )
                    }
                    .padding(.vertical, Spacing.sm)
                    .disabled(!proactiveEnabled)

                    Divider()

                    Toggle(isOn: $quietHoursEnabled) {
                        rowText(
                            "Quiet hours",
                            "Pause delivery during your local overnight window"
                        )
                    }
                    .padding(.vertical, Spacing.sm)
                    .disabled(!proactiveEnabled)

                    Divider()

                    HStack {
                        rowText("Quiet hours start", "Local time")
                        Spacer()
                        DatePicker(
                            "Quiet hours start",
                            selection: quietStartBinding,
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                        .datePickerStyle(.compact)
                    }
                    .padding(.vertical, Spacing.sm)
                    .disabled(!proactiveEnabled || !quietHoursEnabled)

                    Divider()

                    HStack {
                        rowText("Quiet hours end", "Local time")
                        Spacer()
                        DatePicker(
                            "Quiet hours end",
                            selection: quietEndBinding,
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                        .datePickerStyle(.compact)
                    }
                    .padding(.vertical, Spacing.sm)
                    .disabled(!proactiveEnabled || !quietHoursEnabled)

                    Divider()

                    HStack {
                        rowText("Timezone", "Used for quiet hours delivery")
                        Spacer()
                        Text(timezone)
                            .font(.cardCaption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, Spacing.sm)

                    if let syncError {
                        Divider()
                        Text(syncError)
                            .font(.cardCaption)
                            .foregroundStyle(.red)
                            .padding(.vertical, Spacing.sm)
                    }
                }
            }
        }
    }

    private var quietStartBinding: Binding<Date> {
        Binding(
            get: { dateFromLocalTime(quietHoursStart) },
            set: { quietHoursStart = localTimeString(from: $0) }
        )
    }

    private var quietEndBinding: Binding<Date> {
        Binding(
            get: { dateFromLocalTime(quietHoursEnd) },
            set: { quietHoursEnd = localTimeString(from: $0) }
        )
    }

    @ViewBuilder
    private func rowText(_ title: String, _ subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .font(.cardTitle)
            Text(subtitle)
                .font(.cardCaption)
                .foregroundStyle(.secondary)
        }
    }

    private func dateFromLocalTime(_ local: String) -> Date {
        let parts = local.split(separator: ":")
        let hour = Int(parts.first ?? "0") ?? 0
        let minute = Int(parts.dropFirst().first ?? "0") ?? 0
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }

    private func localTimeString(from date: Date) -> String {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        return String(format: "%02d:%02d", hour, minute)
    }
}

#Preview {
    SettingsCoachingNotificationsSection(
        proactiveEnabled: .constant(true),
        trainingMilestoneEnabled: .constant(true),
        trainingConcernEnabled: .constant(true),
        upcomingEventEnabled: .constant(true),
        reengagementEnabled: .constant(true),
        planFollowupEnabled: .constant(true),
        quietHoursEnabled: .constant(true),
        quietHoursStart: .constant("22:00"),
        quietHoursEnd: .constant("07:00"),
        timezone: TimeZone.current.identifier,
        syncError: nil
    )
    .padding()
}
