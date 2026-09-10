//
//  APIClientRefreshTests.swift
//  StridewellTests
//
//  Covers the rule that caused users to be signed out every time they opened the
//  app: a refresh failure must only clear the session when the refresh token is
//  genuinely invalid. Network blips, timeouts, 5xx and 429 must leave the session
//  intact and surface a retryable error instead.
//

import XCTest
@testable import Stridewell

@MainActor
final class APIClientRefreshTests: XCTestCase {

    private let baseURL = URL(string: "http://stub.local")!

    /// Minimal decodable so `get` has a concrete return type.
    private struct Probe: Decodable {
        let ok: Bool
    }

    /// Mutable session state shared with the client under test.
    private final class SessionBox: @unchecked Sendable {
        var accessToken: String? = "access_token_v1"
        var refreshToken: String? = "refresh_token_v1"
        var expiresAt: Int? = Int(Date().timeIntervalSince1970) + 3600
        var unauthorizedCount = 0
        var refreshedSessions: [AuthSessionResponse] = []
    }

    private var box = SessionBox()

    override func setUp() {
        super.setUp()
        StubURLProtocol.reset()
        box = SessionBox()
    }

    override func tearDown() {
        StubURLProtocol.reset()
        super.tearDown()
    }

    private func makeClient() -> APIClient {
        let box = self.box
        return APIClient(
            tokenProvider: { box.accessToken },
            refreshTokenProvider: { box.refreshToken },
            accessTokenExpiryProvider: { box.expiresAt },
            onSessionRefreshed: { response in
                box.refreshedSessions.append(response)
                box.accessToken = response.access_token
                box.refreshToken = response.refresh_token
                box.expiresAt = response.expires_at
            },
            onUnauthorized: { box.unauthorizedCount += 1 },
            baseURL: baseURL,
            session: StubURLProtocol.makeSession()
        )
    }

    private var refreshSuccessBody: String {
        let expiresAt = Int(Date().timeIntervalSince1970) + 3600
        return """
        {"token":"access_token_v2","access_token":"access_token_v2",\
        "refresh_token":"refresh_token_v2","expires_at":\(expiresAt),\
        "token_type":"bearer","user_id":"user_abc"}
        """
    }

    private func refreshCallCount() -> Int {
        StubURLProtocol.paths().filter { $0 == APIEndpoints.refreshSession }.count
    }

    // MARK: - The regression

