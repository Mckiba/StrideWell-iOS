//
//  StravaOAuthHelper.swift
//  Stridewell
//
//  Reusable Strava OAuth flow using ASWebAuthenticationSession.
//  Wraps the callback-based API in async/await for clean usage in both
//  onboarding and settings.
//

import AuthenticationServices
import UIKit

enum StravaOAuthHelper {

    /// Starts the Strava OAuth flow and returns the authorization code.
    /// Returns nil if the user cancelled or an error occurred.
    @MainActor
    static func authenticate() async -> String? {
        guard let authURL = Config.stravaAuthURL else { return nil }

        // Retain session and context for the duration of the flow
        let context = OAuthPresentationContext()

        return await withCheckedContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: Config.appScheme
            ) { callbackURL, error in
                defer { _retainedSession = nil }

                guard let callbackURL, error == nil else {
                    continuation.resume(returning: nil)
                    return
                }
                let code = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
                    .queryItems?.first(where: { $0.name == "code" })?.value
                continuation.resume(returning: code)
            }
            session.presentationContextProvider = context
            session.prefersEphemeralWebBrowserSession = false

            _retainedSession = session
            _retainedContext = context
            session.start()
        }
    }

    @MainActor private static var _retainedSession: ASWebAuthenticationSession?
    @MainActor private static var _retainedContext: OAuthPresentationContext?
}

// MARK: - Presentation Context

private final class OAuthPresentationContext: NSObject,
    ASWebAuthenticationPresentationContextProviding, @unchecked Sendable {

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow) ?? ASPresentationAnchor()
    }
}
