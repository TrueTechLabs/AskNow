import type { ProviderPreset } from './types'

export const PROVIDER_PRESETS: ProviderPreset[] = [
  { id: 'custom', name: 'Custom Provider', baseURL: '', defaultModel: '', isOpenAICompatible: true },
  { id: 'openai', name: 'OpenAI', baseURL: 'https://api.openai.com/v1', defaultModel: 'gpt-4o', isOpenAICompatible: true },
  { id: 'anthropic', name: 'Anthropic', baseURL: 'https://api.anthropic.com/v1', defaultModel: 'claude-sonnet-4-5-20250929', isOpenAICompatible: true },
  { id: 'deepseek', name: 'DeepSeek', baseURL: 'https://api.deepseek.com', defaultModel: 'deepseek-chat', isOpenAICompatible: true },
  { id: 'google', name: 'Google Gemini', baseURL: 'https://generativelanguage.googleapis.com/v1beta/openai', defaultModel: 'gemini-2.5-pro', isOpenAICompatible: true },
  { id: 'openrouter', name: 'OpenRouter', baseURL: 'https://openrouter.ai/api/v1', defaultModel: '', isOpenAICompatible: true },
  { id: 'ollama', name: 'Ollama', baseURL: 'http://localhost:11434/v1', defaultModel: 'llama3.2', isOpenAICompatible: true },
  { id: 'together', name: 'Together AI', baseURL: 'https://api.together.xyz/v1', defaultModel: '', isOpenAICompatible: true },
  { id: 'mistral', name: 'Mistral AI', baseURL: 'https://api.mistral.ai/v1', defaultModel: 'mistral-large-latest', isOpenAICompatible: true },
  { id: 'xai', name: 'xAI (Grok)', baseURL: 'https://api.x.ai/v1', defaultModel: 'grok-4', isOpenAICompatible: true },
  { id: 'moonshot', name: 'Moonshot AI (Kimi)', baseURL: 'https://api.moonshot.cn/v1', defaultModel: 'kimi-k2.5', isOpenAICompatible: true },
  { id: 'kimi-code', name: 'Kimi Code', baseURL: 'https://api.moonshot.cn/v1', defaultModel: 'kimi-k2.5', isOpenAICompatible: true },
  { id: 'qwen', name: 'Qwen', baseURL: 'https://dashscope.aliyuncs.com/compatible-mode/v1', defaultModel: 'qwen-plus', isOpenAICompatible: true },
  { id: 'qwen-model-studio', name: 'Qwen (Alibaba Cloud Model Studio)', baseURL: 'https://dashscope.aliyuncs.com/compatible-mode/v1', defaultModel: 'qwen-plus', isOpenAICompatible: true },
  { id: 'zhipu', name: 'Z.AI / BigModel', baseURL: 'https://open.bigmodel.cn/api/paas/v4', defaultModel: 'glm-5.1', isOpenAICompatible: true },
  { id: 'qianfan', name: 'Qianfan', baseURL: 'https://qianfan.baidubce.com/v2', defaultModel: '', isOpenAICompatible: true },
  { id: 'volcano-engine', name: 'Volcano Engine', baseURL: 'https://ark.cn-beijing.volces.com/api/v3', defaultModel: '', isOpenAICompatible: true },
  { id: 'byteplus', name: 'BytePlus', baseURL: 'https://ark.ap-southeast.bytepluses.com/api/coding/v3', defaultModel: 'ark-code-latest', isOpenAICompatible: true },
  { id: 'minimax', name: 'MiniMax', baseURL: 'https://api.minimax.io/v1', defaultModel: '', isOpenAICompatible: true },
  { id: 'huggingface', name: 'Hugging Face', baseURL: 'https://router.huggingface.co/v1', defaultModel: '', isOpenAICompatible: true },
  { id: 'chutes', name: 'Chutes', baseURL: 'https://llm.chutes.ai/v1', defaultModel: '', isOpenAICompatible: true },
  { id: 'venice', name: 'Venice AI', baseURL: 'https://api.venice.ai/api/v1', defaultModel: '', isOpenAICompatible: true },
  { id: 'litellm', name: 'LiteLLM', baseURL: 'http://localhost:4000/v1', defaultModel: '', isOpenAICompatible: true },
  { id: 'vllm', name: 'vLLM', baseURL: 'http://localhost:8000/v1', defaultModel: '', isOpenAICompatible: true },
  { id: 'sglang', name: 'SGLang', baseURL: 'http://localhost:30000/v1', defaultModel: '', isOpenAICompatible: true },
  { id: 'cloudflare-ai-gateway', name: 'Cloudflare AI Gateway', baseURL: 'https://gateway.ai.cloudflare.com/v1/{account_id}/{gateway_id}/openai', defaultModel: '', isOpenAICompatible: true },
  { id: 'vercel-ai-gateway', name: 'Vercel AI Gateway', baseURL: 'https://ai-gateway.vercel.sh/v1', defaultModel: '', isOpenAICompatible: true },
  { id: 'copilot', name: 'Copilot', baseURL: 'https://api.githubcopilot.com', defaultModel: '', isOpenAICompatible: true },
  { id: 'kilo-gateway', name: 'Kilo Gateway', baseURL: '', defaultModel: '', isOpenAICompatible: true },
  { id: 'opencode', name: 'OpenCode', baseURL: '', defaultModel: '', isOpenAICompatible: true },
  { id: 'synthetic', name: 'Synthetic', baseURL: '', defaultModel: '', isOpenAICompatible: true },
  { id: 'xiaomi', name: 'Xiaomi', baseURL: '', defaultModel: '', isOpenAICompatible: true },
]

export function getProviderPreset(id: string): ProviderPreset | undefined {
  return PROVIDER_PRESETS.find((p) => p.id === id)
}
