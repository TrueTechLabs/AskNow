import Foundation

struct ChatMessage: Identifiable, Codable, Equatable {
    enum Role: String, Codable {
        case system
        case user
        case assistant
    }

    let id: UUID
    var role: Role
    var content: String
    var sourceUserMessageID: UUID?

    init(id: UUID = UUID(), role: Role, content: String, sourceUserMessageID: UUID? = nil) {
        self.id = id
        self.role = role
        self.content = content
        self.sourceUserMessageID = sourceUserMessageID
    }
}

struct PromptMode: Identifiable, Codable, Equatable {
    let id: String
    var nameEn: String
    var nameZh: String
    var systemPromptEn: String
    var systemPromptZh: String
    var colorHex: String
    var modelProfileID: String?
    var temperature: Double?
    var contextTurns: Int?

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case systemPrompt
        case nameEn
        case nameZh
        case systemPromptEn
        case systemPromptZh
        case colorHex
        case modelProfileID
        case temperature
        case contextTurns
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(nameEn, forKey: .nameEn)
        try container.encode(nameZh, forKey: .nameZh)
        try container.encode(systemPromptEn, forKey: .systemPromptEn)
        try container.encode(systemPromptZh, forKey: .systemPromptZh)
        try container.encode(colorHex, forKey: .colorHex)
        try container.encodeIfPresent(modelProfileID, forKey: .modelProfileID)
        try container.encodeIfPresent(temperature, forKey: .temperature)
        try container.encodeIfPresent(contextTurns, forKey: .contextTurns)
    }

    init(
        id: String,
        nameEn: String,
        nameZh: String,
        systemPromptEn: String,
        systemPromptZh: String,
        colorHex: String,
        modelProfileID: String? = nil,
        temperature: Double? = nil,
        contextTurns: Int? = nil
    ) {
        self.id = id
        self.nameEn = nameEn
        self.nameZh = nameZh
        self.systemPromptEn = systemPromptEn
        self.systemPromptZh = systemPromptZh
        self.colorHex = colorHex
        self.modelProfileID = modelProfileID
        self.temperature = temperature
        self.contextTurns = contextTurns
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        let legacyName = try container.decodeIfPresent(String.self, forKey: .name)
        let legacyPrompt = try container.decodeIfPresent(String.self, forKey: .systemPrompt)
        let defaults = PromptMode.builtInDefaults(for: id)
        nameEn = try container.decodeIfPresent(String.self, forKey: .nameEn) ?? defaults.nameEn ?? legacyName ?? "Custom"
        nameZh = try container.decodeIfPresent(String.self, forKey: .nameZh) ?? defaults.nameZh ?? legacyName ?? "自定义"
        systemPromptEn = try container.decodeIfPresent(String.self, forKey: .systemPromptEn) ?? defaults.promptEn ?? legacyPrompt ?? "You are a helpful assistant."
        systemPromptZh = try container.decodeIfPresent(String.self, forKey: .systemPromptZh) ?? defaults.promptZh ?? legacyPrompt ?? "你是一个有帮助的助手。"
        colorHex = try container.decodeIfPresent(String.self, forKey: .colorHex) ?? PromptMode.defaultColor(for: id)
        modelProfileID = try container.decodeIfPresent(String.self, forKey: .modelProfileID)
        temperature = try container.decodeIfPresent(Double.self, forKey: .temperature)
        contextTurns = try container.decodeIfPresent(Int.self, forKey: .contextTurns)
    }

    static let defaults: [PromptMode] = [
        PromptMode(
            id: "ask",
            nameEn: "Ask",
            nameZh: "问答",
            systemPromptEn: "You are AskNow, a concise desktop AI assistant. Answer directly and clearly. If the request is ambiguous, make a reasonable assumption and keep the response useful.",
            systemPromptZh: "你是 AskNow，一个简洁高效的桌面 AI 助手。直接、清楚地回答问题。如果请求不够明确，先做合理假设并给出有用回答。",
            colorHex: "#2F80ED"
        ),
        PromptMode(
            id: "translate",
            nameEn: "Translate",
            nameZh: "翻译",
            systemPromptEn: "You are a professional translation assistant. Translate the user's content into natural, fluent Chinese by default. Preserve meaning, tone, formatting, and technical terms where appropriate. Return only the translation unless clarification is needed.",
            systemPromptZh: "你是专业翻译助手。默认将用户内容翻译成自然流畅的中文，保留原意、语气、格式和必要的技术术语。除非需要澄清，否则只输出译文。",
            colorHex: "#27AE60",
            contextTurns: 1
        ),
        PromptMode(
            id: "summarize",
            nameEn: "Summarize",
            nameZh: "总结",
            systemPromptEn: "You summarize content into compact, scannable points. Preserve the important facts, decisions, and action items. Avoid adding information that is not present.",
            systemPromptZh: "你负责把内容总结成简洁、易扫读的要点。保留重要事实、结论、决定和行动项，不添加原文没有的信息。",
            colorHex: "#F2994A"
        ),
        PromptMode(
            id: "polish",
            nameEn: "Polish",
            nameZh: "润色",
            systemPromptEn: "You improve the user's writing while preserving the original meaning. Make it clear, natural, and concise. Return the polished version first.",
            systemPromptZh: "你负责在保留原意的前提下改进用户文字，使其清晰、自然、简洁。优先直接输出润色后的版本。",
            colorHex: "#9B51E0"
        )
    ]

    static func defaultColor(for id: String) -> String {
        defaults.first(where: { $0.id == id })?.colorHex ?? "#5E6AD2"
    }

    static func isBuiltInID(_ id: String) -> Bool {
        builtInDefaults(for: id).nameEn != nil
    }

    static func builtInDefaults(for id: String) -> (nameEn: String?, nameZh: String?, promptEn: String?, promptZh: String?) {
        switch id {
        case "ask":
            return (
                "Ask",
                "问答",
                "You are AskNow, a concise desktop AI assistant. Answer directly and clearly. If the request is ambiguous, make a reasonable assumption and keep the response useful.",
                "你是 AskNow，一个简洁高效的桌面 AI 助手。直接、清楚地回答问题。如果请求不够明确，先做合理假设并给出有用回答。"
            )
        case "translate":
            return (
                "Translate",
                "翻译",
                "You are a professional translation assistant. Translate the user's content into natural, fluent Chinese by default. Preserve meaning, tone, formatting, and technical terms where appropriate. Return only the translation unless clarification is needed.",
                "你是专业翻译助手。默认将用户内容翻译成自然流畅的中文，保留原意、语气、格式和必要的技术术语。除非需要澄清，否则只输出译文。"
            )
        case "summarize":
            return (
                "Summarize",
                "总结",
                "You summarize content into compact, scannable points. Preserve the important facts, decisions, and action items. Avoid adding information that is not present.",
                "你负责把内容总结成简洁、易扫读的要点。保留重要事实、结论、决定和行动项，不添加原文没有的信息。"
            )
        case "polish":
            return (
                "Polish",
                "润色",
                "You improve the user's writing while preserving the original meaning. Make it clear, natural, and concise. Return the polished version first.",
                "你负责在保留原意的前提下改进用户文字，使其清晰、自然、简洁。优先直接输出润色后的版本。"
            )
        default:
            return (nil, nil, nil, nil)
        }
    }

    var localizedName: String {
        if Self.isBuiltInID(id) {
            return AppText.isChinese ? nameZh : nameEn
        }
        return customName
    }

    var localizedSystemPrompt: String {
        AppText.isChinese ? systemPromptZh : systemPromptEn
    }

    var customName: String {
        let trimmedZh = nameZh.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEn = nameEn.trimmingCharacters(in: .whitespacesAndNewlines)

        if !trimmedZh.isEmpty && trimmedZh != "自定义" {
            return trimmedZh
        }
        if !trimmedEn.isEmpty && trimmedEn != "Custom" {
            return trimmedEn
        }
        return trimmedZh.isEmpty ? trimmedEn : trimmedZh
    }
}

