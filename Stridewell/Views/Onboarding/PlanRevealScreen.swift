//
//  PlanRevealScreen.swift
//  Stridewell
//

import SwiftUI

struct PlanRevealScreen: View {

    @Environment(\.onboardingStore) private var onboardingStore
    @Environment(\.apiClient) private var apiClient

    @State private var screenState: ScreenState = .loading
    @State private var confirmError: String? = nil
    @State private var retryTrigger = false

    enum ScreenState {
        case loading
        case loaded(PlanVersionResponse)
        case confirming
        case error(String)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            switch screenState {
            case .loading:
                loadingView

            case .loaded(let plan):
                planContent(plan)

            case .confirming:
                // Keep plan visible while confirming — only button changes
                if case .loaded(let plan) = screenState {
                    planContent(plan)
                }
                loadingView  // fallback (shouldn't show)

            case .error(let message):
                errorView(message)
            }
        }
        .navigationTitle("Your plan")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .task(id: retryTrigger) { await fetchPlan() }
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
            Button("Try again") { retryTrigger.toggle() }
                .buttonStyle(.bordered)
            Spacer()
        }
    }

    // MARK: - Plan Content

    private func planContent(_ plan: PlanVersionResponse) -> some View {
        let isConfirming = { if case .confirming = screenState { return true }; return false }()
        let days = plan.weeks.first?.days ?? []

        return ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {

                // Coach notes card
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

                // Plan days
                Divider().padding(.leading, 16)
                ForEach(days) { day in
                    WorkoutCardView(day: day)
                    Divider().padding(.leading, 68)
                }

                // Why this plan
                if let bullets = plan.rationale_bullets, !bullets.isEmpty {
                    rationaleSection(bullets)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                }

                // Warning flags
                if let flags = plan.warning_flags, !flags.isEmpty {
                    warningSection(flags)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                }

                // Bottom padding for the sticky button
                Color.clear.frame(height: 96)
            }
        }
        // Sticky "Start training" button
        .overlay(alignment: .bottom) {
            VStack(spacing: 4) {
                if let err = confirmError {
                    Text(err)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                Button {
                    Task { await confirmPlan(plan) }
                } label: {
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
                        .foregroundStyle(.yellow)
                    Text(flag)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(12)
        .background(Color.yellow.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - API

    private func fetchPlan() async {
        guard let planVersionId = onboardingStore.firstPlanVersionId else {
            screenState = .error("Plan ID not available. Please go back and try again.")
            return
        }
        screenState = .loading
        let result: ApiResult<PlanVersionResponse> = await apiClient.planVersion(
            id: planVersionId,
            weeks: 1
        )
        switch result {
        case .success(let plan):
            screenState = .loaded(plan)
        case .failure(_, let message):
            screenState = .error(message)
        }
    }

    private func confirmPlan(_ plan: PlanVersionResponse) async {
        guard let planVersionId = onboardingStore.firstPlanVersionId else { return }
        confirmError = nil
        screenState = .confirming

        let result: ApiResult<ConfirmPlanResponse> = await apiClient.confirmPlan(
            planVersionId: planVersionId
        )
        switch result {
        case .success:
            // RootView observes onboardingStore.isComplete and re-routes automatically
            onboardingStore.markComplete()
        case .failure(_, let message):
            confirmError = message
            screenState = .loaded(plan)
        }
    }
}
