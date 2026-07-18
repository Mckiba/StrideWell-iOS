//
//  PlanRevealContent.swift
//  Stridewell
//

import SwiftUI

struct PlanRevealContent: View {

    let screenState: ScreenState
    let confirmError: String?
    var onConfirm: () -> Void = {}
    var onRetry: () -> Void = {}

    enum ScreenState {
        case loading
        case loaded(PlanVersionResponse)
        case confirming(PlanVersionResponse)
        case error(String)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            switch screenState {
            case .loading:
                loadingView

            case .loaded(let plan):
                planContent(plan, isConfirming: false)

            case .confirming(let plan):
                planContent(plan, isConfirming: true)

            case .error(let message):
                errorView(message)
            }
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView("Building preview…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    // MARK: - Error

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Try again", action: onRetry)
                .buttonStyle(.bordered)
            Spacer()
        }
    }

    // MARK: - Plan Content

    private func planContent(_ plan: PlanVersionResponse, isConfirming: Bool) -> some View {
        let days = plan.weeks.first?.days ?? []

        return ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {

                if let notes = plan.coaching_notes {
                    coachCard(notes, phaseLabel: plan.phase_label)
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                        .padding(.bottom, 16)
                } else if let label = plan.phase_label {
                    phaseBadge(label)
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                        .padding(.bottom, 12)
                }

                Divider().padding(.leading, 16)
                ForEach(days) { day in
                    WorkoutCard(day: day)
                    Divider().padding(.leading, 68)
                }

                if let bullets = plan.rationale_bullets, !bullets.isEmpty {
                    rationaleSection(bullets)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                }

                if let flags = plan.warning_flags, !flags.isEmpty {
                    warningSection(flags)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                }

                Color.clear.frame(height: 96)
            }
        }
        .overlay(alignment: .bottom) {
            VStack(spacing: 4) {
                if let err = confirmError {
                    Text(err)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                Button(action: onConfirm) {
                    Group {
                        if isConfirming {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Start training")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isConfirming)
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .background(.regularMaterial)
        }
    }

    // MARK: - Sub-views

    private func coachCard(_ notes: String, phaseLabel: String?) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if let label = phaseLabel {
                phaseBadge(label)
            }
            Text(notes)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func phaseBadge(_ label: String) -> some View {
        Text(label.replacingOccurrences(of: "_", with: " ").capitalized)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.accentColor.opacity(0.15))
            .foregroundStyle(Color.accentColor)
            .clipShape(Capsule())
    }

    private func rationaleSection(_ bullets: [String]) -> some View {
        DisclosureGroup("Why this plan?") {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(bullets, id: \.self) { bullet in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text(bullet)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.top, 8)
        }
        .font(.subheadline.weight(.medium))
    }

    private func warningSection(_ flags: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(flags, id: \.self) { flag in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                    Text(flag)
                        .font(.caption)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(12)
        .background(Color.red.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Previews

private let mockPlan = PlanVersionResponse(
    plan_version_id: "pv_preview",
    source: .architect,
    start_date: "2026-03-10",
    horizon_days: 7,
    phase_label: "base_building",
    coaching_notes: "We're starting with a gentle base-building phase to establish your aerobic foundation before adding intensity.",
    rationale_bullets: [
        "Your recent weekly mileage of 25 km suggests a solid foundation",
        "Building to 35 km/week over 4 weeks before adding tempo work",
        "Rest days placed after back-to-back run days for recovery"
    ],
    warning_flags: ["Avoid running on consecutive days if shin pain returns"],
    weeks: [
        PlanVersionWeek(
            week_number: 1,
            start_date: "2026-03-10",
            days: [
                PlanDay(date: "2026-03-10", workout: Workout(type: .easy, label: "Easy Run", description: "Relaxed pace, focus on form", target_distance_m: 5000, target_duration_s: 1800, target_pace_s_per_km: 360, intensity: .easy, notes: nil), notes: nil),
                PlanDay(date: "2026-03-11", workout: Workout(type: .rest, label: "Rest Day", description: nil, target_distance_m: nil, target_duration_s: nil, target_pace_s_per_km: nil, intensity: .very_easy, notes: nil), notes: nil),
                PlanDay(date: "2026-03-12", workout: Workout(type: .tempo, label: "Tempo Run", description: "Warm up 10 min, tempo 20 min, cool down 10 min", target_distance_m: 8000, target_duration_s: 2400, target_pace_s_per_km: 300, intensity: .moderate, notes: "Keep tempo effort conversational-plus"), notes: nil),
            ]
        )
    ]
)

#Preview("Loading") {
    NavigationStack {
        PlanRevealContent(screenState: .loading, confirmError: nil)
            .navigationTitle("Your plan")
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Loaded") {
    NavigationStack {
        PlanRevealContent(screenState: .loaded(mockPlan), confirmError: nil)
            .navigationTitle("Your plan")
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Confirm Error") {
    NavigationStack {
        PlanRevealContent(
            screenState: .loaded(mockPlan),
            confirmError: "Failed to confirm plan. Please try again."
        )
        .navigationTitle("Your plan")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Error") {
    NavigationStack {
        PlanRevealContent(
            screenState: .error("Could not load your plan. Please try again."),
            confirmError: nil
        )
        .navigationTitle("Your plan")
        .navigationBarTitleDisplayMode(.inline)
    }
}
