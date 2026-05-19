import type { PromptMode, Settings, ModelProfile } from './types'

export const BUILT_IN_PROMPT_MODES: PromptMode[] = [
  {
    id: 'ask',
    nameEn: 'Ask',
    nameZh: '问答',
    systemPromptEn:
      'You are AskNow, a concise desktop AI assistant. Answer directly and clearly. If the request is ambiguous, make a reasonable assumption and keep the response useful.',
    systemPromptZh:
      '你是 AskNow，一个简洁高效的桌面 AI 助手。直接、清楚地回答问题。如果请求不够明确，先做合理假设并给出有用回答。',
    colorHex: '#2F80ED',
  },
  {
    id: 'translate',
    nameEn: 'Translate',
    nameZh: '翻译',
    systemPromptEn:
      'You are a professional translation assistant. Translate the user\'s content into natural, fluent Chinese by default. Preserve meaning, tone, formatting, and technical terms where appropriate. Return only the translation unless clarification is needed.',
    systemPromptZh:
      '你是专业翻译助手。默认将用户内容翻译成自然流畅的中文，保留原意、语气、格式和必要的技术术语。除非需要澄清，否则只输出译文。',
    colorHex: '#27AE60',
    contextTurns: 1,
  },
  {
    id: 'summarize',
    nameEn: 'Summarize',
    nameZh: '总结',
    systemPromptEn:
      'You summarize content into compact, scannable points. Preserve the important facts, decisions, and action items. Avoid adding information that is not present.',
    systemPromptZh:
      '你负责把内容总结成简洁、易扫读的要点。保留重要事实、结论、决定和行动项，不添加原文没有的信息。',
    colorHex: '#F2994A',
  },
  {
    id: 'polish',
    nameEn: 'Polish',
    nameZh: '润色',
    systemPromptEn:
      'You improve the user\'s writing while preserving the original meaning. Make it clear, natural, and concise. Return the polished version first.',
    systemPromptZh:
      '你负责在保留原意的前提下改进用户文字，使其清晰、自然、简洁。优先直接输出润色后的版本。',
    colorHex: '#9B51E0',
  },
]

export const DEFAULT_MODEL_PROFILE: ModelProfile = {
  id: 'default',
  name: 'Default',
  providerID: 'openai',
  baseURL: 'https://api.openai.com/v1',
  model: 'gpt-4o',
  temperature: 0.7,
  maxTokens: 8192,
}

export const DEFAULT_SETTINGS: Settings = {
  language: 'system',
  defaultTemperature: 0.7,
  defaultContextTurns: 6,
  maxTokens: 8192,
  defaultModelProfileID: 'default',
  defaultPromptModeID: 'ask',
}

export const MAX_TOKEN_PRESETS = [1024, 8192, 20000, 200000] as const
