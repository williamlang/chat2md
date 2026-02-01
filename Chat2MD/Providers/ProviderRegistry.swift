import Foundation

/// Registry managing all available providers
class ProviderRegistry {
    private var providers: [ProviderType: Provider] = [:]

    init() {
        // Register all built-in providers
        register(ClaudeProvider())
        register(GeminiProvider())
        register(CodexProvider())
    }

    func register(_ provider: Provider) {
        providers[provider.type] = provider
    }

    func provider(for type: ProviderType) -> Provider? {
        providers[type]
    }

    func allProviders() -> [Provider] {
        ProviderType.allCases.compactMap { providers[$0] }
    }

    func enabledProviders(settings: Settings) -> [Provider] {
        var result: [Provider] = []
        for providerType in ProviderType.allCases {
            if settings.isProviderEnabled(providerType),
               let provider = providers[providerType] {
                result.append(provider)
            }
        }
        return result
    }
}
