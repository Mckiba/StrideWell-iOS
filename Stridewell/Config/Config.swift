//
//  Config.swift
//  Stridewell
//

import Foundation

enum Config {

    static var baseURL: URL {
        #if DEBUG
        URL(string: "http://localhost:3000")!
        #else
        URL(string: "https://your-backend.fly.dev")!
        #endif
    }

    static let appScheme = "stridewell"
    static let stravaRedirectURI = "stridewell://oauth/strava/callback"
}
