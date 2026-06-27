//
//  IntakeChatModel.swift
//  Stridewell
//
//  Reusable intake-chat controller shared by every guided screen (S2-S6). Owns the
//  per-screen message loop, sends turns with the screen's `screen_context` and any
//  `structured_fields`, and exposes `confirmedFields` / `planBuilding` so the hosting
//  screen can drive advancement.
//

import Foundation
import Observation

@Observable
final class IntakeChatModel {

    enum Phase: Equatable {
        case loading
        case active
        case waiting
        case transitioning
        case error(String)
    }

    private(set) var messages: [InterviewMessage] = []
    private(set) var phase: Phase = .loading
    private(set) var confirmedFields: [String] = []
    private(set) var planBuilding = false

    /// The guided screen's topic, sent as `screen_context` on every turn.
    let screenContext: String?

    private let api: APIClient
    private let conversationId: String
    private var pending: (message: InterviewMessage, structured: StructuredFields?)?
    private var hasStarted = false

    init(api: APIClient, conversationId: String, screenContext: String?) {
        self.api = api
        self.conversationId = conversationId
        self.screenContext = screenContext
    }

    // MARK: - Turns

    /// Sends the opener trigger once, so the Coach speaks first (on-topic via screen_context).
    func startIfNeeded() async {
        guard !hasStarted else { return }
        hasStarted = true
        phase = .loading
        let trigger = makeUserMessage(content: "start")
        pending = (trigger, nil)
        let result = await api.sendOnboardingMessage(
            conversationId: conversationId,
            message: trigger,
            screenContext: screenContext,
            structuredFields: nil
        )
        handle(result)
    }

    /// Sends a user turn. `structured` carries deterministic selections (dual-write:
    /// `content` is the natural-language rendering, `structured` the exact values).
    func send(_ content: String, structured: StructuredFields? = nil) async {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let msg = makeUserMessage(content: trimmed)
        pending = (msg, structured)
        messages.append(msg)
        phase = .waiting
        let result = await api.sendOnboardingMessage(
            conversationId: conversationId,
            message: msg,
            screenContext: screenContext,
            structuredFields: normalize(structured)
        )
        handle(result)
    }

    func retry() async {
        guard let pending else {
            await startIfNeeded()
            return
        }
        phase = .waiting
        let result = await api.sendOnboardingMessage(
            conversationId: conversationId,
            message: pending.message,
            screenContext: screenContext,
            structuredFields: normalize(pending.structured)
        )
        handle(result)
    }

    var canSend: Bool {
        if case .active = phase { return true }
        return false
    }

    // MARK: - Private

    private func handle(_ result: ApiResult<OnboardingMessageResponse>) {
        switch result {
        case .success(let response):
            pending = nil
            messages.append(response.reply)
            if let fields = response.onboarding_state.confirmed_fields {
                confirmedFields = fields
            }
            if response.onboarding_state.plan_building {
                planBuilding = true
                phase = .transitioning
            } else {
                phase = .active
            }
        case .failure(_, let message):
            phase = .error(message)
        }
    }

    /// Drop an all-nil structured payload so we never send an empty object.
    private func normalize(_ structured: StructuredFields?) -> StructuredFields? {
        guard let structured, !structured.isEmpty else { return nil }
        return structured
    }

    private func makeUserMessage(content: String) -> InterviewMessage {
        InterviewMessage(
            id: UUID().uuidString,
            role: .user,
            content: content,
            agent_used: nil,
            created_at: DateUtils.isoDateTimeFormatter.string(from: Date())
        )
    }
}