    func testTransientRefreshFailureKeepsTheSession() async {
        // The backend returns 503 when it could not reach Supabase. The refresh token
        // is untouched, so the session must survive.
        StubURLProtocol.handler = { request in
            request.url?.path == APIEndpoints.refreshSession
                ? .status(503, body: #"{"error":"Session refresh temporarily unavailable"}"#)
                : .status(401, body: #"{"error":"Unauthorized"}"#)
        }

        let result: ApiResult<Probe> = await makeClient().get(path: APIEndpoints.me)

        XCTAssertEqual(box.unauthorizedCount, 0, "A transient failure must not sign the user out")
        guard case .failure(let status, let message) = result else {
            return XCTFail("Expected a retryable failure, got \(result)")
        }
        XCTAssertEqual(status, 0)
        XCTAssertTrue(message.contains("Couldn't reach the server"))
        XCTAssertEqual(box.refreshToken, "refresh_token_v1", "The stored session must be preserved")
    }

    func testNetworkFailureDuringRefreshRetriesThenKeepsTheSession() async {
        // maxTransientRefreshRetries = 2, so one initial attempt plus two retries.
        StubURLProtocol.handler = { request in
            request.url?.path == APIEndpoints.refreshSession
                ? .failure(.cannotConnectToHost)
                : .status(401, body: #"{"error":"Unauthorized"}"#)
        }

        let result: ApiResult<Probe> = await makeClient().get(path: APIEndpoints.me)

        XCTAssertEqual(refreshCallCount(), 3, "Expected the initial attempt plus two retries")
        XCTAssertEqual(box.unauthorizedCount, 0)
        XCTAssertFalse(result.isOk)
    }

    // MARK: - A genuinely dead session still signs out

    func testInvalidRefreshTokenSignsTheUserOut() async {
        // 401 from /auth/refresh means the refresh token itself is rejected — for
        // example after rotation consumed it. Unrecoverable, so clear the session.
        StubURLProtocol.handler = { request in
            request.url?.path == APIEndpoints.refreshSession
                ? .status(401, body: #"{"error":"Invalid Refresh Token: Already Used"}"#)
                : .status(401, body: #"{"error":"Unauthorized"}"#)
        }

        let result: ApiResult<Probe> = await makeClient().get(path: APIEndpoints.me)

        XCTAssertEqual(box.unauthorizedCount, 1)
        guard case .failure(let status, _) = result else {
            return XCTFail("Expected a 401 failure, got \(result)")
        }
        XCTAssertEqual(status, 401)
    }

    func testMissingRefreshTokenSignsTheUserOut() async {
        box.refreshToken = nil
        StubURLProtocol.handler = { _ in .status(401, body: #"{"error":"Unauthorized"}"#) }

        let result: ApiResult<Probe> = await makeClient().get(path: APIEndpoints.me)

        XCTAssertEqual(box.unauthorizedCount, 1)
        XCTAssertEqual(refreshCallCount(), 0, "There is no token to refresh with")
        XCTAssertFalse(result.isOk)
    }

    // MARK: - The happy path

    func testSuccessfulRefreshReplaysTheOriginalRequest() async {
        let body = refreshSuccessBody
        nonisolated(unsafe) var servedFirst401 = false

        StubURLProtocol.handler = { request in
            if request.url?.path == APIEndpoints.refreshSession {
                return .status(200, body: body)
            }
            if servedFirst401 {
                return .status(200, body: #"{"ok":true}"#)
            }
            servedFirst401 = true
            return .status(401, body: #"{"error":"Unauthorized"}"#)
        }

        let result: ApiResult<Probe> = await makeClient().get(path: APIEndpoints.me)

        guard case .success(let probe) = result else {
            return XCTFail("Expected the replayed request to succeed, got \(result)")
        }
        XCTAssertTrue(probe.ok)
        XCTAssertEqual(box.unauthorizedCount, 0)
        XCTAssertEqual(box.refreshedSessions.count, 1)
        XCTAssertEqual(box.accessToken, "access_token_v2")
        XCTAssertEqual(refreshCallCount(), 1)
    }

    // MARK: - Session hygiene

    func testConcurrentRequestsShareASingleRefresh() async {
        // With rotation enabled every extra refresh burns another link in the token
        // chain, so a burst of screen loads on a near-expiry token must coalesce.
        box.expiresAt = Int(Date().timeIntervalSince1970) + 10 // inside the 300s skew
        StubURLProtocol.responseDelay = 0.2

        let body = refreshSuccessBody
        StubURLProtocol.handler = { request in
            request.url?.path == APIEndpoints.refreshSession
                ? .status(200, body: body)
                : .status(200, body: #"{"ok":true}"#)
        }

        let client = makeClient()
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<6 {
                group.addTask {
                    let _: ApiResult<Probe> = await client.get(path: APIEndpoints.me)
                }
            }
        }

        XCTAssertEqual(refreshCallCount(), 1, "Concurrent callers must coalesce onto one refresh")
        XCTAssertEqual(box.unauthorizedCount, 0)
    }

    func testDeadRefreshTokenIsNotRetriedOnTheSameRequest() async {
        // A near-expiry token triggers the pre-flight refresh. When that refresh comes
        // back 401 the client must give up immediately rather than send a doomed
        // request and then refresh a second time.
        box.expiresAt = Int(Date().timeIntervalSince1970) + 10
        StubURLProtocol.handler = { request in
            request.url?.path == APIEndpoints.refreshSession
                ? .status(401, body: #"{"error":"Invalid Refresh Token: Already Used"}"#)
                : .status(200, body: #"{"ok":true}"#)
        }

        let result: ApiResult<Probe> = await makeClient().get(path: APIEndpoints.me)

        XCTAssertEqual(refreshCallCount(), 1, "The dead token must not be presented twice")
        XCTAssertEqual(StubURLProtocol.paths().filter { $0 == APIEndpoints.me }.count, 0,
                       "No request should be sent with a known-dead session")
        XCTAssertEqual(box.unauthorizedCount, 1)
        XCTAssertFalse(result.isOk)
    }
}
