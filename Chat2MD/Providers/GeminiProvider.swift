import Foundation

class GeminiProvider: Provider {
    let type: ProviderType = .gemini

    // Track last message count per file for incremental sync
    private var lastMessageCounts: [String: Int] = [:]

    func findSessionFiles(in basePath: String, maxAge: TimeInterval) throws -> [SessionFile] {
        let fm = FileManager.default
        let cutoffDate = Date().addingTimeInterval(-maxAge)

        guard fm.fileExists(atPath: basePath) else {
            return []
        }

        var sessionFiles: [SessionFile] = []

        // Gemini stores sessions in ~/.gemini/tmp/<hash>/chats/*.json (new format)
        // or ~/.gemini/tmp/<hash>/logs.json (legacy format)
        let hashDirs = try fm.contentsOfDirectory(atPath: basePath)

        for hashDir in hashDirs {
            let hashPath = (basePath as NSString).appendingPathComponent(hashDir)
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: hashPath, isDirectory: &isDir), isDir.boolValue else { continue }

            // Skip folder if not modified since cutoff
            if let folderAttrs = try? fm.attributesOfItem(atPath: hashPath),
               let folderModDate = folderAttrs[.modificationDate] as? Date,
               folderModDate < cutoffDate {
                continue
            }

            // Check for new format: chats/*.json
            let chatsPath = (hashPath as NSString).appendingPathComponent("chats")
            if fm.fileExists(atPath: chatsPath) {
                let chatFiles = (try? fm.contentsOfDirectory(atPath: chatsPath)) ?? []
                for chatFile in chatFiles where chatFile.hasSuffix(".json") {
                    let filePath = (chatsPath as NSString).appendingPathComponent(chatFile)
                    guard let attrs = try? fm.attributesOfItem(atPath: filePath),
                          let modDate = attrs[.modificationDate] as? Date,
                          let fileSize = attrs[.size] as? Int else { continue }

                    if modDate < cutoffDate { continue }

                    sessionFiles.append(SessionFile(
                        path: filePath,
                        modificationDate: modDate,
                        size: fileSize
                    ))
                }
            }

            // Also check for legacy format: logs.json
            let logsPath = (hashPath as NSString).appendingPathComponent("logs.json")
            if fm.fileExists(atPath: logsPath) {
                guard let attrs = try? fm.attributesOfItem(atPath: logsPath),
                      let modDate = attrs[.modificationDate] as? Date,
                      let fileSize = attrs[.size] as? Int else { continue }

                if modDate < cutoffDate { continue }

                sessionFiles.append(SessionFile(
                    path: logsPath,
                    modificationDate: modDate,
                    size: fileSize
                ))
            }
        }

        return sessionFiles
    }

    func parseMessages(from file: SessionFile, afterLine: Int, since: Date?) -> ParseResult {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: file.path)) else {
            return ParseResult(messages: [], totalLines: afterLine)
        }

        // Try new format first (chats/*.json)
        if let session = try? JSONDecoder().decode(GeminiSessionFile.self, from: data) {
            return parseNewFormat(session: session, afterLine: afterLine, since: since)
        }

        // Fall back to legacy format (logs.json)
        if let geminiLog = try? JSONDecoder().decode(GeminiLogFile.self, from: data) {
            return parseLegacyFormat(log: geminiLog, afterLine: afterLine)
        }

        return ParseResult(messages: [], totalLines: afterLine)
    }

    private func parseNewFormat(session: GeminiSessionFile, afterLine: Int, since: Date?) -> ParseResult {
        let allMessages = session.messages
        let totalCount = allMessages.count

        guard totalCount > afterLine else {
            return ParseResult(messages: [], totalLines: totalCount)
        }

        let newMessages = Array(allMessages.dropFirst(afterLine))
        var messages: [ConversationMessage] = []

        for geminiMsg in newMessages {
            // Skip info messages
            guard geminiMsg.isUserMessage || geminiMsg.isAssistantMessage else { continue }
            guard let text = geminiMsg.textContent, !text.isEmpty else { continue }

            // Filter by date if provided
            if let filterDate = since, let msgDate = geminiMsg.parsedTimestamp {
                if msgDate < filterDate { continue }
            }

            let role: ConversationMessage.MessageRole = geminiMsg.isUserMessage ? .user : .assistant

            messages.append(ConversationMessage(
                role: role,
                content: text,
                timestamp: geminiMsg.parsedTimestamp
            ))
        }

        return ParseResult(messages: messages, totalLines: totalCount)
    }

    private func parseLegacyFormat(log: GeminiLogFile, afterLine: Int) -> ParseResult {
        let allMessages = log.messages
        let totalCount = allMessages.count

        guard totalCount > afterLine else {
            return ParseResult(messages: [], totalLines: totalCount)
        }

        let newMessages = Array(allMessages.dropFirst(afterLine))
        var messages: [ConversationMessage] = []

        for geminiMsg in newMessages {
            guard let text = geminiMsg.textContent, !text.isEmpty else { continue }

            let role: ConversationMessage.MessageRole = geminiMsg.isUserMessage ? .user : .assistant

            messages.append(ConversationMessage(
                role: role,
                content: text,
                timestamp: nil
            ))
        }

        return ParseResult(messages: messages, totalLines: totalCount)
    }

    func resolveProjectName(for file: SessionFile) -> String {
        // Use short project hash as project name (Gemini doesn't store actual path)
        let projectHash = extractProjectHash(from: file.path)
        return String(projectHash.prefix(8))
    }

    func resolveMetadata(for file: SessionFile) -> SessionMetadata {
        // Get session ID from file content
        var sessionId: String
        if let data = try? Data(contentsOf: URL(fileURLWithPath: file.path)),
           let session = try? JSONDecoder().decode(GeminiSessionFile.self, from: data) {
            sessionId = String(session.sessionId.prefix(8))
        } else {
            // Fallback: use short project hash
            sessionId = String(extractProjectHash(from: file.path).prefix(8))
        }

        // Gemini doesn't provide working directory
        return SessionMetadata(sessionId: sessionId, workingDirectory: nil)
    }

    func clearCache() {
        lastMessageCounts.removeAll()
    }

    // MARK: - Private Helpers

    private func extractProjectHash(from path: String) -> String {
        // Path format: ~/.gemini/tmp/<hash>/chats/*.json or ~/.gemini/tmp/<hash>/logs.json
        let url = URL(fileURLWithPath: path)
        let components = url.pathComponents

        // Find "tmp" and get the next component (hash)
        if let tmpIndex = components.firstIndex(of: "tmp"), tmpIndex + 1 < components.count {
            return components[tmpIndex + 1]
        }

        return ""
    }
}
