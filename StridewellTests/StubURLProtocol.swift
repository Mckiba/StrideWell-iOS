//
//  StubURLProtocol.swift
//  StridewellTests
//

import Foundation

/// Intercepts every request made through a `URLSession` configured with it, so
/// tests can script backend responses (including network failures) without a server.
final class StubURLProtocol: URLProtocol {

    /// What the stub should do with one request.
    enum Response {
        case status(Int, body: String)
        case failure(URLError.Code)
    }

    /// Returns the response for a request, or nil to fail the test loudly.
    nonisolated(unsafe) static var handler: ((URLRequest) -> Response)?

    /// Every request the stub has seen, in order. Reset in `reset()`.
    nonisolated(unsafe) private(set) static var requestedPaths: [String] = []

    /// Artificial latency before a response is delivered. Widens the window in
    /// which concurrent callers can observe an in-flight request.
    nonisolated(unsafe) static var responseDelay: TimeInterval = 0

    private static let lock = NSLock()

    static func reset() {
        lock.lock()
        defer { lock.unlock() }
        handler = nil
        requestedPaths = []
        responseDelay = 0
    }

    static func record(_ path: String) {
        lock.lock()
        defer { lock.unlock() }
        requestedPaths.append(path)
    }

    static func paths() -> [String] {
        lock.lock()
        defer { lock.unlock() }
        return requestedPaths
    }

    /// A `URLSession` that routes all traffic through this stub.
    static func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: config)
    }

    // MARK: - URLProtocol

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let path = request.url?.path ?? ""
        StubURLProtocol.record(path)

        guard let response = StubURLProtocol.handler?(request) else {
            client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL))
            return
        }

        let deliver = { [weak self] in
            guard let self else { return }
            switch response {
            case .failure(let code):
                self.client?.urlProtocol(self, didFailWithError: URLError(code))

            case .status(let status, let body):
                let http = HTTPURLResponse(
                    url: self.request.url!,
                    statusCode: status,
                    httpVersion: "HTTP/1.1",
                    headerFields: ["Content-Type": "application/json"]
                )!
                self.client?.urlProtocol(self, didReceive: http, cacheStoragePolicy: .notAllowed)
                self.client?.urlProtocol(self, didLoad: Data(body.utf8))
                self.client?.urlProtocolDidFinishLoading(self)
            }
        }

        let delay = StubURLProtocol.responseDelay
        if delay > 0 {
            DispatchQueue.global().asyncAfter(deadline: .now() + delay, execute: deliver)
        } else {
            deliver()
        }
    }

    override func stopLoading() {}
}
