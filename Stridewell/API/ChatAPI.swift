//
//  ChatAPI.swift
//  Stridewell
//
//  M10: Chat message endpoint.
//

import Foundation

extension APIClient {

    /// POST /chat/message — send a message and receive an AI response.
    /// If `conversationId` is nil, the backend creates a new conversation.
    func sendChatMessage(
        conversationId: String?,
        message: String
    ) async -> ApiResult<ChatMessageResponse> {
        let body = ChatMessageRequest(
            message: message,
            conversation_id: conversationId
        )
        return await post(path: APIEndpoints.chatMessage, body: body)
    }
}
