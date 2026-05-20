import SwiftUI

struct SettingsView: View {
    @ObservedObject var settingsStore: SettingsStore
    @State private var selectedModelProfileID: String = ""
    @State private var selectedPromptModeID: String = ""
    @State private var apiKey: String = ""

    private let maxTokenPresets = [1024, 8192, 20000, 200000]

    var body: some View {
        Form {
            languageSection
            modelProfilesSection
            shortcutSection
            promptModesSection
        }
        .id(settingsStore.settings.language)
        .formStyle(.grouped)
        .padding(18)
        .frame(width: 700, height: 720)
        .onAppear {
            selectedModelProfileID = settingsStore.settings.defaultModelProfileID
            selectedPromptModeID = settingsStore.settings.defaultPromptModeID
            normalizeSelections()
            apiKey = settingsStore.apiKey(for: selectedModelProfileID)
        }
        .onChange(of: selectedModelProfileID) { profileID in
            apiKey = settingsStore.apiKey(for: profileID)
        }
    }

    private var languageSection: some View {
        Section(AppText.language) {
            Picker(AppText.language, selection: Binding(
                get: { settingsStore.settings.language },
                set: { language in
                    AppText.setLanguage(language)
                    settingsStore.settings.language = language
                }
            )) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.localizedName).tag(language)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var modelProfilesSection: some View {
        Section(AppText.modelProfiles) {
            Picker(AppText.modelProfiles, selection: $selectedModelProfileID) {
                ForEach(settingsStore.settings.modelProfiles) { profile in
                    Text(profile.name).tag(profile.id)
                }
            }

            if let profile = selectedModelProfileBinding {
                Picker(AppText.provider, selection: Binding(
                    get: { profile.wrappedValue.providerID },
                    set: { applyProviderPreset($0) }
                )) {
                    ForEach(ProviderCatalog.presets) { preset in
                        Text(preset.name).tag(preset.id)
                    }
                }

                if let preset = ProviderCatalog.preset(id: profile.wrappedValue.providerID),
                   !preset.isOpenAICompatible {
                    Text(AppText.nativeProviderHint)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                TextField(AppText.modelName, text: profile.name)
                TextField(AppText.baseURL, text: profile.baseURL)
                SecureField(AppText.apiKey, text: $apiKey)
                    .onChange(of: apiKey) { newValue in
                        settingsStore.setAPIKey(newValue, for: selectedModelProfileID)
                    }
                TextField(AppText.model, text: profile.model)

                HStack {
                    Text(AppText.temperature)
                    Slider(value: profile.temperature, in: 0...2, step: 0.1)
                    Text(profile.wrappedValue.temperature.formatted(.number.precision(.fractionLength(1))))
                        .monospacedDigit()
                        .frame(width: 36, alignment: .trailing)
                }

                HStack {
                    Text(AppText.maxTokens)
                    Spacer()
                    Picker(AppText.maxTokens, selection: profile.maxTokens) {
                        ForEach(maxTokenPresets, id: \.self) { value in
                            Text("\(value)").tag(value)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                }

                Toggle(AppText.choose("设为默认模型", "Use as default model"), isOn: Binding(
                    get: { settingsStore.settings.defaultModelProfileID == selectedModelProfileID },
                    set: { isOn in
                        if isOn {
                            settingsStore.settings.defaultModelProfileID = selectedModelProfileID
                        }
                    }
                ))
            }

            Stepper(value: $settingsStore.settings.defaultContextTurns, in: 0...50) {
                Text("\(AppText.defaultContextTurns): \(settingsStore.settings.defaultContextTurns)")
            }

            HStack {
                Button {
                    addModelProfile()
                } label: {
                    Label(AppText.addModel, systemImage: "plus")
                }

                Button(role: .destructive) {
                    deleteSelectedModelProfile()
                } label: {
                    Label(AppText.deleteModel, systemImage: "trash")
                }
                .disabled(settingsStore.settings.modelProfiles.count <= 1)
            }
        }
    }

    private var shortcutSection: some View {
        Section(AppText.shortcut) {
            HStack {
                Text(AppText.recordShortcut)
                Spacer()
                ShortcutRecorderButton(
                    keyCode: $settingsStore.settings.shortcutKeyCode,
                    modifiers: $settingsStore.settings.shortcutModifiers
                )
                .frame(width: 220, height: 30)
            }

            Text(AppText.defaultShortcutHint)
                .foregroundStyle(.secondary)
        }
    }

    private var promptModesSection: some View {
        Section(AppText.promptModes) {
            Picker(AppText.editPromptMode, selection: $selectedPromptModeID) {
                ForEach(settingsStore.settings.promptModes) { mode in
                    Text(mode.localizedName).tag(mode.id)
                }
            }

            if let mode = selectedPromptModeBinding {
                HStack {
                    TextField(AppText.name, text: localizedNameBinding(mode))
                        .font(.headline)

                    ColorPicker(
                        AppText.color,
                        selection: Binding(
                            get: { Color(hex: mode.wrappedValue.colorHex) },
                            set: { mode.wrappedValue.colorHex = $0.toHex() }
                        )
                    )
                    .labelsHidden()

                    if !isBuiltInMode(mode.wrappedValue.id) {
                        Button(role: .destructive) {
                            deleteMode(id: mode.wrappedValue.id)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .help(AppText.delete)
                    }
                }

                Picker(AppText.modelForMode, selection: Binding(
                    get: { mode.wrappedValue.modelProfileID ?? settingsStore.settings.defaultModelProfileID },
                    set: { mode.wrappedValue.modelProfileID = $0 }
                )) {
                    ForEach(settingsStore.settings.modelProfiles) { profile in
                        Text(profile.name).tag(profile.id)
                    }
                }

                Text(AppText.prompt)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextEditor(text: localizedPromptBinding(mode))
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 140)
                    .border(Color.secondary.opacity(0.2))

                HStack {
                    Text(AppText.modeTemperature)
                    Slider(
                        value: Binding(
                            get: { mode.wrappedValue.temperature ?? selectedModeModelTemperature(mode.wrappedValue) },
                            set: { mode.wrappedValue.temperature = $0 }
                        ),
                        in: 0...2,
                        step: 0.1
                    )
                    Text((mode.wrappedValue.temperature ?? selectedModeModelTemperature(mode.wrappedValue)).formatted(.number.precision(.fractionLength(1))))
                        .monospacedDigit()
                        .frame(width: 36, alignment: .trailing)
                }

                Stepper(
                    value: Binding(
                        get: { mode.wrappedValue.contextTurns ?? settingsStore.settings.defaultContextTurns },
                        set: { mode.wrappedValue.contextTurns = $0 }
                    ),
                    in: 0...50
                ) {
                    Text("\(AppText.modeContextTurns): \(mode.wrappedValue.contextTurns ?? settingsStore.settings.defaultContextTurns)")
                }
            }

            Button {
                addPromptMode()
            } label: {
                Label(AppText.addPromptMode, systemImage: "plus")
            }

            Button(AppText.restoreDefaultPrompts) {
                settingsStore.restoreDefaultPrompts()
                selectedPromptModeID = settingsStore.settings.defaultPromptModeID
            }
        }
    }

    private var selectedModelProfileBinding: Binding<ModelProfile>? {
        guard let index = settingsStore.settings.modelProfiles.firstIndex(where: { $0.id == selectedModelProfileID }) else {
            return nil
        }
        return $settingsStore.settings.modelProfiles[index]
    }

    private var selectedPromptModeBinding: Binding<PromptMode>? {
        guard let index = settingsStore.settings.promptModes.firstIndex(where: { $0.id == selectedPromptModeID }) else {
            return nil
        }
        return $settingsStore.settings.promptModes[index]
    }

    private func addModelProfile() {
        let profile = ModelProfile(
            id: "model-\(UUID().uuidString)",
            name: AppText.choose("新模型", "New Model"),
            providerID: ProviderCatalog.customID,
            baseURL: "https://code.newcli.com/codex/v1",
            model: "gpt-5.2",
            temperature: 0.7,
            maxTokens: 8192
        )
        settingsStore.settings.modelProfiles.append(profile)
        selectedModelProfileID = profile.id
        apiKey = ""
    }

    private func deleteSelectedModelProfile() {
        guard settingsStore.settings.modelProfiles.count > 1 else { return }
        let deletedID = selectedModelProfileID
        settingsStore.settings.modelProfiles.removeAll { $0.id == deletedID }
        for index in settingsStore.settings.promptModes.indices where settingsStore.settings.promptModes[index].modelProfileID == deletedID {
            settingsStore.settings.promptModes[index].modelProfileID = nil
        }
        if settingsStore.settings.defaultModelProfileID == deletedID {
            settingsStore.settings.defaultModelProfileID = settingsStore.settings.modelProfiles.first?.id ?? "default"
        }
        selectedModelProfileID = settingsStore.settings.defaultModelProfileID
        apiKey = settingsStore.apiKey(for: selectedModelProfileID)
    }

    private func applyProviderPreset(_ providerID: String) {
        guard let index = settingsStore.settings.modelProfiles.firstIndex(where: { $0.id == selectedModelProfileID }) else {
            return
        }

        settingsStore.settings.modelProfiles[index].providerID = providerID
        guard providerID != ProviderCatalog.customID,
              let preset = ProviderCatalog.preset(id: providerID) else {
            return
        }

        settingsStore.settings.modelProfiles[index].name = preset.name
        if !preset.baseURL.isEmpty {
            settingsStore.settings.modelProfiles[index].baseURL = preset.baseURL
        }
        if !preset.defaultModel.isEmpty {
            settingsStore.settings.modelProfiles[index].model = preset.defaultModel
        }
    }

    private func addPromptMode() {
        let name = AppText.choose("自定义", "Custom")
        let mode = PromptMode(
            id: "custom-\(UUID().uuidString)",
            nameEn: name,
            nameZh: name,
            systemPromptEn: "You are a helpful assistant.",
            systemPromptZh: "你是一个有帮助的助手。",
            colorHex: "#5E6AD2",
            modelProfileID: settingsStore.settings.defaultModelProfileID
        )
        settingsStore.settings.promptModes.append(mode)
        selectedPromptModeID = mode.id
    }

    private func deleteMode(id: String) {
        settingsStore.settings.promptModes.removeAll { $0.id == id }
        if settingsStore.settings.defaultPromptModeID == id {
            settingsStore.settings.defaultPromptModeID = settingsStore.settings.promptModes.first?.id ?? "ask"
        }
        selectedPromptModeID = settingsStore.settings.defaultPromptModeID
    }

    private func normalizeSelections() {
        if !settingsStore.settings.modelProfiles.contains(where: { $0.id == selectedModelProfileID }) {
            selectedModelProfileID = settingsStore.settings.defaultModelProfileID
        }
        if !settingsStore.settings.promptModes.contains(where: { $0.id == selectedPromptModeID }) {
            selectedPromptModeID = settingsStore.settings.defaultPromptModeID
        }
        if !maxTokenPresets.contains(settingsStore.settings.maxTokens) {
            settingsStore.settings.maxTokens = 8192
        }
        for index in settingsStore.settings.modelProfiles.indices where !maxTokenPresets.contains(settingsStore.settings.modelProfiles[index].maxTokens) {
            settingsStore.settings.modelProfiles[index].maxTokens = 8192
        }
    }

    private func selectedModeModelTemperature(_ mode: PromptMode) -> Double {
        settingsStore.settings.effectiveModelProfile(for: mode).temperature
    }

    private func isBuiltInMode(_ id: String) -> Bool {
        PromptMode.isBuiltInID(id)
    }

    private func localizedNameBinding(_ mode: Binding<PromptMode>) -> Binding<String> {
        Binding(
            get: {
                if isBuiltInMode(mode.wrappedValue.id) {
                    return AppText.isChinese ? mode.wrappedValue.nameZh : mode.wrappedValue.nameEn
                }
                return mode.wrappedValue.customName
            },
            set: { value in
                if isBuiltInMode(mode.wrappedValue.id) && AppText.isChinese {
                    mode.wrappedValue.nameZh = value
                } else if isBuiltInMode(mode.wrappedValue.id) {
                    mode.wrappedValue.nameEn = value
                } else {
                    mode.wrappedValue.nameZh = value
                    mode.wrappedValue.nameEn = value
                }
            }
        )
    }

    private func localizedPromptBinding(_ mode: Binding<PromptMode>) -> Binding<String> {
        Binding(
            get: { AppText.isChinese ? mode.wrappedValue.systemPromptZh : mode.wrappedValue.systemPromptEn },
            set: { value in
                if AppText.isChinese {
                    mode.wrappedValue.systemPromptZh = value
                } else {
                    mode.wrappedValue.systemPromptEn = value
                }
            }
        )
    }
}
