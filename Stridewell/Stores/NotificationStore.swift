//
//  NotificationStore.swift
//  Stridewell
//

import UIKit
import UserNotifications
import Observation

@Observable
final class NotificationStore {

    // MARK: - Deep Link

    enum DeepLink: String {
        case planChange  = "plan_change"
        case home        = "home"
        case chat        = "chat"
        case planReveal  = "plan_reveal"
        case reflection  = "reflection_reminder"
    }

    var pendingDeepLink: DeepLink? = nil

    // MARK: - Permission

    /// Requests APNs permission if not yet determined.
    /// If already authorized, calls registerForRemoteNotifications() to ensure a fresh
    /// token is delivered on every launch (token rotation is automatic on iOS).
    func requestPermission() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .notDetermined:
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
            if granted {
                UIApplication.shared.registerForRemoteNotifications()
            }
        case .authorized, .provisional, .ephemeral:
            // Re-register on each launch so the backend always has the latest token
            UIApplication.shared.registerForRemoteNotifications()
        case .denied:
            break
        @unknown default:
            break
        }
    }

    // MARK: - Actions

    func clearDeepLink() {
        pendingDeepLink = nil
    }
}
