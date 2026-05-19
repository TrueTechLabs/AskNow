export type AppLanguage = 'system' | 'chinese' | 'english'

export interface ChatMessage {
  id: string
  role: 'system' | 'user' | 'assistant'
  content: string
  sourceUserMessageID?: string
}

export interface PromptMode {
  id: string
  nameEn: string
  nameZh: string
  systemPromptEn: string
  systemPromptZh: string
  colorHex: string
  modelProfileID?: string
  temperature?: number
  contextTurns?: number
}

export interface ModelProfile {
  id: string
  name: string
  providerID: string
  baseURL: string
  model: string
  temperature: number
  maxTokens: number
}

export interface ProviderPreset {
  id: string
  name: string
  baseURL: string
  defaultModel: string
  isOpenAICompatible: boolean
}

export interface Conversation {
  promptModeID: string
  messages: ChatMessage[]
}

export interface Settings {
  language: AppLanguage
  defaultTemperature: number
  defaultContextTurns: number
  maxTokens: number
  defaultModelProfileID: string
  defaultPromptModeID: string
}

export interface APIKeyEntry {
  profileID: string
  apiKey: string
}
