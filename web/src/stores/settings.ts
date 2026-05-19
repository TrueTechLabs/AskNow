import { create } from 'zustand'
import type { Settings, AppLanguage, PromptMode, ModelProfile, APIKeyEntry } from '../models/types'
import { DEFAULT_SETTINGS, BUILT_IN_PROMPT_MODES, DEFAULT_MODEL_PROFILE } from '../models/defaults'
import { db } from '../lib/db'

interface AppState {
  // Settings
  settings: Settings
  promptModes: PromptMode[]
  modelProfiles: ModelProfile[]
  apiKeys: APIKeyEntry[]
  activePromptModeID: string

  // Conversations
  conversations: Record<string, import('../models/types').ChatMessage[]>

  // UI
  hydrated: boolean
  settingsOpen: boolean

  // Actions
  hydrate: () => Promise<void>
  setSettings: (patch: Partial<Settings>) => void
  setLanguage: (lang: AppLanguage) => void
  setActivePromptMode: (id: string) => void
  addPromptMode: (mode: PromptMode) => void
  updatePromptMode: (id: string, patch: Partial<PromptMode>) => void
  deletePromptMode: (id: string) => void
  addModelProfile: (profile: ModelProfile) => void
  updateModelProfile: (id: string, patch: Partial<ModelProfile>) => void
  deleteModelProfile: (id: string) => void
  setAPIKey: (profileID: string, key: string) => void
  getAPIKey: (profileID: string) => string | undefined
  getConversation: (modeID: string) => import('../models/types').ChatMessage[]
  addMessage: (modeID: string, message: import('../models/types').ChatMessage) => void
  updateMessage: (modeID: string, id: string, content: string) => void
  removeMessage: (modeID: string, id: string) => void
  clearConversation: (modeID: string) => void
  setSettingsOpen: (open: boolean) => void
}

function persistSetting<K extends keyof Settings>(key: K, value: Settings[K]) {
  db.settings.put({ key, value: JSON.stringify(value) }).catch(() => {})
}

