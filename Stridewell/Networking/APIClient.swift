//
//  APIClient.swift
//  Stridewell
//

import Foundation

final class APIClient {

    // MARK: - Properties

    private let baseURL: URL
    private let session: URLSession
    private let tokenProvider: () -> String?
    private let onUnauthorized: () -> Void

    // MARK: - Init

    init(
        tokenProvider: @escaping () -> String?,
        onUnauthorized: @escaping () -> Void,
        baseURL: URL = Config.baseURL,
        session: URLSession = .shared
    ) {
        self.tokenProvider   = tokenProvider
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

        guard let url = URL(string: path, relativeTo: baseURL) else {
            return .failure(status: 0, message: "Invalid URL path: \(path)")
        }

        var req = URLRequest(url: url)
        req.httpMethod = method

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
                onUnauthorized()
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
