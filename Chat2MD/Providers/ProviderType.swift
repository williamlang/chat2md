import Foundation

enum ProviderType: String, CaseIterable, Codable, Identifiable {
    case claude
    case gemini
    case codex

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .claude: return "Claude Code"
        case .gemini: return "Gemini CLI"
        case .codex: return "Codex CLI"
        }
    }

    var defaultPath: String {
        switch self {
        case .claude: return "~/.claude/projects"
        case .gemini: return "~/.gemini/tmp"
        case .codex: return "~/.codex/sessions"
        }
    }
}
