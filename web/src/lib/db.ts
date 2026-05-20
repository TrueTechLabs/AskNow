import Dexie, { type EntityTable } from 'dexie'

interface PersistedConversation {
  promptModeID: string
  messages: string // JSON
}

interface PersistedAPIKey {
  profileID: string
  apiKey: string
}

interface PersistedSetting {
  key: string
  value: string // JSON
}

const db = new Dexie('AskNowDB') as Dexie & {
  conversations: EntityTable<PersistedConversation, 'promptModeID'>
  apiKeys: EntityTable<PersistedAPIKey, 'profileID'>
  settings: EntityTable<PersistedSetting, 'key'>
  promptModes: EntityTable<{ id: string; data: string }, 'id'>
  modelProfiles: EntityTable<{ id: string; data: string }, 'id'>
}

db.version(1).stores({
  conversations: 'promptModeID',
  apiKeys: 'profileID',
  settings: 'key',
  promptModes: 'id',
  modelProfiles: 'id',
})

export { db }
export type { PersistedConversation, PersistedAPIKey, PersistedSetting }