export const useAppStore = create<AppState>((set, get) => ({
  settings: { ...DEFAULT_SETTINGS },
  promptModes: BUILT_IN_PROMPT_MODES.map((m) => ({ ...m })),
  modelProfiles: [{ ...DEFAULT_MODEL_PROFILE }],
  apiKeys: [],
  activePromptModeID: 'ask',
  conversations: {},
  hydrated: false,
  settingsOpen: false,

  hydrate: async () => {
    try {
      const [settingsRows, modeRows, profileRows, keyRows] = await Promise.all([
        db.settings.toArray(),
        db.promptModes.toArray(),
        db.modelProfiles.toArray(),
        db.apiKeys.toArray(),
      ])

      const persisted: Partial<Settings> = {}
      for (const row of settingsRows) {
        try {
          persisted[row.key as keyof Settings] = JSON.parse(row.value)
        } catch { /* skip */ }
      }

      const settings: Settings = { ...DEFAULT_SETTINGS, ...persisted }

      const promptModes =
        modeRows.length > 0
          ? modeRows.map((r) => JSON.parse(r.data) as PromptMode)
          : BUILT_IN_PROMPT_MODES.map((m) => ({ ...m }))

      const modelProfiles =
        profileRows.length > 0
          ? profileRows.map((r) => JSON.parse(r.data) as ModelProfile)
          : [{ ...DEFAULT_MODEL_PROFILE }]

      const apiKeys = keyRows.map((r) => ({ profileID: r.profileID, apiKey: r.apiKey }))

      // Load conversations
      const convRows = await db.conversations.toArray()
      const conversations: Record<string, import('../models/types').ChatMessage[]> = {}
      for (const row of convRows) {
        try {
          conversations[row.promptModeID] = JSON.parse(row.messages)
        } catch { /* skip */ }
      }

      set({
        settings,
        promptModes,
        modelProfiles,
        apiKeys,
        activePromptModeID: settings.defaultPromptModeID,
        conversations,
        hydrated: true,
      })
    } catch {
      // If DB fails, keep defaults
      set({ hydrated: true })
    }
  },

  setSettings: (patch) => {
    const settings = { ...get().settings, ...patch }
    for (const [k, v] of Object.entries(patch)) {
      persistSetting(k as keyof Settings, v as Settings[keyof Settings])
    }
    set({ settings })
  },

  setLanguage: (lang) => {
    get().setSettings({ language: lang })
  },

  setActivePromptMode: (id) => set({ activePromptModeID: id }),

  addPromptMode: (mode) => {
    const modes = [...get().promptModes, mode]
    db.promptModes.put({ id: mode.id, data: JSON.stringify(mode) }).catch(() => {})
    set({ promptModes: modes })
  },

  updatePromptMode: (id, patch) => {
    const modes = get().promptModes.map((m) => (m.id === id ? { ...m, ...patch } : m))
    const updated = modes.find((m) => m.id === id)
    if (updated) db.promptModes.put({ id, data: JSON.stringify(updated) }).catch(() => {})
    set({ promptModes: modes })
  },

  deletePromptMode: (id) => {
    const builtInIDs = ['ask', 'translate', 'summarize', 'polish']
    if (builtInIDs.includes(id)) return
    const modes = get().promptModes.filter((m) => m.id !== id)
    db.promptModes.delete(id).catch(() => {})
    db.conversations.delete(id).catch(() => {})
    const convs = { ...get().conversations }
    delete convs[id]
    if (get().activePromptModeID === id) {
      set({ promptModes: modes, activePromptModeID: 'ask', conversations: convs })
    } else {
      set({ promptModes: modes, conversations: convs })
    }
  },

  addModelProfile: (profile) => {
    const profiles = [...get().modelProfiles, profile]
    db.modelProfiles.put({ id: profile.id, data: JSON.stringify(profile) }).catch(() => {})
    set({ modelProfiles: profiles })
  },

  updateModelProfile: (id, patch) => {
    const profiles = get().modelProfiles.map((p) => (p.id === id ? { ...p, ...patch } : p))
    const updated = profiles.find((p) => p.id === id)
    if (updated) db.modelProfiles.put({ id, data: JSON.stringify(updated) }).catch(() => {})
    set({ modelProfiles: profiles })
  },

  deleteModelProfile: (id) => {
    if (id === 'default') return
    const profiles = get().modelProfiles.filter((p) => p.id !== id)
    db.modelProfiles.delete(id).catch(() => {})
    db.apiKeys.delete(id).catch(() => {})
    set({ modelProfiles: profiles })
  },

  setAPIKey: (profileID, key) => {
    const apiKeys = [...get().apiKeys.filter((k) => k.profileID !== profileID), { profileID, apiKey: key }]
    db.apiKeys.put({ profileID, apiKey: key }).catch(() => {})
    set({ apiKeys })
  },

  getAPIKey: (profileID) => get().apiKeys.find((k) => k.profileID === profileID)?.apiKey,

  getConversation: (modeID) => get().conversations[modeID] ?? [],

  addMessage: (modeID, message) => {
    const conversations = { ...get().conversations }
    const msgs = [...(conversations[modeID] ?? []), message]
    conversations[modeID] = msgs
    db.conversations.put({ promptModeID: modeID, messages: JSON.stringify(msgs) }).catch(() => {})
    set({ conversations })
  },

  updateMessage: (modeID, id, content) => {
    const conversations = { ...get().conversations }
    const msgs = (conversations[modeID] ?? []).map((m) =>
      m.id === id ? { ...m, content } : m,
    )
    conversations[modeID] = msgs
    db.conversations.put({ promptModeID: modeID, messages: JSON.stringify(msgs) }).catch(() => {})
    set({ conversations })
  },

  removeMessage: (modeID, id) => {
    const conversations = { ...get().conversations }
    const msgs = (conversations[modeID] ?? []).filter((m) => m.id !== id)
    conversations[modeID] = msgs
    db.conversations.put({ promptModeID: modeID, messages: JSON.stringify(msgs) }).catch(() => {})
    set({ conversations })
  },

  clearConversation: (modeID) => {
    const conversations = { ...get().conversations }
    conversations[modeID] = []
    db.conversations.put({ promptModeID: modeID, messages: '[]' }).catch(() => {})
    set({ conversations })
  },

  setSettingsOpen: (open) => set({ settingsOpen: open }),
}))
