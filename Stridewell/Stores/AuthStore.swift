//
//  AuthStore.swift
//  Stridewell
//

import Foundation
import Observation

@Observable
final class AuthStore {

    // MARK: - State

    private(set) var token: String?
    private(set) var refreshToken: String?
    private(set) var accessTokenExpiresAt: Int?
    private(set) var userId: String?

    /// False until the Keychain read finishes. RootView waits on this
    /// before routing, preventing a flash of the wrong stack at launch.
    private(set) var authCheckComplete: Bool = false

    var isAuthenticated: Bool { token != nil }

    // MARK: - Init

    init() {
        // Synchronous Keychain read — completes in < 1ms in practice.
        token = KeychainStore.loadToken()
        refreshToken = KeychainStore.loadRefreshToken()
        accessTokenExpiresAt = KeychainStore.loadAccessTokenExpiry()
        userId = KeychainStore.loadUserId()
        authCheckComplete = true
    }

    // MARK: - Actions

    func signIn(session: AuthSessionResponse) {
        KeychainStore.saveToken(session.access_token)
        KeychainStore.saveRefreshToken(session.refresh_token)
        if let expiresAt = session.expires_at {
            KeychainStore.saveAccessTokenExpiry(expiresAt)
        } else {
            KeychainStore.deleteAccessTokenExpiry()
        }
        KeychainStore.saveUserId(session.user_id)

        token = session.access_token
        refreshToken = session.refresh_token
        accessTokenExpiresAt = session.expires_at
        userId = session.user_id
    }

    /// Compatibility helper for call sites that only have a token.
    func signIn(token: String, userId: String) {
        KeychainStore.saveToken(token)
        KeychainStore.deleteRefreshToken()
        KeychainStore.deleteAccessTokenExpiry()
        KeychainStore.saveUserId(userId)

        self.token = token
        self.refreshToken = nil
        self.accessTokenExpiresAt = nil
        self.userId = userId
    }

    func updateSession(
        accessToken: String,
        refreshToken: String,
        expiresAt: Int?
    ) {
        KeychainStore.saveToken(accessToken)
        KeychainStore.saveRefreshToken(refreshToken)
        if let expiresAt {
            KeychainStore.saveAccessTokenExpiry(expiresAt)
        } else {
            KeychainStore.deleteAccessTokenExpiry()
        }

        token = accessToken
        self.refreshToken = refreshToken
        accessTokenExpiresAt = expiresAt
    }

    func signOut() {
        KeychainStore.clearAll()
        token = nil
        refreshToken = nil
        accessTokenExpiresAt = nil
        userId = nil
    }

    /// Called by APIClient when refresh cannot recover from auth failure.
    func handle401() {
        signOut()
    }
}
