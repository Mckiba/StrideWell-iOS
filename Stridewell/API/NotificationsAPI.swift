//
//  NotificationsAPI.swift
//  Stridewell
//

import Foundation

extension APIClient {

    func registerDeviceToken(_ token: String) async -> ApiResult<NotificationRegisterResponse> {
        await post(
            path: APIEndpoints.notificationsRegister,
            body: NotificationRegisterRequest(device_token: token)
        )
    }
}