struct ModelProfile: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var providerID: String
    var baseURL: String
    var model: String
    var temperature: Double
    var maxTokens: Int

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case providerID
        case baseURL
        case model
        case temperature
        case maxTokens
    }

    init(
        id: String,
        name: String,
        providerID: String = ProviderCatalog.customID,
        baseURL: String,
        model: String,
        temperature: Double,
        maxTokens: Int
    ) {
        self.id = id
        self.name = name
        self.providerID = providerID
        self.baseURL = baseURL
        self.model = model
        self.temperature = temperature
        self.maxTokens = maxTokens
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        baseURL = try container.decode(String.self, forKey: .baseURL)
        model = try container.decode(String.self, forKey: .model)
        temperature = try container.decode(Double.self, forKey: .temperature)
        maxTokens = try container.decode(Int.self, forKey: .maxTokens)
        providerID = try container.decodeIfPresent(String.self, forKey: .providerID) ?? ProviderCatalog.inferredProviderID(for: baseURL)
    }

    static let defaults = [
        ModelProfile(
            id: "default",
            name: "Default",
            baseURL: "https://code.newcli.com/codex/v1",
            model: "gpt-5.2",
            temperature: 0.7,
            maxTokens: 8192
        )
    ]
}

enum AppLanguage: String, Codable, CaseIterable, Identifiable {
    case system
    case chinese
    case english

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .system:
            AppText.followSystemLanguage
        case .chinese:
            AppText.chineseLanguage
        case .english:
            AppText.englishLanguage
        }
    }
}

