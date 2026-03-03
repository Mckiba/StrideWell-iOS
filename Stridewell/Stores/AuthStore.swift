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
    private(set) var userId: String?

    /// False until the Keychain read finishes. RootView waits on this
    /// before routing, preventing a flash of the wrong stack at launch.
    private(set) var authCheckComplete: Bool = false

    var isAuthenticated: Bool { token != nil }

    // MARK: - Init

    init() {
        // Synchronous Keychain read — completes in < 1ms in practice.
        token = KeychainStore.loadToken()
        userId = KeychainStore.loadUserId()
        authCheckComplete = true
    }

    // MARK: - Actions

    func signIn(token: String, userId: String) {
        KeychainStore.saveToken(token)
        KeychainStore.saveUserId(userId)
        self.token = token
        self.userId = userId
    }

    func signOut() {
        KeychainStore.clearAll()
        token = nil
        userId = nil
    }

    /// Called by APIClient on HTTP 401. Named separately from signOut
    /// so token-refresh logic can be added here independently in future.
    func handle401() {
        signOut()
    }
}
