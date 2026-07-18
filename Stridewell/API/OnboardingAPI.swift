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

    /// Sends one intake turn. `screenContext` tells the coach which topic the screen
    /// is on; `structuredFields` carries values picked from controls. Both default to
    /// nil, which sends a plain free-text turn.
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
