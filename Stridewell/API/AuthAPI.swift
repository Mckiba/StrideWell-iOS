//
//  AuthAPI.swift
//  Stridewell
//

import Foundation

// MARK: - Request / Response Types

struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct LoginResponse: Decodable {
    let token: String
    let user_id: String
}

// MARK: - APIClient Extension

extension APIClient {

    func login(email: String, password: String) async -> ApiResult<LoginResponse> {
        await post(
            path: APIEndpoints.login,
            body: LoginRequest(email: email, password: password)
        )
    }
}
