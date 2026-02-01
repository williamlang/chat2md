import Foundation

/// Represents a line from Codex CLI JSONL sessions
/// Format: {"timestamp": "...", "type": "response_item"/"session_meta", "payload": {...}}
struct CodexMessage: Codable {
    let timestamp: String?
    let type: String?
    let payload: CodexPayload?

    var isUserMessage: Bool {
        guard type == "response_item" && payload?.role == "user" else { return false }
        // Filter out system injections disguised as user messages
        guard let text = textContent else { return false }
        let systemPrefixes = [
            "<permissions",
            "<environment_context>",
            "# AGENTS.md",
            "<INSTRUCTIONS>"
        ]
        for prefix in systemPrefixes {
            if text.hasPrefix(prefix) { return false }
        }
        return true
    }

    var isAssistantMessage: Bool {
        type == "response_item" && payload?.role == "assistant"
    }

    var textContent: String? {
        // Extract text from content array
        payload?.content?.compactMap { block -> String? in
            if block.type == "input_text" || block.type == "output_text" {
                return block.text
            }
            return nil
        }.joined(separator: "\n")
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

struct CodexPayload: Codable {
    let type: String?       // "message" for response_item
    let role: String?       // "user", "assistant", "developer"
    let content: [CodexContentBlock]?  // array of content blocks
    let cwd: String?        // working directory (in session_meta)
}

struct CodexContentBlock: Codable {
    let type: String?       // "input_text", "output_text"
    let text: String?
}
