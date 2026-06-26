//
//  OnboardingAPI.swift
//  Stridewell
//

import Foundation

extension APIClient {

    func startOnboarding() async -> ApiResult<OnboardingStartResponse> {
        await request("POST", path: APIEndpoints.onboardingStart)
    }

    func onboardingStatus() async -> ApiResult<OnboardingState> {
        await get(path: APIEndpoints.onboardingStatus)
    }

    func stravaConnect(code: String) async -> ApiResult<StravaConnectResponse> {
        await post(path: APIEndpoints.stravaConnect, body: StravaConnectRequest(code: code))
    }

    /// Sends an intake turn. `screenContext` keeps the Coach on the current guided
    /// screen's topic; `structuredFields` carries deterministic selections. Both
    /// default to nil → a V1-shaped request.
    func sendOnboardingMessage(
        conversationId: String,
        message: InterviewMessage,
        screenContext: String? = nil,
        structuredFields: StructuredFields? = nil
    ) async -> ApiResult<OnboardingMessageResponse> {
        await post(
            path: APIEndpoints.onboardingMessage,
            body: OnboardingMessageRequest(
                conversation_id: conversationId,
                message: message,
                screen_context: screenContext,
                structured_fields: structuredFields
            )
        )
    }

    func skipOnboarding() async -> ApiResult<OnboardingSkipResponse> {
        await request("POST", path: APIEndpoints.onboardingSkip)
    }

    func confirmPlan(planVersionId: String) async -> ApiResult<ConfirmPlanResponse> {
        await post(
            path: APIEndpoints.onboardingConfirm,
            body: ConfirmPlanRequest(plan_version_id: planVersionId)
        )
    }
}

// MARK: - Private request types

private struct ConfirmPlanRequest: Encodable {
    let plan_version_id: String
}
