//
//  AuthAPI.swift
//  Stridewell
//

import Foundation

// MARK: - Request / Response Types

struct RegisterRequest: Encodable {
    let email: String
    let password: String
}

struct LoginRequest: Encodable {
    let email: String
    let password: String
}

/// Shared response shape for /auth/register and /auth/login.
struct LoginResponse: Decodable {
    let token: String
    let user_id: String
}

// MARK: - APIClient Extension

extension APIClient {

    func register(email: String, password: String) async -> ApiResult<LoginResponse> {
        await post(
            path: APIEndpoints.register,
            body: RegisterRequest(email: email, password: password)
        )
    }

    func login(email: String, password: String) async -> ApiResult<LoginResponse> {
        await post(
            path: APIEndpoints.login,
            body: LoginRequest(email: email, password: password)
        )
    }
}
