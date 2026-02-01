import Foundation

/// Represents a file containing session/conversation data
struct SessionFile {
    let path: String
    let modificationDate: Date
    let size: Int
}

/// Result of parsing messages from a session file
struct ParseResult {
    let messages: [ConversationMessage]
    let totalLines: Int
}

/// Protocol defining the interface for AI CLI providers
protocol Provider {
    /// Provider type identifier
    var type: ProviderType { get }

    /// Display name for UI (e.g., "Claude Code")
    var displayName: String { get }

    /// Default path where session files are stored
    var defaultPath: String { get }

    /// Find session files within the base path
    /// - Parameters:
    ///   - basePath: Root directory to search
    ///   - maxAge: Maximum age of sessions to include
    /// - Returns: Array of session files matching criteria
    func findSessionFiles(in basePath: String, maxAge: TimeInterval) throws -> [SessionFile]

    /// Parse messages from a session file
    /// - Parameters:
    ///   - file: Session file to parse
    ///   - afterLine: Start parsing after this line number (for incremental sync)
    ///   - since: Only include messages after this date
    /// - Returns: Parse result with messages and line count
    func parseMessages(from file: SessionFile, afterLine: Int, since: Date?) -> ParseResult

    /// Resolve project name for a session file
    /// - Parameter file: Session file
    /// - Returns: Human-readable project name
    func resolveProjectName(for file: SessionFile) -> String

    /// Resolve metadata for a session file (session ID and working directory)
    /// - Parameter file: Session file
    /// - Returns: Session metadata for frontmatter
    func resolveMetadata(for file: SessionFile) -> SessionMetadata

    /// Clear any caches (called at start of sync cycle)
    func clearCache()
}

extension Provider {
    var displayName: String { type.displayName }
    var defaultPath: String { type.defaultPath }
}
