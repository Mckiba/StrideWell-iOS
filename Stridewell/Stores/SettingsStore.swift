//
//  SettingsStore.swift
//  Stridewell
//
//  Centralized state and actions for the Settings screen.
//  Views read state and call action methods — no API calls or business
//  logic lives in the view layer.
//

import Foundation
import SwiftUI

// MARK: - AppTheme

enum AppTheme: String, CaseIterable {
    case device
    case light
    case dark

    var label: String {
        switch self {
        case .device: return "Device"
        case .light:  return "Light"
        case .dark:   return "Dark"
        }
    }

    /// Maps to `preferredColorScheme` — nil follows the system setting.
    var colorScheme: ColorScheme? {
        switch self {
        case .device: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

// MARK: - SettingsStore

@Observable
final class SettingsStore {

    // MARK: - Strava Connection

    enum StravaState: Equatable {
        case loading
        case disconnected
        case connected(expiresAt: String?, scope: String?)
        case expired(expiresAt: String, scope: String?)
        case connecting
        case disconnecting
        case error(String)
    }

    private(set) var stravaState: StravaState = .loading

    // MARK: - Unit System Preference

    var unitSystem: UnitSystem {
        didSet { UserDefaults.standard.set(unitSystem.rawValue, forKey: Self.unitSystemKey) }
    }

    // MARK: - Notification Preferences (local-only V1)

    var reflectionReminders: Bool {
        didSet { UserDefaults.standard.set(reflectionReminders, forKey: Self.reflectionRemindersKey) }
    }

    var planUpdateAlerts: Bool {
        didSet { UserDefaults.standard.set(planUpdateAlerts, forKey: Self.planUpdateAlertsKey) }
    }

    // MARK: - Appearance

    var appTheme: AppTheme {
        didSet { UserDefaults.standard.set(appTheme.rawValue, forKey: Self.appThemeKey) }
    }

    // MARK: - Account Deletion

    enum DeleteState: Equatable {
        case idle
        case deleting
        case error(String)
    }

    private(set) var deleteState: DeleteState = .idle

    // MARK: - Persistence Keys

    private static let unitSystemKey          = "Settings.unitSystem"
    private static let reflectionRemindersKey = "Settings.reflectionReminders"
    private static let planUpdateAlertsKey    = "Settings.planUpdateAlerts"
    private static let appThemeKey            = "Settings.appTheme"

    // MARK: - Init

    init() {
        let rawUnit = UserDefaults.standard.string(forKey: Self.unitSystemKey)
        unitSystem          = UnitSystem(rawValue: rawUnit ?? "") ?? .metric
        reflectionReminders = UserDefaults.standard.object(forKey: Self.reflectionRemindersKey) as? Bool ?? true
        planUpdateAlerts    = UserDefaults.standard.object(forKey: Self.planUpdateAlertsKey) as? Bool ?? true
        let rawTheme = UserDefaults.standard.string(forKey: Self.appThemeKey)
        appTheme            = AppTheme(rawValue: rawTheme ?? "") ?? .device
    }

    /// Preview/test initializer with explicit state.
    init(stravaState: StravaState, unitSystem: UnitSystem = .metric, reflectionReminders: Bool = true, planUpdateAlerts: Bool = true, appTheme: AppTheme = .device, deleteState: DeleteState = .idle) {
        self.stravaState = stravaState
        self.unitSystem = unitSystem
        self.reflectionReminders = reflectionReminders
        self.planUpdateAlerts = planUpdateAlerts
        self.appTheme = appTheme
        self.deleteState = deleteState
    }

    // MARK: - Strava Actions

    func loadStravaStatus(apiClient: APIClient) async {
        stravaState = .loading
        let result: ApiResult<StravaStatusResponse> = await apiClient.stravaStatus()
        switch result {
        case .success(let response):
            if !response.connected {
                stravaState = .disconnected
            } else if let expiresAt = response.expires_at, Self.isExpired(expiresAt) {
                stravaState = .expired(expiresAt: expiresAt, scope: response.scope)
            } else {
                stravaState = .connected(expiresAt: response.expires_at, scope: response.scope)
            }
        case .failure(_, let message):
            stravaState = .error(message)
        }
    }

    func setConnecting() {
        stravaState = .connecting
    }

    func exchangeStravaCode(_ code: String, apiClient: APIClient) async {
        let result: ApiResult<StravaConnectResponse> = await apiClient.stravaConnect(code: code)
        switch result {
        case .success:
            // Refresh to get actual expiry/scope from server
            await loadStravaStatus(apiClient: apiClient)
        case .failure(_, let message):
            stravaState = .error(message)
        }
    }

    func disconnectStrava(apiClient: APIClient) async {
        stravaState = .disconnecting
        let result: ApiResult<StravaDisconnectResponse> = await apiClient.stravaDisconnect()
        switch result {
        case .success:
            stravaState = .disconnected
        case .failure(_, let message):
            stravaState = .error(message)
        }
    }

    // MARK: - Account Deletion

    func executeDeleteAccount(apiClient: APIClient) async -> Bool {
        deleteState = .deleting
        let result: ApiResult<EmptyResponse> = await apiClient.deleteAccount()
        switch result {
        case .success:
            return true
        case .failure(_, let message):
            deleteState = .error(message)
            return false
        }
    }

    // MARK: - Sign Out

    /// Resets all stores and signs out. authStore.signOut() is called last
    /// because it triggers RootView re-routing.
    func signOut(
        authStore: AuthStore,
        onboardingStore: OnboardingStore,
        planStore: PlanStore,
        chatStore: ChatStore
    ) {
        chatStore.reset()
        planStore.reset()
        onboardingStore.reset()
        // Clear heatmap disk cache before signing out
        if let userId = authStore.userId {
            HeatmapCache().clearAll(userId: userId)
        }
        authStore.signOut()
    }

    // MARK: - Helpers

    private static func isExpired(_ isoString: String) -> Bool {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: isoString) {
            return date < Date()
        }
        // Retry without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: isoString) {
            return date < Date()
        }
        return false
    }
}
