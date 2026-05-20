import Foundation

struct ConversationStore {
    private struct Payload: Codable {
        let version: Int
        let conversations: [String: [ChatMessage]]
    }

    private let fileManager: FileManager
    private let fileURL: URL

    init(fileManager: FileManager = .default, fileURL: URL? = nil) {
        self.fileManager = fileManager
        self.fileURL = fileURL ?? Self.defaultFileURL(fileManager: fileManager)
    }

    func load() -> [String: [ChatMessage]] {
        guard fileManager.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let payload = try? JSONDecoder().decode(Payload.self, from: data) else {
            return [:]
        }

        return payload.conversations
    }

    func save(_ conversations: [String: [ChatMessage]]) {
        do {
            let directoryURL = fileURL.deletingLastPathComponent()
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            let payload = Payload(version: 1, conversations: conversations)
            let data = try JSONEncoder().encode(payload)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            // Persistence should never block the assistant UI.
        }
    }

    private static func defaultFileURL(fileManager: FileManager) -> URL {
        let baseURL = try? fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        return (baseURL ?? fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support"))
            .appendingPathComponent("AskNow", isDirectory: true)
            .appendingPathComponent("conversations.json")
    }
}
