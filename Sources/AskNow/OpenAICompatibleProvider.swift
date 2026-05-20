import Foundation

final class OpenAICompatibleProvider: AIProvider {
    func streamChat(
        messages: [ChatMessage],
        settings: ModelSettings,
        apiKey: String
    ) async throws -> AsyncThrowingStream<String, Error> {
        guard let baseURL = URL(string: settings.baseURL.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw AIProviderError.invalidBaseURL
        }

        let endpoint = chatCompletionsEndpoint(from: baseURL)

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")

        if !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        let requestMessages = sanitizedMessages(messages)
        guard requestMessages.contains(where: { $0.role == ChatMessage.Role.user.rawValue }) else {
            throw AIProviderError.requestFailed("Model request was not sent because it has no user message.")
        }

        let body = ChatCompletionRequest(
            model: settings.model.trimmingCharacters(in: .whitespacesAndNewlines),
            messages: requestMessages,
            temperature: normalizedTemperature(settings.defaultTemperature, for: endpoint),
            max_tokens: normalizedMaxTokens(settings.maxTokens, for: endpoint),
            stream: true
        )

        request.httpBody = try JSONEncoder().encode(body)

        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIProviderError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            var responseBody = ""
            for try await line in bytes.lines {
                responseBody += line
                if responseBody.count > 2000 {
                    break
                }
            }

            let message = responseBody.trimmingCharacters(in: .whitespacesAndNewlines)
            if message.isEmpty {
                throw AIProviderError.requestFailed("Model request failed with HTTP \(httpResponse.statusCode).")
            } else {
                throw AIProviderError.requestFailed("Model request failed with HTTP \(httpResponse.statusCode): \(message)")
            }
        }

        return AsyncThrowingStream { continuation in
            Task {
                do {
                    for try await line in bytes.lines {
                        if Task.isCancelled {
                            continuation.finish()
                            return
                        }

                        guard line.hasPrefix("data: ") else { continue }
                        let payload = String(line.dropFirst(6))
                        if payload == "[DONE]" {
                            continuation.finish()
                            return
                        }

                        guard let data = payload.data(using: .utf8) else { continue }
                        let chunk = try JSONDecoder().decode(ChatCompletionChunk.self, from: data)
                        for choice in chunk.choices {
                            if let content = choice.delta.content, !content.isEmpty {
                                continuation.yield(content)
                            }
                        }
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

private func sanitizedMessages(_ messages: [ChatMessage]) -> [ChatCompletionRequest.Message] {
    messages.compactMap { message in
        let content = message.content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return nil }

        switch message.role {
        case .system, .user, .assistant:
            return ChatCompletionRequest.Message(role: message.role.rawValue, content: content)
        }
    }
}

private func normalizedTemperature(_ temperature: Double, for endpoint: URL) -> Double {
    let host = endpoint.host ?? ""
    let needsZeroToOneTemperature = host.contains("bigmodel.cn") || host.contains("api.z.ai")
    let clamped = needsZeroToOneTemperature
        ? min(max(temperature, 0), 1)
        : temperature
    return (clamped * 100).rounded() / 100
}

private func normalizedMaxTokens(_ maxTokens: Int, for endpoint: URL) -> Int {
    let host = endpoint.host ?? ""
    if host.contains("bigmodel.cn") || host.contains("api.z.ai") {
        return min(max(maxTokens, 1), 131072)
    }
    return maxTokens
}

private func chatCompletionsEndpoint(from baseURL: URL) -> URL {
    let normalizedPath = baseURL.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")).lowercased()
    if normalizedPath.hasSuffix("chat/completions") {
        return baseURL
    }

    return baseURL
        .appendingPathComponent("chat")
        .appendingPathComponent("completions")
}

private struct ChatCompletionRequest: Encodable {
    struct Message: Encodable {
        let role: String
        let content: String
    }

    let model: String
    let messages: [Message]
    let temperature: Double
    let max_tokens: Int
    let stream: Bool
}

private struct ChatCompletionChunk: Decodable {
    struct Choice: Decodable {
        struct Delta: Decodable {
            let content: String?
        }

        let delta: Delta
    }

    let choices: [Choice]
}
