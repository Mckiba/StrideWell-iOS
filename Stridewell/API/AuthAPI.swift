//
//  AuthAPI.swift
//  Stridewell
//

import Foundation

// MARK: - Request / Response Types

/// Response shape for GET /auth/me.
struct MeResponse: Decodable {
    let id: String
    let email: String?
    let onboarding_status: OnboardingStatus?
}

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

struct ForgotPasswordRequest: Encodable {
    let email: String
}

struct ForgotPasswordResponse: Decodable {
    let message: String
}

struct ResetPasswordRequest: Encodable {
    let password: String
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

    /// Validates the stored JWT and returns the current user profile.
    /// A 401 response triggers the onUnauthorized handler, clearing auth state.
    func me() async -> ApiResult<MeResponse> {
        await get(path: APIEndpoints.me)
    }

    func forgotPassword(email: String) async -> ApiResult<ForgotPasswordResponse> {
        await post(
            path: APIEndpoints.forgotPassword,
            body: ForgotPasswordRequest(email: email)
        )
    }

    /// Updates the user's password using their Supabase recovery token.
    /// Uses the recovery token as the Bearer — NOT the keychain token — so this
    /// bypasses the normal `request()` method and makes a direct URLRequest.
    func resetPassword(newPassword: String, recoveryToken: String) async -> ApiResult<LoginResponse> {
        guard let url = URL(string: APIEndpoints.resetPassword, relativeTo: Config.baseURL) else {
            return .failure(status: 0, message: "Invalid URL")
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(recoveryToken)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            req.httpBody = try JSONEncoder().encode(ResetPasswordRequest(password: newPassword))
        } catch {
            return .failure(status: 0, message: "Encoding error: \(error.localizedDescription)")
        }
        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            guard let http = response as? HTTPURLResponse else {
                return .failure(status: 0, message: "Non-HTTP response")
            }
            guard (200..<300).contains(http.statusCode) else {
                struct BE: Decodable { let error: String? }
                let msg = (try? JSONDecoder().decode(BE.self, from: data))?.error
                    ?? HTTPURLResponse.localizedString(forStatusCode: http.statusCode)
                return .failure(status: http.statusCode, message: msg)
            }
            let decoded = try JSONDecoder().decode(LoginResponse.self, from: data)
            return .success(decoded)
        } catch let urlError as URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .timedOut:
                return .failure(status: 0, message: "No internet connection. Please check your network.")
            default:
                return .failure(status: 0, message: "Network error: \(urlError.localizedDescription)")
            }
        } catch {
            return .failure(status: 0, message: "Unexpected error: \(error.localizedDescription)")
        }
    }
}
