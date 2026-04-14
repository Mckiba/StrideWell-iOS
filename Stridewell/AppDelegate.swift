//
//  AppDelegate.swift
//  Stridewell
//

import GoogleSignIn
import UIKit
import UserNotifications

// MARK: - App Delegate

final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // MARK: - Google Sign-In URL Handling

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }

    // MARK: - Remote Notification Registration

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        NotificationCenter.default.post(name: .apnsTokenReceived, object: token)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        // Non-fatal — push is best-effort; app functions normally without it
        #if DEBUG
        print("[Push] Registration failed: \(error.localizedDescription)")
        #endif
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {

    /// Show banner, sound, and badge even when the app is foregrounded.
    /// Also broadcasts the full payload so stores can react without navigating.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        NotificationCenter.default.post(name: .foregroundPushReceived, object: userInfo)
        completionHandler([.banner, .sound, .badge])
    }

    /// Handle notification tap — update stores with full payload, then route via deep_link.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        // Update activityStore / planStore with run_id / plan_version_id — same handler as foreground push.
        // This covers the case where the push arrived while the app was backgrounded and the user tapped it.
        NotificationCenter.default.post(name: .foregroundPushReceived, object: userInfo)
        if let deepLink = userInfo["deep_link"] as? String {
            NotificationCenter.default.post(name: .deepLinkReceived, object: deepLink)
        }
        completionHandler()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let apnsTokenReceived      = Notification.Name("com.stridewell.apnsTokenReceived")
    static let deepLinkReceived       = Notification.Name("com.stridewell.deepLinkReceived")
    static let foregroundPushReceived = Notification.Name("com.stridewell.foregroundPushReceived")
    static let switchToActivities     = Notification.Name("com.stridewell.switchToActivities")
    static let switchToChat           = Notification.Name("com.stridewell.switchToChat")
    // Screen-specific navigation triggered by deep links
    static let openReflection         = Notification.Name("com.stridewell.openReflection")
    static let openPlanChange         = Notification.Name("com.stridewell.openPlanChange")
    static let openPlanReveal         = Notification.Name("com.stridewell.openPlanReveal")
}
