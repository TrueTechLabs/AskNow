import type { AppLanguage } from '../models/types'

const zh: Record<string, string> = {
  settings: '设置',
  promptModes: '提示词模式',
  modelProfiles: '模型配置',
  provider: '供应商',
  language: '语言',
  apiKey: 'API 密钥',
  modelName: '模型名称',
  temperature: '温度',
  maxTokens: '最大 Token 数',
  contextTurns: '上下文轮数',
  defaultPromptMode: '默认提示词模式',
  defaultModelProfile: '默认模型配置',
  emptyHint: '输入问题、粘贴要翻译的内容，或切换上方模式。',
  send: '发送',
  clear: '清除',
  maximizeWindow: '放大',
  restoreWindow: '还原',
  copy: '复制',
  delete: '删除',
  regenerate: '重新生成',
  cancel: '取消',
  save: '保存',
  addMode: '添加模式',
  addProfile: '添加配置',
  deleteMode: '删除模式',
  deleteProfile: '删除配置',
  editMode: '编辑模式',
  editProfile: '编辑配置',
  promptContent: '提示词内容',
  color: '颜色',
  name: '名称',
  baseURL: 'Base URL',
  customProvider: '自定义供应商',
  apiKeyNotice: 'API 密钥仅存储在当前浏览器中，仅发送至您配置的供应商端点。',
  builtInMode: '内置模式',
  customMode: '自定义模式',
  protectBuiltIn: '内置模式不可删除',
  protectDefault: '默认配置不可删除',
  copiedToClipboard: '已复制到剪贴板',
  conversationCleared: '对话已清除',
  streaming: '回复中...',
  errorNetwork: '网络错误，请检查连接。',
  errorHTTP: '请求失败 (HTTP {status})',
  errorCORS: '跨域请求被拒绝，请使用支持 CORS 的供应商或本地代理。',
  errorNoAPIKey: '请先设置 API 密钥。',
  errorInvalidConfig: '配置无效，请检查模型设置。',
  errorRetry: '点击重试',
  default: '默认',
  systemLang: '跟随系统',
  chinese: '中文',
  english: 'English',
  askPlaceholder: '输入问题...',
  translatePlaceholder: '粘贴要翻译的内容...',
  summarizePlaceholder: '粘贴要总结的内容...',
  polishPlaceholder: '粘贴要润色的文字...',
}

const en: Record<string, string> = {
  settings: 'Settings',
  promptModes: 'Prompt Modes',
  modelProfiles: 'Model Profiles',
  provider: 'Provider',
  language: 'Language',
  apiKey: 'API Key',
  modelName: 'Model Name',
  temperature: 'Temperature',
  maxTokens: 'Max Tokens',
  contextTurns: 'Context Turns',
  defaultPromptMode: 'Default Prompt Mode',
  defaultModelProfile: 'Default Model Profile',
  emptyHint: 'Ask a question, paste text to translate, or switch modes above.',
  send: 'Send',
  clear: 'Clear',
  maximizeWindow: 'Maximize',
  restoreWindow: 'Restore',
  copy: 'Copy',
  delete: 'Delete',
  regenerate: 'Regenerate',
  cancel: 'Cancel',
  save: 'Save',
  addMode: 'Add Mode',
  addProfile: 'Add Profile',
  deleteMode: 'Delete Mode',
  deleteProfile: 'Delete Profile',
  editMode: 'Edit Mode',
  editProfile: 'Edit Profile',
  promptContent: 'Prompt Content',
  color: 'Color',
  name: 'Name',
  baseURL: 'Base URL',
  customProvider: 'Custom Provider',
  apiKeyNotice: 'Your API key is stored only in this browser and sent only to your configured provider endpoint.',
  builtInMode: 'Built-in Mode',
  customMode: 'Custom Mode',
  protectBuiltIn: 'Built-in modes cannot be deleted',
  protectDefault: 'Default profile cannot be deleted',
  copiedToClipboard: 'Copied to clipboard',
  conversationCleared: 'Conversation cleared',
  streaming: 'Streaming...',
  errorNetwork: 'Network error, please check your connection.',
  errorHTTP: 'Request failed (HTTP {status})',
  errorCORS: 'CORS request rejected. Use a CORS-enabled provider or a local proxy.',
  errorNoAPIKey: 'Please set an API key first.',
  errorInvalidConfig: 'Invalid configuration, please check model settings.',
  errorRetry: 'Click to retry',
  default: 'Default',
  systemLang: 'System',
  chinese: '中文',
  english: 'English',
  askPlaceholder: 'Type a question...',
  translatePlaceholder: 'Paste text to translate...',
  summarizePlaceholder: 'Paste text to summarize...',
  polishPlaceholder: 'Paste text to polish...',
}

export function isChinese(lang: AppLanguage): boolean {
  if (lang === 'chinese') return true
  if (lang === 'english') return false
  return navigator.language.toLowerCase().startsWith('zh')
}

export function t(key: string, lang: AppLanguage): string {
  const table = isChinese(lang) ? zh : en
  return table[key] ?? key
}

export function getModeName(
  mode: { nameEn: string; nameZh: string; id: string },
  lang: AppLanguage,
): string {
  // Built-in modes use localized names, custom modes keep user-entered names
  const builtInIDs = ['ask', 'translate', 'summarize', 'polish']
  if (!builtInIDs.includes(mode.id)) return mode.nameEn
  return isChinese(lang) ? mode.nameZh : mode.nameEn
}

export function getModePrompt(
  mode: { systemPromptEn: string; systemPromptZh: string },
  lang: AppLanguage,
): string {
  return isChinese(lang) ? mode.systemPromptZh : mode.systemPromptEn
}

export function getPlaceholder(modeID: string, lang: AppLanguage): string {
  const suffix: Record<string, string> = {
    ask: 'askPlaceholder',
    translate: 'translatePlaceholder',
    summarize: 'summarizePlaceholder',
    polish: 'polishPlaceholder',
  }
  return t(suffix[modeID] ?? 'askPlaceholder', lang)
}
