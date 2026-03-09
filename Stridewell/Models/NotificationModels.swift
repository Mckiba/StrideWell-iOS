//
//  NotificationModels.swift
//  Stridewell
//

import Foundation

struct NotificationRegisterRequest: Encodable {
    let device_token: String
    let platform: String = "ios"
}

struct NotificationRegisterResponse: Decodable {
    let registered: Bool
}