struct ModelSettings: Codable, Equatable {
    var language: AppLanguage
    var baseURL: String
    var model: String
    var defaultTemperature: Double
    var defaultContextTurns: Int
    var maxTokens: Int
    var defaultModelProfileID: String
    var modelProfiles: [ModelProfile]
    var defaultPromptModeID: String
    var promptModes: [PromptMode]
    var shortcutKeyCode: UInt32
    var shortcutModifiers: UInt32

    private enum CodingKeys: String, CodingKey {
        case language
        case baseURL
        case model
        case temperature
        case defaultTemperature
        case defaultContextTurns
        case maxTokens
        case defaultModelProfileID
        case modelProfiles
        case defaultPromptModeID
        case promptModes
        case shortcutKeyCode
        case shortcutModifiers
    }

    static let defaults = ModelSettings(
        language: .system,
        baseURL: "https://code.newcli.com/codex/v1",
        model: "gpt-5.2",
        defaultTemperature: 0.7,
        defaultContextTurns: 6,
        maxTokens: 8192,
        defaultModelProfileID: "default",
        modelProfiles: ModelProfile.defaults,
        defaultPromptModeID: "ask",
        promptModes: PromptMode.defaults,
        shortcutKeyCode: 49,
        shortcutModifiers: 2048
    )

