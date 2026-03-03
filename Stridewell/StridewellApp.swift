//
//  StridewellApp.swift
//  Stridewell
//
//  Created by McKiba Williams on 2/20/26.
//

import SwiftUI

// MARK: - Environment Keys

extension EnvironmentValues {
    @Entry var authStore: AuthStore = AuthStore()
    @Entry var apiClient: APIClient = APIClient(tokenProvider: { nil }, onUnauthorized: {})
}

// MARK: - App

@main
struct StridewellApp: App {

    @State private var authStore: AuthStore
    private let apiClient: APIClient

    init() {
        let store = AuthStore()
        let client = APIClient(
            tokenProvider: { store.token },
            onUnauthorized: { store.handle401() }
        )
        _authStore = State(wrappedValue: store)
        apiClient = client
    }

    var body: some Scene {
        WindowGroup {
            RootView(authStore: authStore)
                .environment(\.authStore, authStore)
                .environment(\.apiClient, apiClient)
        }
    }
}
