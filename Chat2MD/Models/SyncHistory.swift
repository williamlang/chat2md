import Foundation

struct SyncHistoryEntry: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let status: SyncStatus
    let filesProcessed: Int
    let errorMessage: String?
    let providers: [String]

    enum SyncStatus: String, Codable {
        case success
        case failure
        case skipped
    }

    enum CodingKeys: String, CodingKey {
        case id, timestamp, status, filesProcessed, errorMessage, providers
    }

    init(status: SyncStatus, filesProcessed: Int = 0, errorMessage: String? = nil, providers: [ProviderType] = []) {
        self.id = UUID()
        self.timestamp = Date()
        self.status = status
        self.filesProcessed = filesProcessed
        self.errorMessage = errorMessage
        self.providers = providers.map { $0.rawValue }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        status = try container.decode(SyncStatus.self, forKey: .status)
        filesProcessed = try container.decode(Int.self, forKey: .filesProcessed)
        errorMessage = try container.decodeIfPresent(String.self, forKey: .errorMessage)
        providers = try container.decodeIfPresent([String].self, forKey: .providers) ?? []
    }

    var providerTypes: [ProviderType] {
        providers.compactMap { ProviderType(rawValue: $0) }
    }
}

struct SyncHistory: Codable {
    var entries: [SyncHistoryEntry]
    static let maxEntries = 48

    init() {
        self.entries = []
    }

    mutating func add(_ entry: SyncHistoryEntry) {
        entries.append(entry)
        if entries.count > Self.maxEntries {
            entries.removeFirst(entries.count - Self.maxEntries)
        }
    }

    var lastEntry: SyncHistoryEntry? {
        entries.last
    }
}
