import Foundation

protocol AIProvider {
    func streamChat(
        messages: [ChatMessage],
        settings: ModelSettings,
        apiKey: String
    ) async throws -> AsyncThrowingStream<String, Error>
}

enum AIProviderError: LocalizedError {
    case invalidBaseURL
    case invalidResponse
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidBaseURL:
            return "The model base URL is invalid."
        case .invalidResponse:
            return "The model returned an invalid response."
        case .requestFailed(let message):
            return message
        }
    }
}
