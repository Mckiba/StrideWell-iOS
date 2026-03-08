//
//  PlanRevealScreen.swift
//  Stridewell
//

import SwiftUI

struct PlanRevealScreen: View {

    @Environment(\.onboardingStore) private var onboardingStore
    @Environment(\.apiClient) private var apiClient

    @State private var screenState: PlanRevealContent.ScreenState = .loading
    @State private var confirmError: String? = nil
    @State private var retryTrigger = false
    @State private var loadedPlan: PlanVersionResponse? = nil

    var body: some View {
        PlanRevealContent(
            screenState: screenState,
            confirmError: confirmError,
            onConfirm: { Task { await confirmPlan() } },
            onRetry: { retryTrigger.toggle() }
        )
        .navigationTitle("Your plan")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .task(id: retryTrigger) { await fetchPlan() }
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
            loadedPlan = plan
            screenState = .loaded(plan)
        case .failure(_, let message):
            screenState = .error(message)
        }
    }

    private func confirmPlan() async {
        guard let planVersionId = onboardingStore.firstPlanVersionId,
              let plan = loadedPlan else { return }
        confirmError = nil
        screenState = .confirming(plan)

        let result: ApiResult<ConfirmPlanResponse> = await apiClient.confirmPlan(
            planVersionId: planVersionId
        )
        switch result {
        case .success:
            onboardingStore.markComplete()
        case .failure(_, let message):
            confirmError = message
            screenState = .loaded(plan)
        }
    }
}
