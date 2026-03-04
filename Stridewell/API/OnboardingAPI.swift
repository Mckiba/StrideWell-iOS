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
}
