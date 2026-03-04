//
//  Config.swift
//  Stridewell
//

import Foundation

enum Config {

    static var baseURL: URL {
        #if DEBUG
        URL(string: "http://10.0.0.112:3000")!
        #else
        URL(string: "http://localhost:3000")!
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
