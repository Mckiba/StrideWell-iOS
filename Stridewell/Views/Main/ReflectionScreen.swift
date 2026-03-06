//
//  ReflectionScreen.swift
//  Stridewell
//
//  M9: Daily check-in form — fatigue, sleep quality, mood, soreness, notes.
//  Presented as a sheet from HomeScreen. Must feel like a 30-second interaction.
//

import SwiftUI

// MARK: - Mood Selector

private enum MoodSelection: Int, CaseIterable {
    case low = 3
    case neutral = 5
    case good = 8

    var label: String {
        switch self {
        case .low:     return "Low"
        case .neutral: return "Neutral"
        case .good:    return "Good"
        }
    }

    var icon: String {
        switch self {
        case .low:     return "cloud.rain"
        case .neutral: return "cloud.sun"
        case .good:    return "sun.max"
        }
    }
}

// MARK: - ReflectionScreen

struct ReflectionScreen: View {

    @Environment(\.apiClient) private var apiClient
    @Environment(\.dismiss) private var dismiss

    // MARK: - Form State

    @State private var fatigue: Double = 5
    @State private var sleepQuality: Double = 5
    @State private var mood: MoodSelection = .neutral
    @State private var sorenessEntries: [SorenessFormEntry] = []
    @State private var freeText: String = ""

    // MARK: - Submission State

    @State private var isSubmitting = false
    @State private var errorMessage: String? = nil
    @State private var showSuccess = false

    var body: some View {
        NavigationStack {
            Group {
                if showSuccess {
                    successView
                } else {
                    formContent
                }
            }
            .navigationTitle("Daily Check-in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !showSuccess {
                        Button("Cancel") { dismiss() }
                    }
                }
            }
        }
    }

    // MARK: - Form Content

    private var formContent: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                fatigueSection
                sleepQualitySection
                moodSection
                sorenessSection
                notesSection
                submitButton
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.md)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Fatigue

    private var fatigueSection: some View {
        CardView {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Text("Fatigue")
                        .font(.cardTitle)
                    Spacer()
                    Text("\(Int(fatigue))")
                        .font(.cardBody)
                        .foregroundStyle(.secondary)
                }
                Slider(value: $fatigue, in: 1...10, step: 1)
                HStack {
                    Text("Fresh")
                        .font(.cardCaption)
                        .foregroundStyle(.tertiary)
                    Spacer()
                    Text("Exhausted")
                        .font(.cardCaption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    // MARK: - Sleep Quality

    private var sleepQualitySection: some View {
        CardView {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Text("Sleep Quality")
                        .font(.cardTitle)
                    Spacer()
                    Text("\(Int(sleepQuality))")
                        .font(.cardBody)
                        .foregroundStyle(.secondary)
                }
                Slider(value: $sleepQuality, in: 1...10, step: 1)
                HStack {
                    Text("Poor")
                        .font(.cardCaption)
                        .foregroundStyle(.tertiary)
                    Spacer()
                    Text("Great")
                        .font(.cardCaption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    // MARK: - Mood

    private var moodSection: some View {
        CardView {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Mood")
                    .font(.cardTitle)
                HStack(spacing: Spacing.md) {
                    ForEach(MoodSelection.allCases, id: \.self) { option in
                        Button {
                            mood = option
                        } label: {
                            VStack(spacing: Spacing.xs) {
                                Image(systemName: option.icon)
                                    .font(.title2)
                                Text(option.label)
                                    .font(.cardCaption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.sm)
                            .background(
                                mood == option
                                    ? Color.accentColor.opacity(0.15)
                                    : Color.clear
                            )
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(mood == option ? Color.accentColor : .secondary)
                    }
                }
            }
        }
    }

    // MARK: - Soreness

    private var sorenessSection: some View {
        CardView {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Soreness")
                    .font(.cardTitle)

                ForEach($sorenessEntries) { $entry in
                    sorenessRow(entry: $entry)
                }

                Button {
                    sorenessEntries.append(SorenessFormEntry())
                } label: {
                    Label("Add body part", systemImage: "plus.circle")
                        .font(.cardBody)
                }
            }
        }
    }

    private func sorenessRow(entry: Binding<SorenessFormEntry>) -> some View {
        VStack(spacing: Spacing.xs) {
            HStack {
                TextField("Body part (e.g. left knee)", text: entry.location)
                    .font(.cardBody)
                    .textFieldStyle(.roundedBorder)
                Button {
                    sorenessEntries.removeAll { $0.id == entry.wrappedValue.id }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
            HStack {
                Slider(value: entry.score, in: 1...10, step: 1)
                Text("\(Int(entry.wrappedValue.score))")
                    .font(.cardCaption)
                    .foregroundStyle(.secondary)
                    .frame(width: 24)
            }
        }
    }

    // MARK: - Notes

    private var notesSection: some View {
        CardView {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("How are you feeling? Any pain or tightness?")
                    .font(.cardTitle)
                TextEditor(text: $freeText)
                    .frame(minHeight: 80)
                    .font(.cardBody)
                    .scrollContentBackground(.hidden)
                    .onChange(of: freeText) { _, newValue in
                        if newValue.count > 2000 {
                            freeText = String(newValue.prefix(2000))
                        }
                    }
            }
        }
    }

    // MARK: - Submit

    private var submitButton: some View {
        VStack(spacing: Spacing.sm) {
            if let error = errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task { await submit() }
            } label: {
                Group {
                    if isSubmitting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Submit check-in")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isSubmitting)
        }
    }

    // MARK: - Success View

    private var successView: some View {
        VStack(spacing: Spacing.md) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)
            Text("Check-in recorded")
                .font(.sectionTitle)
            Text("Thanks! This helps your plan stay on track.")
                .font(.cardBody)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.horizontal, Spacing.xl)
    }

    // MARK: - Submission Logic

    private func submit() async {
        isSubmitting = true
        errorMessage = nil

        let sorenessPayload = sorenessEntries.compactMap { $0.toSubmission() }
        let trimmedText = freeText.trimmingCharacters(in: .whitespacesAndNewlines)

        let submission = ReflectionSubmission(
            fatigue: Int(fatigue),
            sleep_quality: Int(sleepQuality),
            mood: mood.rawValue,
            soreness: sorenessPayload.isEmpty ? nil : sorenessPayload,
            free_text: trimmedText.isEmpty ? nil : trimmedText,
            related_run_id: nil
        )

        let result = await apiClient.submitReflection(submission)

        switch result {
        case .success:
            showSuccess = true
            try? await Task.sleep(for: .seconds(1.5))
            dismiss()

        case .failure(_, let message):
            errorMessage = message
            isSubmitting = false
        }
    }
}