    init(
        language: AppLanguage,
        baseURL: String,
        model: String,
        defaultTemperature: Double,
        defaultContextTurns: Int,
        maxTokens: Int,
        defaultModelProfileID: String,
        modelProfiles: [ModelProfile],
        defaultPromptModeID: String,
        promptModes: [PromptMode],
        shortcutKeyCode: UInt32,
        shortcutModifiers: UInt32
    ) {
        self.language = language
        self.baseURL = baseURL
        self.model = model
        self.defaultTemperature = defaultTemperature
        self.defaultContextTurns = defaultContextTurns
        self.maxTokens = maxTokens
        self.defaultModelProfileID = defaultModelProfileID
        self.modelProfiles = modelProfiles
        self.defaultPromptModeID = defaultPromptModeID
        self.promptModes = promptModes
        self.shortcutKeyCode = shortcutKeyCode
        self.shortcutModifiers = shortcutModifiers
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        language = try container.decodeIfPresent(AppLanguage.self, forKey: .language) ?? Self.defaults.language
        baseURL = try container.decodeIfPresent(String.self, forKey: .baseURL) ?? Self.defaults.baseURL
        model = try container.decodeIfPresent(String.self, forKey: .model) ?? Self.defaults.model
        defaultTemperature = try container.decodeIfPresent(Double.self, forKey: .defaultTemperature) ?? container.decodeIfPresent(Double.self, forKey: .temperature) ?? Self.defaults.defaultTemperature
        defaultContextTurns = try container.decodeIfPresent(Int.self, forKey: .defaultContextTurns) ?? Self.defaults.defaultContextTurns
        maxTokens = try container.decodeIfPresent(Int.self, forKey: .maxTokens) ?? Self.defaults.maxTokens
        let decodedProfiles = try container.decodeIfPresent([ModelProfile].self, forKey: .modelProfiles)
        modelProfiles = decodedProfiles?.isEmpty == false ? decodedProfiles! : [
            ModelProfile(
                id: "default",
                name: "Default",
                baseURL: baseURL,
                model: model,
                temperature: defaultTemperature,
                maxTokens: maxTokens
            )
        ]
        modelProfiles = modelProfiles.map(Self.normalizedModelProfile)
        defaultModelProfileID = try container.decodeIfPresent(String.self, forKey: .defaultModelProfileID) ?? modelProfiles.first?.id ?? "default"
        defaultPromptModeID = try container.decodeIfPresent(String.self, forKey: .defaultPromptModeID) ?? Self.defaults.defaultPromptModeID
        promptModes = try container.decodeIfPresent([PromptMode].self, forKey: .promptModes) ?? Self.defaults.promptModes
        shortcutKeyCode = try container.decodeIfPresent(UInt32.self, forKey: .shortcutKeyCode) ?? Self.defaults.shortcutKeyCode
        shortcutModifiers = try container.decodeIfPresent(UInt32.self, forKey: .shortcutModifiers) ?? Self.defaults.shortcutModifiers
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(language, forKey: .language)
        try container.encode(baseURL, forKey: .baseURL)
        try container.encode(model, forKey: .model)
        try container.encode(defaultTemperature, forKey: .defaultTemperature)
        try container.encode(defaultContextTurns, forKey: .defaultContextTurns)
        try container.encode(maxTokens, forKey: .maxTokens)
        try container.encode(defaultModelProfileID, forKey: .defaultModelProfileID)
        try container.encode(modelProfiles, forKey: .modelProfiles)
        try container.encode(defaultPromptModeID, forKey: .defaultPromptModeID)
        try container.encode(promptModes, forKey: .promptModes)
        try container.encode(shortcutKeyCode, forKey: .shortcutKeyCode)
        try container.encode(shortcutModifiers, forKey: .shortcutModifiers)
    }

    func effectiveTemperature(for mode: PromptMode) -> Double {
        mode.temperature ?? defaultTemperature
    }

    func effectiveContextTurns(for mode: PromptMode) -> Int {
        mode.contextTurns ?? (mode.id == "translate" ? 1 : defaultContextTurns)
    }

    func effectiveModelProfile(for mode: PromptMode) -> ModelProfile {
        if let id = mode.modelProfileID,
           let profile = modelProfiles.first(where: { $0.id == id }) {
            return profile
        }

        if let profile = modelProfiles.first(where: { $0.id == defaultModelProfileID }) {
            return profile
        }

        return modelProfiles.first ?? ModelProfile.defaults[0]
    }

    private static func normalizedModelProfile(_ profile: ModelProfile) -> ModelProfile {
        var profile = profile
        if profile.baseURL.contains("open.bigmodel.cn"),
           profile.model == "glm-2323" {
            profile.model = "glm-5.1"
        }
        if profile.providerID == "zai",
           profile.baseURL.contains("api.z.ai") {
            profile.baseURL = "https://open.bigmodel.cn/api/paas/v4"
            profile.model = profile.model.isEmpty ? "glm-4.7" : profile.model
        }
        if profile.providerID == "zai",
           profile.maxTokens > 131072 {
            profile.maxTokens = 131072
        }
        return profile
    }
}
