import Foundation

// MARK: - New format (chats/*.json)

/// Represents a session file from Gemini CLI chats folder
struct GeminiSessionFile: Codable {
    let sessionId: String
    let projectHash: String?
    let startTime: String?
    let lastUpdated: String?
    let messages: [GeminiChatMessage]
}

/// Represents a message in new Gemini CLI chat session format
struct GeminiChatMessage: Codable {
    let id: String?
    let timestamp: String?
    let type: String  // "user", "gemini", "info"
    let content: String?

    var isUserMessage: Bool {
        type == "user"
    }

    var isAssistantMessage: Bool {
        type == "gemini"
    }

    var textContent: String? {
        content
    }

    var parsedTimestamp: Date? {
        guard let ts = timestamp else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: ts) {
            return date
        }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: ts)
    }
}

// MARK: - Legacy format (logs.json)

/// Represents a message from Gemini CLI logs.json (legacy format)
struct GeminiMessage: Codable {
    let role: String  // "user" or "model"
    let parts: [GeminiPart]

    var isUserMessage: Bool {
        role == "user"
    }

    var isAssistantMessage: Bool {
        role == "model"
    }

    var textContent: String? {
        let texts = parts.compactMap { $0.text }
        return texts.isEmpty ? nil : texts.joined(separator: "\n")
    }
}

struct GeminiPart: Codable {
    let text: String?
}

/// Wrapper for the logs.json array structure (legacy format)
struct GeminiLogFile: Codable {
    let messages: [GeminiMessage]

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        messages = try container.decode([GeminiMessage].self)
    }
}
