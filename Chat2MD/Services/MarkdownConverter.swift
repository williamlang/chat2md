import Foundation

class MarkdownConverter {
    /// Generate YAML frontmatter for a new markdown file
    /// - Parameters:
    ///   - provider: Provider type identifier
    ///   - projectName: Project name
    ///   - metadata: Session metadata (session ID and cwd)
    /// - Returns: YAML frontmatter string including opening and closing ---
    func generateFrontmatter(provider: ProviderType, projectName: String, metadata: SessionMetadata) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())

        var lines: [String] = ["---"]
        lines.append("date: \"[[\(dateString)]]\"")
        lines.append("provider: \(provider.rawValue)")
        lines.append("project: \(projectName)")
        lines.append("session: \(metadata.sessionId)")
        if let cwd = metadata.workingDirectory {
            lines.append("cwd: \(cwd)")
        }
        lines.append("---")
        lines.append("")

        return lines.joined(separator: "\n")
    }

    /// Convert messages to markdown format for appending
    /// - Parameters:
    ///   - messages: Conversation messages to convert
    ///   - assistantName: Display name for assistant messages (e.g., "Claude Code", "Gemini CLI")
    func convertForAppend(messages: [ConversationMessage], assistantName: String = "Claude") -> String {
        var lines: [String] = []

        for message in messages {
            let prefix = message.role == .user ? "**User**:" : "**\(assistantName)**:"
            let content = message.content

            lines.append(prefix)
            // Table needs extra blank line to render properly
            if content.hasPrefix("|") {
                lines.append("")
            }
            lines.append(content)
            lines.append("")
            lines.append("")  // Two empty strings = one blank line after join
        }

        return lines.joined(separator: "\n")
    }

    func generateFilename(projectName: String, sessionId: String, date: Date, providerID: String = "claude", usePrefix: Bool = true) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)

        // Remove provider prefix from projectName if it exists (e.g., "codex-chat2md" -> "chat2md")
        var cleanProjectName = projectName
        for provider in ["claude-", "gemini-", "codex-"] {
            if cleanProjectName.hasPrefix(provider) {
                cleanProjectName = String(cleanProjectName.dropFirst(provider.count))
                break
            }
        }
        let sanitizedProject = sanitizeFilename(cleanProjectName)

        if usePrefix {
            // flat mode: yyyy-mm-dd-provider-project-sessionid.md
            return "\(dateString)-\(providerID)-\(sanitizedProject)-\(sessionId).md"
        } else {
            // subfolder mode: yyyy-mm-dd-project-sessionid.md
            return "\(dateString)-\(sanitizedProject)-\(sessionId).md"
        }
    }

    private func sanitizeFilename(_ name: String) -> String {
        let invalidChars = CharacterSet(charactersIn: "/\\:*?\"<>|")
        return name.components(separatedBy: invalidChars).joined(separator: "-")
    }
}
