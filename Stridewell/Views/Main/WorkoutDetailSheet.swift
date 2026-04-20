//
//  WorkoutDetailSheet.swift
//  Stridewell
//
//  M8: Detail modal shown when tapping a workout day in PlanScreen.
//  Basic layout — design work comes later.
//

import SwiftUI

struct WorkoutDetailSheet: View {

    let day: PlanDay

    @Environment(\.dismiss) private var dismiss
    @Environment(\.settingsStore) private var settingsStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    headerSection
                    typeBadge

                    if let description = day.workout.description {
                        descriptionSection(description)
                    }

                    if hasTargets {
                        targetsSection
                    }

                    if let intensity = day.workout.intensity {
                        intensityRow(intensity)
                    }

                    if let dayNotes = day.notes {
                        notesSection("Day Notes", text: dayNotes)
                    }
                    if let workoutNotes = day.workout.notes {
                        notesSection("Workout Notes", text: workoutNotes)
                    }
                }
                .padding(Spacing.md)
            }
            .navigationTitle(day.workout.label)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(formattedDate)
                .font(.sectionTitle)
            Text(day.workout.label)
                .font(.screenTitle)
        }
    }

    private var typeBadge: some View {
        Text(day.workout.type.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.accentColor.opacity(0.15))
            .foregroundStyle(Color.accentColor)
            .clipShape(Capsule())
    }

    private func descriptionSection(_ text: String) -> some View {
        CardView {
            Text(text)
                .font(.cardBody)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var hasTargets: Bool {
        day.workout.target_distance_m != nil ||
        day.workout.target_pace_s_per_km != nil ||
        day.workout.target_pace_range != nil ||
        day.workout.target_duration_s != nil
    }

    private var targetsSection: some View {
        let unit = settingsStore.unitSystem
        return CardView {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Targets")
                    .font(.cardTitle)

                if let d = day.workout.target_distance_m {
                    targetRow(label: "Distance", value: FormatUtils.distance(d, unit: unit))
                }
                // Prefer pace range (V2) over single pace (V1 legacy).
                if let range = day.workout.target_pace_range {
                    targetRow(
                        label: "Pace",
                        value: FormatUtils.paceRange(min: range.min_s_per_km, max: range.max_s_per_km, unit: unit)
                    )
                } else if let p = day.workout.target_pace_s_per_km {
                    targetRow(label: "Pace", value: FormatUtils.pace(p, unit: unit))
                }
                if let effort = day.workout.effort_level {
                    targetRow(
                        label: "Effort",
                        value: effort.replacingOccurrences(of: "_", with: " ").capitalized
                    )
                }
                if let dur = day.workout.target_duration_s {
                    targetRow(label: "Duration", value: FormatUtils.duration(dur))
                }
            }
        }
    }

    private func targetRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.cardBody)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.cardBody.weight(.semibold))
        }
    }

    private func intensityRow(_ intensity: WorkoutIntensity) -> some View {
        CardView {
            HStack {
                Text("Intensity")
                    .font(.cardBody)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(intensity.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.cardBody.weight(.semibold))
            }
        }
    }

    private func notesSection(_ title: String, text: String) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(.cardTitle)
                Text(text)
                    .font(.cardBody)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Date Formatting

    private var formattedDate: String {
        guard let date = DateUtils.parse(day.date) else { return day.date }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"  // "Monday, March 3"
        return formatter.string(from: date)
    }
}
