import Foundation
import SwiftUI

enum OutputOrganization: String, CaseIterable {
    case flat = "flat"           // vault/yyyy-mm-dd-provider-name.md
    case subfolder = "subfolder" // vault/provider/yyyy-mm-dd-name.md

    var description: String {
        switch self {
        case .flat: return "yyyy-mm-dd-provider-name.md"
        case .subfolder: return "provider/yyyy-mm-dd-name.md"
        }
    }
}

class Settings: ObservableObject {
    @AppStorage("destinationPath") var destinationPath: String = "~/Library/Mobile Documents/iCloud~md~obsidian/Documents/vault/claude"
    @AppStorage("syncIntervalSeconds") var syncIntervalSeconds: Int = 5
    @AppStorage("syncEnabled") var syncEnabled: Bool = true
    @AppStorage("sessionMaxAgeMinutes") var sessionMaxAgeMinutes: Int = 60
    @AppStorage("launchAtLogin") var launchAtLogin: Bool = false
    @AppStorage("outputOrganization") var outputOrganizationRaw: String = "flat"

    var outputOrganization: OutputOrganization {
        get { OutputOrganization(rawValue: outputOrganizationRaw) ?? .flat }
        set { outputOrganizationRaw = newValue.rawValue }
    }

    // MARK: - Provider Settings

    // Claude
    @AppStorage("claudeEnabled") var claudeEnabled: Bool = true
    @AppStorage("claudePath") var claudePath: String = "~/.claude/projects"

    // Gemini
    @AppStorage("geminiEnabled") var geminiEnabled: Bool = false
    @AppStorage("geminiPath") var geminiPath: String = "~/.gemini/tmp"

    // Codex
    @AppStorage("codexEnabled") var codexEnabled: Bool = false
    @AppStorage("codexPath") var codexPath: String = "~/.codex/sessions"

    // MARK: - Backward Compatibility

    /// Deprecated: Use claudePath instead
    var claudeProjectsPath: String {
        get { claudePath }
        set { claudePath = newValue }
    }

    var expandedDestinationPath: String {
        (destinationPath as NSString).expandingTildeInPath
    }

    /// Deprecated: Use expandedPath(for:) instead
    var expandedClaudeProjectsPath: String {
        (claudePath as NSString).expandingTildeInPath
    }

    // MARK: - Provider Helpers

    func isProviderEnabled(_ provider: ProviderType) -> Bool {
        switch provider {
        case .claude: return claudeEnabled
        case .gemini: return geminiEnabled
        case .codex: return codexEnabled
        }
    }

    func setProviderEnabled(_ provider: ProviderType, _ enabled: Bool) {
        switch provider {
        case .claude: claudeEnabled = enabled
        case .gemini: geminiEnabled = enabled
        case .codex: codexEnabled = enabled
        }
    }

    func path(for provider: ProviderType) -> String {
        switch provider {
        case .claude: return claudePath
        case .gemini: return geminiPath
        case .codex: return codexPath
        }
    }

    func setPath(_ path: String, for provider: ProviderType) {
        switch provider {
        case .claude: claudePath = path
        case .gemini: geminiPath = path
        case .codex: codexPath = path
        }
    }

    func expandedPath(for provider: ProviderType) -> String {
        (path(for: provider) as NSString).expandingTildeInPath
    }

    // MARK: - Path Validation

    /// Validates that a path is safe (no path traversal, absolute path)
    func isPathSafe(_ path: String) -> Bool {
        let expanded = (path as NSString).expandingTildeInPath
        // Must be absolute path and not contain path traversal
        return expanded.hasPrefix("/") && !expanded.contains("/../") && !expanded.hasSuffix("/..")
    }

    var isDestinationPathValid: Bool {
        isPathSafe(destinationPath)
    }

    /// Deprecated: Use isPathValid(for:) instead
    var isClaudeProjectsPathValid: Bool {
        isPathSafe(claudePath)
    }

    func isPathValid(for provider: ProviderType) -> Bool {
        isPathSafe(path(for: provider))
    }
}
