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

    /// PUT /profile/proactive-preferences
    func putProactivePreferences(_ body: ProactivePreferencesRequest) async -> ApiResult<ProactivePreferencesStoredResponse> {
        await request("PUT", path: APIEndpoints.proactivePreferences, body: body)
    }

    /// PUT /profile/units — persists the athlete's distance unit preference.
    func setMeasurementSystem(_ system: UnitSystem) async -> ApiResult<UserUnitsResponse> {
        await request("PUT", path: APIEndpoints.profileUnits, body: UserUnitsRequest(measurement_system: system.rawValue))
    }
}

// MARK: - Units DTOs

struct UserUnitsRequest: Encodable {
    let measurement_system: String
}

struct UserUnitsResponse: Decodable {
    let measurement_system: String
}
