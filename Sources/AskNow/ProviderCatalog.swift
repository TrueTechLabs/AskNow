import Foundation

struct ProviderPreset: Identifiable, Equatable {
    let id: String
    let name: String
    let baseURL: String
    let defaultModel: String
    let isOpenAICompatible: Bool
}

enum ProviderCatalog {
    static let customID = "custom"

    static let presets: [ProviderPreset] = [
        ProviderPreset(id: customID, name: "Custom Provider", baseURL: "", defaultModel: "", isOpenAICompatible: true),
        ProviderPreset(id: "openai", name: "OpenAI", baseURL: "https://api.openai.com/v1", defaultModel: "gpt-5.2", isOpenAICompatible: true),
        ProviderPreset(id: "anthropic", name: "Anthropic", baseURL: "https://api.anthropic.com/v1", defaultModel: "claude-sonnet-4-5-20250929", isOpenAICompatible: false),
        ProviderPreset(id: "byteplus", name: "BytePlus", baseURL: "https://ark.ap-southeast.bytepluses.com/api/coding/v3", defaultModel: "ark-code-latest", isOpenAICompatible: true),
        ProviderPreset(id: "chutes", name: "Chutes", baseURL: "https://llm.chutes.ai/v1", defaultModel: "", isOpenAICompatible: true),
        ProviderPreset(id: "cloudflare-ai-gateway", name: "Cloudflare AI Gateway", baseURL: "https://gateway.ai.cloudflare.com/v1/{account_id}/{gateway_id}/openai", defaultModel: "", isOpenAICompatible: true),
        ProviderPreset(id: "copilot", name: "Copilot", baseURL: "https://api.githubcopilot.com", defaultModel: "", isOpenAICompatible: false),
        ProviderPreset(id: "deepseek", name: "DeepSeek", baseURL: "https://api.deepseek.com", defaultModel: "deepseek-chat", isOpenAICompatible: true),
        ProviderPreset(id: "google", name: "Google Gemini", baseURL: "https://generativelanguage.googleapis.com/v1beta/openai", defaultModel: "gemini-2.5-pro", isOpenAICompatible: true),
        ProviderPreset(id: "huggingface", name: "Hugging Face", baseURL: "https://router.huggingface.co/v1", defaultModel: "", isOpenAICompatible: true),
        ProviderPreset(id: "kilo-gateway", name: "Kilo Gateway", baseURL: "", defaultModel: "", isOpenAICompatible: true),
        ProviderPreset(id: "kimi-code", name: "Kimi Code", baseURL: "https://api.moonshot.cn/v1", defaultModel: "kimi-k2.5", isOpenAICompatible: true),
        ProviderPreset(id: "litellm", name: "LiteLLM", baseURL: "http://localhost:4000/v1", defaultModel: "", isOpenAICompatible: true),
        ProviderPreset(id: "minimax", name: "MiniMax", baseURL: "https://api.minimax.io/v1", defaultModel: "", isOpenAICompatible: true),
        ProviderPreset(id: "mistral", name: "Mistral AI", baseURL: "https://api.mistral.ai/v1", defaultModel: "mistral-large-latest", isOpenAICompatible: true),
        ProviderPreset(id: "moonshot", name: "Moonshot AI (Kimi)", baseURL: "https://api.moonshot.cn/v1", defaultModel: "kimi-k2.5", isOpenAICompatible: true),
        ProviderPreset(id: "ollama", name: "Ollama", baseURL: "http://localhost:11434/v1", defaultModel: "llama3.2", isOpenAICompatible: true),
        ProviderPreset(id: "opencode", name: "OpenCode", baseURL: "", defaultModel: "", isOpenAICompatible: true),
        ProviderPreset(id: "openrouter", name: "OpenRouter", baseURL: "https://openrouter.ai/api/v1", defaultModel: "", isOpenAICompatible: true),
        ProviderPreset(id: "qianfan", name: "Qianfan", baseURL: "https://qianfan.baidubce.com/v2", defaultModel: "", isOpenAICompatible: true),
        ProviderPreset(id: "qwen", name: "Qwen", baseURL: "https://dashscope.aliyuncs.com/compatible-mode/v1", defaultModel: "qwen-plus", isOpenAICompatible: true),
        ProviderPreset(id: "qwen-model-studio", name: "Qwen (Alibaba Cloud Model Studio)", baseURL: "https://dashscope.aliyuncs.com/compatible-mode/v1", defaultModel: "qwen-plus", isOpenAICompatible: true),
        ProviderPreset(id: "sglang", name: "SGLang", baseURL: "http://localhost:30000/v1", defaultModel: "", isOpenAICompatible: true),
        ProviderPreset(id: "synthetic", name: "Synthetic", baseURL: "", defaultModel: "", isOpenAICompatible: true),
        ProviderPreset(id: "together", name: "Together AI", baseURL: "https://api.together.xyz/v1", defaultModel: "", isOpenAICompatible: true),
        ProviderPreset(id: "venice", name: "Venice AI", baseURL: "https://api.venice.ai/api/v1", defaultModel: "", isOpenAICompatible: true),
        ProviderPreset(id: "vercel-ai-gateway", name: "Vercel AI Gateway", baseURL: "https://ai-gateway.vercel.sh/v1", defaultModel: "", isOpenAICompatible: true),
        ProviderPreset(id: "vllm", name: "vLLM", baseURL: "http://localhost:8000/v1", defaultModel: "", isOpenAICompatible: true),
        ProviderPreset(id: "volcano-engine", name: "Volcano Engine", baseURL: "https://ark.cn-beijing.volces.com/api/v3", defaultModel: "", isOpenAICompatible: true),
        ProviderPreset(id: "xai", name: "xAI (Grok)", baseURL: "https://api.x.ai/v1", defaultModel: "grok-4", isOpenAICompatible: true),
        ProviderPreset(id: "xiaomi", name: "Xiaomi", baseURL: "", defaultModel: "", isOpenAICompatible: true),
        ProviderPreset(id: "zai", name: "Z.AI / BigModel", baseURL: "https://open.bigmodel.cn/api/paas/v4", defaultModel: "glm-5.1", isOpenAICompatible: true)
    ]

    static func preset(id: String) -> ProviderPreset? {
        presets.first { $0.id == id }
    }

    static func inferredProviderID(for baseURL: String) -> String {
        let normalized = baseURL.lowercased()
        if normalized.contains("open.bigmodel.cn") || normalized.contains("api.z.ai") {
            return "zai"
        }
        return presets.first { preset in
            !preset.baseURL.isEmpty && normalized.contains(preset.baseURL.lowercased())
        }?.id ?? customID
    }
}
