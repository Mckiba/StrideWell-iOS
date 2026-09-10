//
//  APIClient.swift
//  Stridewell
//

import Foundation

final class APIClient {

    // MARK: - Refresh Outcome

    /// Result of a session-refresh attempt. The distinction between an auth
    /// failure and a transient failure is what prevents a network blip from
    /// wiping the user's session.
    private enum RefreshOutcome {
        /// A valid access token is available (refreshed, or still fresh).
        case refreshed
        /// The refresh token is genuinely invalid (a 401 from /auth/refresh).
        /// The only case that should trigger a hard logout.
        case authFailed
        /// A transient error (no network, timeout, 5xx, 429). The session is
        /// still valid — the caller should surface a retryable error, not log out.
        case transientFailed
        /// No refresh token stored, so a 401 cannot be recovered.
        case noRefreshToken
    }

    // MARK: - Properties

    private let baseURL: URL
    private let session: URLSession
    private let tokenProvider: () -> String?
    private let refreshTokenProvider: () -> String?
    private let accessTokenExpiryProvider: () -> Int?
    private let onSessionRefreshed: (AuthSessionResponse) -> Void
    private let onUnauthorized: () -> Void
    private let refreshSkewSeconds: Int = 300
    /// Number of extra attempts for a transient refresh failure before giving up.
    private let maxTransientRefreshRetries: Int = 2
    private let refreshLock = NSLock()
    private var refreshTask: Task<RefreshOutcome, Never>?

    // MARK: - Init

    init(
        tokenProvider: @escaping () -> String?,
        refreshTokenProvider: @escaping () -> String? = { nil },
        accessTokenExpiryProvider: @escaping () -> Int? = { nil },
        onSessionRefreshed: @escaping (AuthSessionResponse) -> Void = { _ in },
        onUnauthorized: @escaping () -> Void,
        baseURL: URL = Config.baseURL,
        session: URLSession = .shared
    ) {
        self.tokenProvider   = tokenProvider
        self.refreshTokenProvider = refreshTokenProvider
        self.accessTokenExpiryProvider = accessTokenExpiryProvider
        self.onSessionRefreshed = onSessionRefreshed
        self.onUnauthorized  = onUnauthorized
        self.baseURL         = baseURL
        self.session         = session
    }

    // MARK: - Core Request

    func request<T: Decodable>(
        _ method: String,
        path: String,
        body: (any Encodable)? = nil
    ) async -> ApiResult<T> {
        await request(
            method,
            path: path,
            body: body,
            allowAutoRefresh: true,
            allowUnauthorizedHandler: true,
            retryOn401: true
        )
    }

