//
//  ReflectionAPI.swift
//  Stridewell
//

import Foundation

extension APIClient {

    /// Submit a daily reflection check-in.
    func submitReflection(_ data: ReflectionSubmission) async -> ApiResult<ReflectionResponse> {
        await post(path: APIEndpoints.reflection, body: data)
    }
}
