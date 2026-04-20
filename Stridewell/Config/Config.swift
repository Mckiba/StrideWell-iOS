//
//  Config.swift
//  Stridewell
//

import Foundation

enum Config {

    static var baseURL: URL {
        #if DEBUG
        URL(string: "https://stridewell-api-production.up.railway.app")!
        #else
        URL(string: "https://stridewell-api-production.up.railway.app")!
        #endif
    }

    static let appScheme = "stridewell"
    static let stravaRedirectURI = "stridewell://localhost"
    static let stravaClientId = "204378"   // replace before release

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
