import AppKit
import Combine
import Foundation

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var input = ""
    @Published var conversations: [String: [ChatMessage]] = [:]
    @Published var selectedPromptModeID: String {
        didSet {
            errorMessage = nil
            focusInput()
        }
    }
    @Published var isStreaming = false
    @Published var isPanelPinned = false
    @Published var errorMessage: String?
    @Published var inputFocusToken = UUID()

    let settingsStore: SettingsStore
    private let provider: AIProvider
    private let conversationStore: ConversationStore
    private var streamTask: Task<Void, Never>?

    init(
        settingsStore: SettingsStore,
        provider: AIProvider = OpenAICompatibleProvider(),
        conversationStore: ConversationStore = ConversationStore()
    ) {
        self.settingsStore = settingsStore
        self.provider = provider
        self.conversationStore = conversationStore
        self.selectedPromptModeID = settingsStore.settings.defaultPromptModeID
        self.conversations = conversationStore.load()
    }

    var promptModes: [PromptMode] {
        settingsStore.settings.promptModes
    }

    var messages: [ChatMessage] {
        conversations[selectedPromptModeID] ?? []
    }

    func focusInput() {
        inputFocusToken = UUID()
    }

    func submit() {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isStreaming else { return }

        errorMessage = nil
        input = ""

        let userMessage = ChatMessage(role: .user, content: trimmed)
        let assistantMessage = ChatMessage(role: .assistant, content: "", sourceUserMessageID: userMessage.id)
        append(userMessage)
        append(assistantMessage)
        saveConversations()

        streamResponse(into: assistantMessage.id, requestMessages: composeMessages(for: assistantMessage.id))
    }

    func retry() {
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        submit()
    }

    func regenerate(messageID: UUID) {
        guard !isStreaming,
              let index = messages.firstIndex(where: { $0.id == messageID }),
              messages[index].role == .assistant else {
            return
        }

        setMessageContent(id: messageID, content: "")
        streamResponse(into: messageID, requestMessages: composeMessages(for: messageID))
    }

    func deleteMessage(id: UUID) {
        cancelStreaming()
        updateCurrentMessages { messages in
            guard let index = messages.firstIndex(where: { $0.id == id }) else { return }
            let message = messages[index]
            messages.remove(at: index)

            if message.role == .user {
                messages.removeAll { $0.sourceUserMessageID == message.id }
            }
        }
        saveConversations()
    }

    func cancelStreaming() {
        streamTask?.cancel()
        streamTask = nil
        isStreaming = false
        saveConversations()
    }

    func togglePanelPinned() {
        isPanelPinned.toggle()
    }

    func clear() {
        cancelStreaming()
        conversations.removeAll()
        errorMessage = nil
        input = ""
        focusInput()
        saveConversations()
    }

    func copyLastAnswer() {
        guard let answer = messages.last(where: { $0.role == .assistant && !$0.content.isEmpty }) else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(answer.content, forType: .string)
    }

    func copyMessage(id: UUID) {
        guard let message = messages.first(where: { $0.id == id && !$0.content.isEmpty }) else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(message.content, forType: .string)
    }

    private func streamResponse(into assistantID: UUID, requestMessages: [ChatMessage]) {
        guard let mode = currentPromptMode else { return }
        let settings = effectiveSettings(for: mode)
        let profile = settingsStore.settings.effectiveModelProfile(for: mode)
        let apiKey = settingsStore.apiKey(for: profile.id)

        isStreaming = true
        streamTask = Task { [weak self] in
            guard let self else { return }

            do {
                let stream = try await provider.streamChat(
                    messages: requestMessages,
                    settings: settings,
                    apiKey: apiKey
                )

                for try await token in stream {
                    if Task.isCancelled { break }
                    await MainActor.run {
                        self.appendToMessage(id: assistantID, token: token)
                    }
                }

                await MainActor.run {
                    self.isStreaming = false
                    self.streamTask = nil
                    self.saveConversations()
                }
            } catch {
                await MainActor.run {
                    self.isStreaming = false
                    self.streamTask = nil
                    self.errorMessage = error.localizedDescription
                    self.setMessageContent(id: assistantID, content: "")
                    self.saveConversations()
                }
            }
        }
    }

    private var currentPromptMode: PromptMode? {
        promptModes.first(where: { $0.id == selectedPromptModeID }) ?? PromptMode.defaults.first
    }

    private func effectiveSettings(for mode: PromptMode) -> ModelSettings {
        var settings = settingsStore.settings
        let profile = settings.effectiveModelProfile(for: mode)
        settings.baseURL = profile.baseURL
        settings.model = profile.model
        settings.maxTokens = profile.maxTokens
        settings.defaultTemperature = mode.temperature ?? profile.temperature
        return settings
    }

    private func composeMessages(for assistantID: UUID) -> [ChatMessage] {
        guard let mode = currentPromptMode else { return [] }
        let allMessages = messages
        guard let assistantIndex = allMessages.firstIndex(where: { $0.id == assistantID }) else { return [] }

        let contextTurns = max(0, settingsStore.settings.effectiveContextTurns(for: mode))
        let prior = Array(allMessages.prefix(upTo: assistantIndex))
        let relevantPrior = prior.suffix(contextTurns * 2 + 1)

        var composed = [ChatMessage(role: .system, content: mode.localizedSystemPrompt)]
        composed.append(contentsOf: relevantPrior)
        return composed
    }

    private func append(_ message: ChatMessage) {
        updateCurrentMessages { $0.append(message) }
    }

    private func appendToMessage(id: UUID, token: String) {
        updateCurrentMessages { messages in
            if let index = messages.firstIndex(where: { $0.id == id }) {
                messages[index].content += token
            }
        }
    }

    private func setMessageContent(id: UUID, content: String) {
        updateCurrentMessages { messages in
            if let index = messages.firstIndex(where: { $0.id == id }) {
                messages[index].content = content
            }
        }
    }

    private func updateCurrentMessages(_ transform: (inout [ChatMessage]) -> Void) {
        var messages = conversations[selectedPromptModeID] ?? []
        transform(&messages)
        conversations[selectedPromptModeID] = messages
    }

    private func saveConversations() {
        conversationStore.save(conversations)
    }
}
