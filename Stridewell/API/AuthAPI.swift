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

struct AppleSignInRequest: Encodable {
    let id_token: String
    let nonce: String
}

struct GoogleSignInRequest: Encodable {
    let id_token: String
    let nonce: String
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

    func appleSignIn(idToken: String, nonce: String) async -> ApiResult<LoginResponse> {
        await post(
            path: APIEndpoints.appleSignIn,
            body: AppleSignInRequest(id_token: idToken, nonce: nonce)
        )
    }

    func googleSignIn(idToken: String, nonce: String) async -> ApiResult<LoginResponse> {
        await post(
            path: APIEndpoints.googleSignIn,
            body: GoogleSignInRequest(id_token: idToken, nonce: nonce)
        )
    }
}
