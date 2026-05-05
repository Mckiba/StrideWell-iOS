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

    // MARK: - Coaching Notifications (Phase 5)

    var proactiveEnabled: Bool {
        didSet { UserDefaults.standard.set(proactiveEnabled, forKey: Self.proactiveEnabledKey) }
    }

    var proactiveTrainingMilestone: Bool {
        didSet { UserDefaults.standard.set(proactiveTrainingMilestone, forKey: Self.proactiveTrainingMilestoneKey) }
    }

    var proactiveTrainingConcern: Bool {
        didSet { UserDefaults.standard.set(proactiveTrainingConcern, forKey: Self.proactiveTrainingConcernKey) }
    }

    var proactiveUpcomingEvent: Bool {
        didSet { UserDefaults.standard.set(proactiveUpcomingEvent, forKey: Self.proactiveUpcomingEventKey) }
    }

    var proactiveReengagement: Bool {
        didSet { UserDefaults.standard.set(proactiveReengagement, forKey: Self.proactiveReengagementKey) }
    }

    var proactivePlanFollowup: Bool {
        didSet { UserDefaults.standard.set(proactivePlanFollowup, forKey: Self.proactivePlanFollowupKey) }
    }

    var proactiveQuietHoursEnabled: Bool {
        didSet { UserDefaults.standard.set(proactiveQuietHoursEnabled, forKey: Self.proactiveQuietHoursEnabledKey) }
    }

    var proactiveQuietHoursStart: String {
        didSet { UserDefaults.standard.set(proactiveQuietHoursStart, forKey: Self.proactiveQuietHoursStartKey) }
    }

    var proactiveQuietHoursEnd: String {
        didSet { UserDefaults.standard.set(proactiveQuietHoursEnd, forKey: Self.proactiveQuietHoursEndKey) }
    }

    var proactiveTimezone: String {
        didSet { UserDefaults.standard.set(proactiveTimezone, forKey: Self.proactiveTimezoneKey) }
    }

    private(set) var proactiveSyncError: String? = nil

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
    private static let proactiveEnabledKey              = "Settings.proactive.enabled"
    private static let proactiveTrainingMilestoneKey    = "Settings.proactive.trainingMilestone"
    private static let proactiveTrainingConcernKey      = "Settings.proactive.trainingConcern"
    private static let proactiveUpcomingEventKey        = "Settings.proactive.upcomingEvent"
    private static let proactiveReengagementKey         = "Settings.proactive.reengagement"
    private static let proactivePlanFollowupKey         = "Settings.proactive.planFollowup"
    private static let proactiveQuietHoursEnabledKey    = "Settings.proactive.quietHoursEnabled"
    private static let proactiveQuietHoursStartKey      = "Settings.proactive.quietHoursStart"
    private static let proactiveQuietHoursEndKey        = "Settings.proactive.quietHoursEnd"
    private static let proactiveTimezoneKey             = "Settings.proactive.timezone"

    // MARK: - Init

    init() {
        let rawUnit = UserDefaults.standard.string(forKey: Self.unitSystemKey)
        unitSystem          = UnitSystem(rawValue: rawUnit ?? "") ?? .metric
        reflectionReminders = UserDefaults.standard.object(forKey: Self.reflectionRemindersKey) as? Bool ?? true
        planUpdateAlerts    = UserDefaults.standard.object(forKey: Self.planUpdateAlertsKey) as? Bool ?? true
        let rawTheme = UserDefaults.standard.string(forKey: Self.appThemeKey)
        appTheme            = AppTheme(rawValue: rawTheme ?? "") ?? .device
        proactiveEnabled = UserDefaults.standard.object(forKey: Self.proactiveEnabledKey) as? Bool ?? true
        proactiveTrainingMilestone = UserDefaults.standard.object(forKey: Self.proactiveTrainingMilestoneKey) as? Bool ?? true
        proactiveTrainingConcern = UserDefaults.standard.object(forKey: Self.proactiveTrainingConcernKey) as? Bool ?? true
        proactiveUpcomingEvent = UserDefaults.standard.object(forKey: Self.proactiveUpcomingEventKey) as? Bool ?? true
        proactiveReengagement = UserDefaults.standard.object(forKey: Self.proactiveReengagementKey) as? Bool ?? true
        proactivePlanFollowup = UserDefaults.standard.object(forKey: Self.proactivePlanFollowupKey) as? Bool ?? true
        proactiveQuietHoursEnabled = UserDefaults.standard.object(forKey: Self.proactiveQuietHoursEnabledKey) as? Bool ?? true
        proactiveQuietHoursStart = UserDefaults.standard.string(forKey: Self.proactiveQuietHoursStartKey) ?? "22:00"
        proactiveQuietHoursEnd = UserDefaults.standard.string(forKey: Self.proactiveQuietHoursEndKey) ?? "07:00"
        proactiveTimezone = UserDefaults.standard.string(forKey: Self.proactiveTimezoneKey) ?? TimeZone.current.identifier
    }

    /// Preview/test initializer with explicit state.
    init(stravaState: StravaState, unitSystem: UnitSystem = .metric, reflectionReminders: Bool = true, planUpdateAlerts: Bool = true, appTheme: AppTheme = .device, deleteState: DeleteState = .idle, proactiveEnabled: Bool = true, proactiveTrainingMilestone: Bool = true, proactiveTrainingConcern: Bool = true, proactiveUpcomingEvent: Bool = true, proactiveReengagement: Bool = true, proactivePlanFollowup: Bool = true, proactiveQuietHoursEnabled: Bool = true, proactiveQuietHoursStart: String = "22:00", proactiveQuietHoursEnd: String = "07:00", proactiveTimezone: String = "America/Los_Angeles", proactiveSyncError: String? = nil) {
        self.stravaState = stravaState
        self.unitSystem = unitSystem
        self.reflectionReminders = reflectionReminders
        self.planUpdateAlerts = planUpdateAlerts
        self.appTheme = appTheme
        self.deleteState = deleteState
        self.proactiveEnabled = proactiveEnabled
        self.proactiveTrainingMilestone = proactiveTrainingMilestone
        self.proactiveTrainingConcern = proactiveTrainingConcern
        self.proactiveUpcomingEvent = proactiveUpcomingEvent
        self.proactiveReengagement = proactiveReengagement
        self.proactivePlanFollowup = proactivePlanFollowup
        self.proactiveQuietHoursEnabled = proactiveQuietHoursEnabled
        self.proactiveQuietHoursStart = proactiveQuietHoursStart
        self.proactiveQuietHoursEnd = proactiveQuietHoursEnd
        self.proactiveTimezone = proactiveTimezone
        self.proactiveSyncError = proactiveSyncError
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

    // MARK: - Coaching Notifications

    func setProactiveEnabled(_ enabled: Bool, apiClient: APIClient) async {
        proactiveEnabled = enabled
        await syncProactivePreferences(apiClient: apiClient)
    }

    func setProactiveTrainingMilestone(_ enabled: Bool, apiClient: APIClient) async {
        proactiveTrainingMilestone = enabled
        await syncProactivePreferences(apiClient: apiClient)
    }

    func setProactiveTrainingConcern(_ enabled: Bool, apiClient: APIClient) async {
        proactiveTrainingConcern = enabled
        await syncProactivePreferences(apiClient: apiClient)
    }

    func setProactiveUpcomingEvent(_ enabled: Bool, apiClient: APIClient) async {
        proactiveUpcomingEvent = enabled
        await syncProactivePreferences(apiClient: apiClient)
    }

    func setProactiveReengagement(_ enabled: Bool, apiClient: APIClient) async {
        proactiveReengagement = enabled
        await syncProactivePreferences(apiClient: apiClient)
    }

    func setProactivePlanFollowup(_ enabled: Bool, apiClient: APIClient) async {
        proactivePlanFollowup = enabled
        await syncProactivePreferences(apiClient: apiClient)
    }

    func setProactiveQuietHoursEnabled(_ enabled: Bool, apiClient: APIClient) async {
        proactiveQuietHoursEnabled = enabled
        await syncProactivePreferences(apiClient: apiClient)
    }

    func setProactiveQuietHoursStart(_ startLocal: String, apiClient: APIClient) async {
        proactiveQuietHoursStart = startLocal
        await syncProactivePreferences(apiClient: apiClient)
    }

    func setProactiveQuietHoursEnd(_ endLocal: String, apiClient: APIClient) async {
        proactiveQuietHoursEnd = endLocal
        await syncProactivePreferences(apiClient: apiClient)
    }

    func clearProactiveSyncError() {
        proactiveSyncError = nil
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
        chatStore: ChatStore,
        activityStore: ActivityStore
    ) {
        chatStore.reset()
        planStore.reset()
        onboardingStore.reset()
        activityStore.reset()
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

    private func syncProactivePreferences(apiClient: APIClient) async {
        let payload = ProactivePreferencesRequest(
            enabled: proactiveEnabled,
            categories_enabled: ProactiveCategoriesEnabled(
                training_milestone: proactiveTrainingMilestone,
                training_concern: proactiveTrainingConcern,
                upcoming_event: proactiveUpcomingEvent,
                reengagement: proactiveReengagement,
                plan_followup: proactivePlanFollowup
            ),
            quiet_hours: ProactiveQuietHours(
                enabled: proactiveQuietHoursEnabled,
                start_local: proactiveQuietHoursStart,
                end_local: proactiveQuietHoursEnd
            ),
            timezone: proactiveTimezone
        )

        let result: ApiResult<ProactivePreferencesStoredResponse> = await apiClient.putProactivePreferences(payload)
        switch result {
        case .success:
            proactiveSyncError = nil
        case .failure(_, let message):
            proactiveSyncError = message
        }
    }
}
