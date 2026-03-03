//
//  OnboardingAPI.swift
//  Stridewell
//

import Foundation

extension APIClient {

    func onboardingStatus() async -> ApiResult<OnboardingState> {
        await get(path: APIEndpoints.onboardingStatus)
    }
}
