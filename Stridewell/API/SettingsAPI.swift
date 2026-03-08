//
//  SettingsAPI.swift
//  Stridewell
//
//  APIClient extension for settings-related endpoints.
//

import Foundation

extension APIClient {

    /// GET /auth/strava-status
    func stravaStatus() async -> ApiResult<StravaStatusResponse> {
        await get(path: APIEndpoints.stravaStatus)
    }

    /// POST /oauth/strava/disconnect
    func stravaDisconnect() async -> ApiResult<StravaDisconnectResponse> {
        await request("POST", path: APIEndpoints.stravaDisconnect)
    }

    /// DELETE /auth/account — returns 204 No Content
    func deleteAccount() async -> ApiResult<EmptyResponse> {
        await request("DELETE", path: APIEndpoints.deleteAccount)
    }
}
