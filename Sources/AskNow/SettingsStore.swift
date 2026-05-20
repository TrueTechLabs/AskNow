import Combine
import Foundation

final class SettingsStore: ObservableObject {
    @Published var settings: ModelSettings {
        didSet {
            AppText.setLanguage(settings.language)
            saveSettings()
        }
    }

    private let settingsKey = "modelSettings"
    private let apiKeysKey = "modelProfileAPIKeys"
    private let keychain = KeychainStore(service: "local.asknow.app.api-keys")

    init() {
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(ModelSettings.self, from: data) {
            settings = decoded
            AppText.setLanguage(settings.language)
            saveSettings()
        } else {
            settings = .defaults
            AppText.setLanguage(settings.language)
        }
        migrateLegacyAPIKeysIfNeeded()
    }

    var apiKey: String {
        get { apiKey(for: settings.defaultModelProfileID) }
        set {
            setAPIKey(newValue, for: settings.defaultModelProfileID)
        }
    }

    func apiKey(for profileID: String) -> String {
        keychain.read(account: profileID) ?? ""
    }

    func setAPIKey(_ value: String, for profileID: String) {
        if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            keychain.delete(account: profileID)
        } else {
            keychain.save(value, account: profileID)
        }
    }

    func restoreDefaultPrompts() {
        settings.promptModes = PromptMode.defaults
        settings.defaultPromptModeID = PromptMode.defaults.first?.id ?? "ask"
    }

    private func saveSettings() {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        UserDefaults.standard.set(data, forKey: settingsKey)
    }

    private func apiKeys() -> [String: String] {
        UserDefaults.standard.dictionary(forKey: apiKeysKey) as? [String: String] ?? [:]
    }

    private func migrateLegacyAPIKeysIfNeeded() {
        let legacyKeys = apiKeys()
        guard !legacyKeys.isEmpty else { return }

        var didMigrateAllKeys = true
        for (profileID, apiKey) in legacyKeys {
            let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            didMigrateAllKeys = keychain.save(apiKey, account: profileID) && didMigrateAllKeys
        }

        if didMigrateAllKeys {
            UserDefaults.standard.removeObject(forKey: apiKeysKey)
        }
    }
}
