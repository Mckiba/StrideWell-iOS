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

    /// GET /chat/history?before=<iso>&limit=N
    /// Returns messages in ascending order (oldest → newest).
    /// Pass nil for `before` to fetch the latest page.
    func chatHistory(before: String? = nil, limit: Int = 50) async -> ApiResult<ChatHistoryResponse> {
        var path = "\(APIEndpoints.chatHistory)?limit=\(limit)"
        if let cursor = before {
            let encoded = cursor.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? cursor
            path += "&before=\(encoded)"
        }
        return await get(path: path)
    }

    /// PUT /chat/messages/:messageId/feedback — upsert thumbs up/down (+ optional comment).
    /// Server denormalises agent_used / prompt_version / context_flags at write time.
    func sendMessageFeedback(
        messageId: String,
        vote: FeedbackVote,
        comment: String?
    ) async -> ApiResult<FeedbackResponse> {
        let encoded = messageId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? messageId
        let body = FeedbackRequest(vote: vote.rawValue, comment: comment)
        return await request("PUT", path: "/chat/messages/\(encoded)/feedback", body: body)
    }
}

// MARK: - Feedback DTOs

private struct FeedbackRequest: Encodable {
    let vote: String
    let comment: String?
}

struct FeedbackResponse: Decodable {
    let stored: Bool
}
