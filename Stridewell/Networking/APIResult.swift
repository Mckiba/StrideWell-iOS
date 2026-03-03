//
//  APIResult.swift
//  Stridewell
//

import Foundation

/// Typed result for all API calls. Screens check `isOk` or switch on
/// cases — raw errors never reach render logic.
///
/// Status 0 is a sentinel for network-level failures (URLError, no connection).
enum ApiResult<T> {
    case success(T)
    case failure(status: Int, message: String)
}

extension ApiResult {
    var isOk: Bool {
        if case .success = self { return true }
        return false
    }

    var data: T? {
        if case .success(let value) = self { return value }
        return nil
    }

    var errorMessage: String? {
        if case .failure(_, let msg) = self { return msg }
        return nil
    }

    var isOffline: Bool {
        if case .failure(let status, _) = self { return status == 0 }
        return false
    }
}
