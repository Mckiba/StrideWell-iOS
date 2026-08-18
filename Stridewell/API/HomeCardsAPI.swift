//
//  HomeCardsAPI.swift
//  Stridewell
//

import Foundation

extension APIClient {

    /// Fetch weather/home cards for a coordinate. `units` is "metric" or "imperial"
    func homeCards(lat: Double, lng: Double, units: String) async -> ApiResult<HomeCardsResponse> {
        await get(path: "\(APIEndpoints.homeCards)?lat=\(lat)&lng=\(lng)&units=\(units)")
    }
}