    private func request<T: Decodable>(
        _ method: String,
        path: String,
        body: (any Encodable)? = nil,
        allowAutoRefresh: Bool,
        allowUnauthorizedHandler: Bool,
        retryOn401: Bool
    ) async -> ApiResult<T> {

        guard let url = URL(string: path, relativeTo: baseURL) else {
            return .failure(status: 0, message: "Invalid URL path: \(path)")
        }

        var req = URLRequest(url: url)
        req.httpMethod = method

        if allowAutoRefresh && path != APIEndpoints.refreshSession && tokenProvider() != nil {
            // Only a proven-dead refresh token short-circuits here. On a transient
            // failure the stored access token may still be valid, so the request goes
            // ahead and the 401 path deals with it if it isn't. Bailing out on
            // .authFailed avoids sending a doomed request and then burning a second
            // refresh (and, with rotation on, another link of the token chain).
            if case .authFailed = await refreshSessionIfNeeded(force: false) {
                if allowUnauthorizedHandler {
                    onUnauthorized()
                }
                return .failure(status: 401, message: "Session expired. Please sign in again.")
            }
        }

        if let token = tokenProvider() {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Send the device's IANA timezone so backend code can resolve "today" in
        // the user's local calendar (otherwise UTC wins and late-evening users
        // in west-of-UTC zones lose a day of plan windowing).
        req.setValue(TimeZone.current.identifier, forHTTPHeaderField: "X-Timezone")

        if let body {
            do {
                req.setValue("application/json", forHTTPHeaderField: "Content-Type")
                req.httpBody = try JSONEncoder().encode(body)
            } catch {
                return .failure(status: 0, message: "Encoding error: \(error.localizedDescription)")
            }
        }

        do {
            let (data, response) = try await session.data(for: req)

            guard let http = response as? HTTPURLResponse else {
                return .failure(status: 0, message: "Non-HTTP response")
            }

            if http.statusCode == 401 {
                if retryOn401 && path != APIEndpoints.refreshSession && tokenProvider() != nil {
                    switch await refreshSessionIfNeeded(force: true) {
                    case .refreshed:
                        return await request(
                            method,
                            path: path,
                            body: body,
                            allowAutoRefresh: false,
                            allowUnauthorizedHandler: allowUnauthorizedHandler,
                            retryOn401: false
                        )
                    case .transientFailed:
                        // The session is still valid — a transient failure blocked the
                        // refresh. Surface a retryable error instead of logging out.
                        return .failure(status: 0, message: "Couldn't reach the server. Please try again.")
                    case .authFailed, .noRefreshToken:
                        break // fall through to the logout path below
                    }
                }

                if allowUnauthorizedHandler {
                    onUnauthorized()
                }
                return .failure(status: 401, message: "Session expired. Please sign in again.")
            }

            guard (200..<300).contains(http.statusCode) else {
                let msg = (try? JSONDecoder().decode(BackendError.self, from: data))?.resolvedMessage
                    ?? HTTPURLResponse.localizedString(forStatusCode: http.statusCode)
                return .failure(status: http.statusCode, message: msg)
            }

            // Handle 204 No Content (empty body)
            if data.isEmpty, let empty = EmptyResponse() as? T {
                return .success(empty)
            }

            do {
                let decoded = try JSONDecoder().decode(T.self, from: data)
                return .success(decoded)
            } catch {
                return .failure(status: 0, message: "Decode error: \(error.localizedDescription)")
            }

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

    // MARK: - Session Refresh

    /// Proactively refreshes the session if the access token is near expiry.
    /// Call this when the app foregrounds so a burst of screen loads doesn't each
    /// race on a just-expired token. Never triggers a logout — a genuinely dead
    /// session is handled by the 401 path on the next real request.
    func ensureFreshSession() async {
        guard tokenProvider() != nil else { return }
        _ = await refreshSessionIfNeeded(force: false)
    }

    private func refreshSessionIfNeeded(force: Bool) async -> RefreshOutcome {
        guard let refreshToken = refreshTokenProvider(), !refreshToken.isEmpty else {
            return .noRefreshToken
        }

        if !force && !isAccessTokenNearExpiry() {
            return .refreshed
        }

        // Single-flight: concurrent callers coalesce onto one in-flight refresh.
        // Only the caller that created the task clears it, so a late awaiter can't
        // drop another caller's in-flight refresh registration.
        var isOwner = false
        let task: Task<RefreshOutcome, Never> = {
            refreshLock.lock()
            defer { refreshLock.unlock() }
            if let existing = refreshTask {
                return existing
            }
            isOwner = true
            let created = Task { [weak self] () -> RefreshOutcome in
                guard let self else { return .transientFailed }
                var attempt = 0
                while true {
                    let result: ApiResult<AuthSessionResponse> = await self.request(
                        "POST",
                        path: APIEndpoints.refreshSession,
                        body: RefreshSessionRequest(refresh_token: refreshToken),
                        allowAutoRefresh: false,
                        allowUnauthorizedHandler: false,
                        retryOn401: false
                    )

                    switch result {
                    case .success(let response):
                        self.onSessionRefreshed(response)
                        return .refreshed
                    case .failure(let status, _):
                        // A 401 means the refresh token itself is invalid — unrecoverable.
                        if status == 401 { return .authFailed }
                        // Network (status 0), 5xx, or 429 — retry a few times, then give
                        // up without clearing the session.
                        attempt += 1
                        if attempt > self.maxTransientRefreshRetries { return .transientFailed }
                        try? await Task.sleep(nanoseconds: UInt64(attempt) * 500_000_000)
                    }
                }
            }
            refreshTask = created
            return created
        }()

        let outcome = await task.value
        if isOwner {
            refreshLock.lock()
            refreshTask = nil
            refreshLock.unlock()
        }
        return outcome
    }

    private func isAccessTokenNearExpiry() -> Bool {
        guard let expiresAt = accessTokenExpiryProvider() else {
            return true
        }
        let now = Int(Date().timeIntervalSince1970)
        return expiresAt - now <= refreshSkewSeconds
    }

    // MARK: - Convenience Methods

    func get<T: Decodable>(path: String) async -> ApiResult<T> {
        await request("GET", path: path)
    }

    func post<T: Decodable>(path: String, body: some Encodable) async -> ApiResult<T> {
        await request("POST", path: path, body: body)
    }
}

// MARK: - Backend Error Envelope

private struct BackendError: Decodable {
    let message: String?
    let error: String?

    var resolvedMessage: String? {
        if let message, !message.isEmpty { return message }
        if let error, !error.isEmpty { return error }
        return nil
    }
}
