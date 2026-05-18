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
    }

    var apiKey: String {
        get { apiKey(for: settings.defaultModelProfileID) }
        set {
            setAPIKey(newValue, for: settings.defaultModelProfileID)
        }
    }

    func apiKey(for profileID: String) -> String {
        apiKeys()[profileID] ?? ""
    }

    func setAPIKey(_ value: String, for profileID: String) {
        var keys = apiKeys()
        if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            keys.removeValue(forKey: profileID)
        } else {
            keys[profileID] = value
        }
        UserDefaults.standard.set(keys, forKey: apiKeysKey)
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
}
