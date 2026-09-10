//
//  Config.swift
//  Stridewell
//

import Foundation

enum Config {

    static var baseURL: URL {
        #if DEBUG
        // The LAN address of the dev machine changes with the network, so allow an
        // override without editing this file: pass `-api_base_url http://host:3000`
        // in the scheme's launch arguments, or on the simulator with
        // `simctl launch <udid> com.stridewell -api_base_url http://localhost:3000`.
        if let override = UserDefaults.standard.string(forKey: "api_base_url"),
           let url = URL(string: override) {
            return url
        }
        return URL(string: "http://10.174.25.59:3000")!
        #else
        return URL(string: "https://stridewell-api-production.up.railway.app")!
        #endif
    }

    // Replace with your Mapbox public token (pk.xxx) before building.
    // Set once at app startup via MapboxOptions.accessToken = Config.mapboxPublicToken.
    static let mapboxPublicToken = "pk.eyJ1IjoibWNraWJhIiwiYSI6ImNtb2h2cXMyOTAwM3oycm9haDgwODEzcngifQ.dZUOWGebonQxa6xP2VDUmA"

    static let appScheme = "stridewell"
    static let stravaRedirectURI = "stridewell://localhost"
    static let stravaClientId = "270877"   // replace before release

    static var stravaAuthURL: URL? {
        var components = URLComponents(string: "https://www.strava.com/oauth/authorize")
        components?.queryItems = [
            URLQueryItem(name: "client_id",       value: stravaClientId),
            URLQueryItem(name: "response_type",   value: "code"),
            URLQueryItem(name: "redirect_uri",    value: stravaRedirectURI),
            URLQueryItem(name: "approval_prompt", value: "auto"),
            URLQueryItem(name: "scope",           value: "activity:read_all"),
        ]
        return components?.url
    }
}
