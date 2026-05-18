import Foundation

enum AppText {
    static let languagePreferenceKey = "appLanguagePreference"

    static var isChinese: Bool {
        switch UserDefaults.standard.string(forKey: languagePreferenceKey) {
        case AppLanguage.chinese.rawValue:
            return true
        case AppLanguage.english.rawValue:
            return false
        default:
            return Locale.preferredLanguages.first?.lowercased().hasPrefix("zh") == true
        }
    }

    static func setLanguage(_ language: AppLanguage) {
        UserDefaults.standard.set(language.rawValue, forKey: languagePreferenceKey)
    }

    static func choose(_ zh: String, _ en: String) -> String {
        isChinese ? zh : en
    }

    static var settings: String { choose("设置", "Settings") }
    static var showAskNow: String { choose("显示 AskNow", "Show AskNow") }
    static var quitAskNow: String { choose("退出 AskNow", "Quit AskNow") }
    static var settingsTitle: String { choose("AskNow 设置", "AskNow Settings") }
    static var copyLastAnswer: String { choose("复制上一条回答", "Copy last answer") }
    static var copy: String { choose("复制", "Copy") }
    static var cut: String { choose("剪切", "Cut") }
    static var paste: String { choose("粘贴", "Paste") }
    static var selectAll: String { choose("全选", "Select All") }
    static var clearSession: String { choose("清空会话", "Clear session") }
    static var close: String { choose("关闭", "Close") }
    static var ready: String { choose("准备就绪", "Ready") }
    static var emptyHint: String { choose("输入问题、粘贴要翻译的内容，或切换上方模式。", "Ask a question, paste text to translate, or switch modes above.") }
    static var typePlaceholder: String { choose("输入问题或粘贴内容...", "Type a question or paste content...") }
    static var send: String { choose("发送", "Send") }
    static var retry: String { choose("重试", "Retry") }
    static var you: String { choose("你", "You") }
    static var thinking: String { choose("思考中...", "Thinking...") }

    static var language: String { choose("语言", "Language") }
    static var followSystemLanguage: String { choose("跟随系统", "Follow System") }
    static var chineseLanguage: String { choose("中文", "Chinese") }
    static var englishLanguage: String { choose("英文", "English") }
    static var modelSection: String { choose("模型", "Model") }
    static var modelProfiles: String { choose("模型配置", "Model Profiles") }
    static var addModel: String { choose("增加模型", "Add Model") }
    static var deleteModel: String { choose("删除模型", "Delete Model") }
    static var provider: String { choose("供应商", "Provider") }
    static var nativeProviderHint: String { choose("该供应商不是 OpenAI-compatible 协议，当前版本会先保存配置，后续需要接入专用调用适配。", "This provider is not OpenAI-compatible. AskNow will save the profile now, but needs a provider adapter before chat calls can use it.") }
    static var modelName: String { choose("配置名称", "Profile Name") }
    static var baseURL: String { choose("Base URL", "Base URL") }
    static var apiKey: String { choose("API Key", "API Key") }
    static var model: String { choose("模型", "Model") }
    static var temperature: String { choose("Temperature", "Temperature") }
    static var maxTokens: String { choose("Max tokens", "Max tokens") }
    static var defaultTemperature: String { choose("默认温度", "Default temperature") }
    static var defaultContextTurns: String { choose("默认上下文轮次", "Default context turns") }
    static var modeTemperature: String { choose("模式温度", "Mode temperature") }
    static var modeContextTurns: String { choose("模式上下文轮次", "Mode context turns") }
    static var defaultMode: String { choose("默认模式", "Default mode") }
    static var modelForMode: String { choose("该模式使用的模型", "Model for this mode") }
    static var editPromptMode: String { choose("编辑模式", "Edit mode") }
    static var choosePreset: String { choose("常用选项", "Common options") }
    static var manual: String { choose("手动输入", "Manual") }

    static var shortcut: String { choose("快捷键", "Shortcut") }
    static var recordShortcut: String { choose("录入快捷键", "Record shortcut") }
    static var recordingShortcut: String { choose("请按下快捷键...", "Press shortcut...") }
    static var defaultShortcutHint: String { choose("默认是 Option + Space。点击按钮后按下想使用的组合键。", "Default is Option + Space. Click the button and press the shortcut you want.") }

    static var promptModes: String { choose("提示词模式", "Prompt Modes") }
    static var name: String { choose("名称", "Name") }
    static var prompt: String { choose("提示词", "Prompt") }
    static var color: String { choose("颜色", "Color") }
    static var addPromptMode: String { choose("增加自定义模式", "Add custom mode") }
    static var delete: String { choose("删除", "Delete") }
    static var regenerate: String { choose("重新生成", "Regenerate") }
    static var restoreDefaultPrompts: String { choose("恢复默认提示词", "Restore Default Prompts") }

    static var askMode: String { choose("问答", "Ask") }
    static var translateMode: String { choose("翻译", "Translate") }
    static var summarizeMode: String { choose("总结", "Summarize") }
    static var polishMode: String { choose("润色", "Polish") }
}
