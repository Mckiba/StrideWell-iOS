//
//  IntakeInterviewScreen.swift
//  Stridewell
//

import SwiftUI

struct IntakeInterviewScreen: View {

    @Environment(\.onboardingStore) private var onboardingStore
    @Environment(\.authStore) private var authStore
    @Environment(\.apiClient) private var apiClient

    @State private var messages: [InterviewMessage] = []
    @State private var inputText = ""
    @State private var screenState: IntakeInterviewContent.ScreenState = .loading
    @State private var navigateToPlanBuilding = false
    @State private var pendingMessage: InterviewMessage? = nil

    var body: some View {
        IntakeInterviewContent(
            messages: messages,
            screenState: screenState,
            inputText: $inputText,
            canSend: canSend,
            onSend: { Task { await sendMessage() } },
            onRetry: { Task { await retry() } }
        )
        .navigationTitle("Intake Interview")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Sign out") {
                    onboardingStore.reset()
                    authStore.signOut()
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
        }
        .navigationDestination(isPresented: $navigateToPlanBuilding) {
            PlanBuildingScreen()
        }
        .task { await triggerInitialMessage() }
    }

    private var canSend: Bool {
        screenState == .active &&
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Initial Trigger

    private func triggerInitialMessage() async {
        guard let conversationId = onboardingStore.conversationId else {
            screenState = .error("No active conversation. Please go back and try again.")
            return
        }
        screenState = .loading
        let trigger = makeMessage(content: "start")
        pendingMessage = trigger

        let result: ApiResult<OnboardingMessageResponse> = await apiClient.sendOnboardingMessage(
            conversationId: conversationId,
            message: trigger
        )
        handleResult(result, isTrigger: true)
    }

    // MARK: - Send Message

    private func sendMessage() async {
        let content = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty, let conversationId = onboardingStore.conversationId else { return }

        inputText = ""
        let userMsg = makeMessage(content: content)
        pendingMessage = userMsg
        messages.append(userMsg)
        screenState = .waiting

        let result: ApiResult<OnboardingMessageResponse> = await apiClient.sendOnboardingMessage(
            conversationId: conversationId,
            message: userMsg
        )
        handleResult(result, isTrigger: false)
    }

    // MARK: - Retry

    private func retry() async {
        if messages.isEmpty {
            await triggerInitialMessage()
        } else if let msg = pendingMessage, let conversationId = onboardingStore.conversationId {
            screenState = .waiting
            let result: ApiResult<OnboardingMessageResponse> = await apiClient.sendOnboardingMessage(
                conversationId: conversationId,
                message: msg
            )
            handleResult(result, isTrigger: false)
        }
    }

    // MARK: - Handle Result

    private func handleResult(_ result: ApiResult<OnboardingMessageResponse>, isTrigger: Bool) {
        switch result {
        case .success(let response):
            pendingMessage = nil
            messages.append(response.reply)
            applyOnboardingState(response.onboarding_state)
            if screenState != .transitioning {
                screenState = .active
            }
        case .failure(_, let errorMessage):
            screenState = .error(errorMessage)
        }
    }

    private func applyOnboardingState(_ state: OnboardingMessageOnboardingState) {
        guard state.plan_building else { return }
        screenState = .transitioning
        Task {
            try? await Task.sleep(for: .seconds(2))
            navigateToPlanBuilding = true
        }
    }

    // MARK: - Helpers

    private func makeMessage(content: String) -> InterviewMessage {
        InterviewMessage(
            id: UUID().uuidString,
            role: .user,
            content: content,
            agent_used: nil,
            created_at: DateUtils.isoDateTimeFormatter.string(from: Date())
        )
    }
}
