import { useState } from 'react'
import { useAppStore } from '../stores/settings'
import { isChinese, t, getModeName } from '../i18n'
import { PROVIDER_PRESETS, getProviderPreset } from '../models/providers'
import { MAX_TOKEN_PRESETS, BUILT_IN_PROMPT_MODES, DEFAULT_MODEL_PROFILE } from '../models/defaults'
import type { PromptMode, ModelProfile } from '../models/types'
import { X, Plus, Trash2 } from 'lucide-react'

interface Props {
  onClose: () => void
}

export default function SettingsPanel({ onClose }: Props) {
  const { settings } = useAppStore()

  const lang = settings.language
  const zh = isChinese(lang)
  const [tab, setTab] = useState<'general' | 'profiles' | 'modes'>('general')

  return (
    <div className="fixed inset-0 z-50 bg-black/30 flex items-center justify-center p-4">
      <div className="bg-white rounded-xl w-full max-w-md max-h-[85vh] flex flex-col overflow-hidden shadow-xl">
        {/* Header */}
        <div className="flex items-center justify-between px-4 py-2.5 border-b border-gray-100">
          <h2 className="text-sm font-semibold text-gray-900">{t('settings', lang)}</h2>
          <button onClick={onClose} className="p-1 rounded-md hover:bg-gray-100 text-gray-400">
            <X size={14} />
          </button>
        </div>

        {/* Tabs */}
        <div className="flex gap-1 px-4 py-1.5 border-b border-gray-50">
          {(['general', 'profiles', 'modes'] as const).map((key) => (
            <button
              key={key}
              onClick={() => setTab(key)}
              className={`px-3 py-1 rounded-md text-xs font-medium transition-colors ${
                tab === key ? 'bg-gray-100 text-gray-900' : 'text-gray-400 hover:text-gray-600'
              }`}
            >
              {key === 'general' ? (zh ? '通用' : 'General')
                : key === 'profiles' ? t('modelProfiles', lang)
                : t('promptModes', lang)}
            </button>
          ))}
        </div>

        {/* Content */}
        <div className="flex-1 overflow-y-auto p-4 space-y-3">
          {tab === 'general' && <GeneralTab />}
          {tab === 'profiles' && <ProfilesTab />}
          {tab === 'modes' && <ModesTab />}
        </div>
      </div>
    </div>
  )
}

function GeneralTab() {
  const { settings, setLanguage } = useAppStore()
  const lang = settings.language

  return (
    <div className="space-y-3">
      <Field label={t('language', lang)}>
        <select
          value={settings.language}
          onChange={(e) => setLanguage(e.target.value as typeof settings.language)}
          className="input-field"
        >
          <option value="system">{t('systemLang', lang)}</option>
          <option value="chinese">{t('chinese', lang)}</option>
          <option value="english">{t('english', lang)}</option>
        </select>
      </Field>

      <Field label={t('temperature', lang)}>
        <input
          type="number"
          min={0}
          max={2}
          step={0.1}
          value={settings.defaultTemperature}
          onChange={(e) => useAppStore.getState().setSettings({ defaultTemperature: +e.target.value })}
          className="input-field"
        />
      </Field>

      <Field label={t('contextTurns', lang)}>
        <input
          type="number"
          min={0}
          max={50}
          value={settings.defaultContextTurns}
          onChange={(e) => useAppStore.getState().setSettings({ defaultContextTurns: +e.target.value })}
          className="input-field"
        />
      </Field>

      <Field label={t('maxTokens', lang)}>
        <select
          value={settings.maxTokens}
          onChange={(e) => useAppStore.getState().setSettings({ maxTokens: +e.target.value })}
          className="input-field"
        >
          {MAX_TOKEN_PRESETS.map((v) => (
            <option key={v} value={v}>{v.toLocaleString()}</option>
          ))}
        </select>
      </Field>
    </div>
  )
}

function ProfilesTab() {
  const { modelProfiles, settings } = useAppStore()
  const lang = settings.language
  const [selectedID, setSelectedID] = useState(modelProfiles[0]?.id ?? '')

  const selected = modelProfiles.find((p) => p.id === selectedID)
  const apiKey = selected ? useAppStore.getState().getAPIKey(selected.id) ?? '' : ''

  return (
    <div className="space-y-3">
      <div className="flex items-center justify-between">
        <span className="text-xs text-gray-500">{modelProfiles.length} {t('modelProfiles', lang).toLowerCase()}</span>
        <button
          onClick={() => {
            const id = crypto.randomUUID().slice(0, 8)
            const p: ModelProfile = { ...DEFAULT_MODEL_PROFILE, id, name: `Profile ${modelProfiles.length + 1}` }
            useAppStore.getState().addModelProfile(p)
            setSelectedID(id)
          }}
          className="flex items-center gap-1 px-2 py-0.5 rounded-md bg-gray-100 hover:bg-gray-200 text-xs text-gray-700"
        >
          <Plus size={11} /> {t('addProfile', lang)}
        </button>
      </div>

      <div className="flex gap-1 flex-wrap">
        {modelProfiles.map((p) => (
          <button
            key={p.id}
            onClick={() => setSelectedID(p.id)}
            className={`px-2 py-0.5 rounded-md text-xs ${p.id === selectedID ? 'bg-gray-200 text-gray-900' : 'bg-gray-50 text-gray-600 hover:bg-gray-100'}`}
          >
            {p.name}
          </button>
        ))}
      </div>

      {selected && (
        <ProfileEditor
          profile={selected}
          apiKey={apiKey}
          onProfileChange={(patch) => useAppStore.getState().updateModelProfile(selected.id, patch)}
          onAPIKeyChange={(key) => useAppStore.getState().setAPIKey(selected.id, key)}
          onDelete={() => {
            useAppStore.getState().deleteModelProfile(selected.id)
            setSelectedID(modelProfiles[0]?.id ?? '')
          }}
          canDelete={selected.id !== 'default'}
        />
      )}
    </div>
  )
}

function ProfileEditor({
  profile, apiKey, onProfileChange, onAPIKeyChange, onDelete, canDelete,
}: {
  profile: ModelProfile
  apiKey: string
  onProfileChange: (patch: Partial<ModelProfile>) => void
  onAPIKeyChange: (key: string) => void
  onDelete: () => void
  canDelete: boolean
}) {
  const { settings } = useAppStore()
  const lang = settings.language

  return (
    <div className="space-y-2.5 bg-gray-50 rounded-lg p-3">
      <Field label={t('name', lang)}>
        <input value={profile.name} onChange={(e) => onProfileChange({ name: e.target.value })} className="input-field" />
      </Field>

      <Field label={t('provider', lang)}>
        <select
          value={profile.providerID}
          onChange={(e) => {
            const p = getProviderPreset(e.target.value)
            onProfileChange({
              providerID: e.target.value,
              ...(p?.baseURL ? { baseURL: p.baseURL } : {}),
              ...(p?.defaultModel ? { model: p.defaultModel } : {}),
            })
          }}
          className="input-field"
        >
          {PROVIDER_PRESETS.map((p) => (
            <option key={p.id} value={p.id}>{p.name}</option>
          ))}
        </select>
      </Field>

      <Field label={t('baseURL', lang)}>
        <input value={profile.baseURL} onChange={(e) => onProfileChange({ baseURL: e.target.value })} className="input-field" />
      </Field>

      <Field label={t('modelName', lang)}>
        <input value={profile.model} onChange={(e) => onProfileChange({ model: e.target.value })} className="input-field" />
      </Field>

      <Field label={t('temperature', lang)}>
        <input type="number" min={0} max={2} step={0.1} value={profile.temperature} onChange={(e) => onProfileChange({ temperature: +e.target.value })} className="input-field" />
      </Field>

      <Field label={t('maxTokens', lang)}>
        <select value={profile.maxTokens} onChange={(e) => onProfileChange({ maxTokens: +e.target.value })} className="input-field">
          {MAX_TOKEN_PRESETS.map((v) => (
            <option key={v} value={v}>{v.toLocaleString()}</option>
          ))}
        </select>
      </Field>

      <Field label={t('apiKey', lang)}>
        <input
          type="password"
          value={apiKey}
          onChange={(e) => onAPIKeyChange(e.target.value)}
          className="input-field"
          placeholder="sk-..."
        />
      </Field>
      <p className="text-[10px] text-gray-400 -mt-1">{t('apiKeyNotice', lang)}</p>

      {canDelete && (
        <button
          onClick={onDelete}
          className="flex items-center gap-1 text-xs text-red-500 hover:text-red-600"
        >
          <Trash2 size={11} /> {t('deleteProfile', lang)}
        </button>
      )}
    </div>
  )
}

function ModesTab() {
  const { promptModes, settings } = useAppStore()
  const lang = settings.language
  const [selectedID, setSelectedID] = useState(promptModes[0]?.id ?? '')
  const builtInIDs = BUILT_IN_PROMPT_MODES.map((m) => m.id)
  const selected = promptModes.find((m) => m.id === selectedID)
  const isBuiltIn = builtInIDs.includes(selectedID)

  return (
    <div className="space-y-3">
      <div className="flex items-center justify-between">
        <span className="text-xs text-gray-500">{promptModes.length} {t('promptModes', lang).toLowerCase()}</span>
        <button
          onClick={() => {
            const id = crypto.randomUUID().slice(0, 8)
            const m: PromptMode = {
              id,
              nameEn: `Custom ${promptModes.length + 1}`,
              nameZh: `自定义 ${promptModes.length + 1}`,
              systemPromptEn: '',
              systemPromptZh: '',
              colorHex: '#5E6AD2',
            }
            useAppStore.getState().addPromptMode(m)
            setSelectedID(id)
          }}
          className="flex items-center gap-1 px-2 py-0.5 rounded-md bg-gray-100 hover:bg-gray-200 text-xs text-gray-700"
        >
          <Plus size={11} /> {t('addMode', lang)}
        </button>
      </div>

      <div className="flex gap-1 flex-wrap">
        {promptModes.map((m) => (
          <button
            key={m.id}
            onClick={() => setSelectedID(m.id)}
            className="px-2 py-0.5 rounded-full text-xs border"
            style={{
              backgroundColor: m.id === selectedID ? m.colorHex + '1a' : 'transparent',
              borderColor: m.id === selectedID ? m.colorHex : '#ddd',
              color: m.id === selectedID ? m.colorHex : '#999',
            }}
          >
            {getModeName(m, lang)}
          </button>
        ))}
      </div>

      {selected && (
        <ModeEditor
          mode={selected}
          isBuiltIn={isBuiltIn}
          onChange={(patch) => useAppStore.getState().updatePromptMode(selected.id, patch)}
          onDelete={() => {
            useAppStore.getState().deletePromptMode(selected.id)
            setSelectedID('ask')
          }}
        />
      )}
    </div>
  )
}

function ModeEditor({
  mode, isBuiltIn, onChange, onDelete,
}: {
  mode: PromptMode
  isBuiltIn: boolean
  onChange: (patch: Partial<PromptMode>) => void
  onDelete: () => void
}) {
  const { modelProfiles, settings } = useAppStore()
  const lang = settings.language
  const zh = isChinese(lang)

  return (
    <div className="space-y-2.5 bg-gray-50 rounded-lg p-3">
      {isBuiltIn && <p className="text-[10px] text-gray-400">{t('builtInMode', lang)}</p>}

      <Field label={zh ? '英文名称' : 'English Name'}>
        <input value={mode.nameEn} onChange={(e) => onChange({ nameEn: e.target.value })} className="input-field" disabled={isBuiltIn} />
      </Field>

      <Field label={zh ? '中文名称' : 'Chinese Name'}>
        <input value={mode.nameZh} onChange={(e) => onChange({ nameZh: e.target.value })} className="input-field" disabled={isBuiltIn} />
      </Field>

      <Field label={`${t('promptContent', lang)} (EN)`}>
        <textarea value={mode.systemPromptEn} onChange={(e) => onChange({ systemPromptEn: e.target.value })} className="input-field min-h-[50px] resize-y" disabled={isBuiltIn} />
      </Field>

      <Field label={`${t('promptContent', lang)} (中文)`}>
        <textarea value={mode.systemPromptZh} onChange={(e) => onChange({ systemPromptZh: e.target.value })} className="input-field min-h-[50px] resize-y" disabled={isBuiltIn} />
      </Field>

      <Field label={t('color', lang)}>
        <input type="color" value={mode.colorHex} onChange={(e) => onChange({ colorHex: e.target.value })} className="w-7 h-7 rounded border border-gray-200 cursor-pointer p-0" />
      </Field>

      <Field label={t('modelProfile', lang)}>
        <select
          value={mode.modelProfileID ?? ''}
          onChange={(e) => onChange({ modelProfileID: e.target.value || undefined })}
          className="input-field"
        >
          <option value="">{t('default', lang)}</option>
          {modelProfiles.map((p) => (
            <option key={p.id} value={p.id}>{p.name}</option>
          ))}
        </select>
      </Field>

      <Field label={t('temperature', lang)}>
        <input type="number" min={0} max={2} step={0.1} value={mode.temperature ?? ''} onChange={(e) => onChange({ temperature: e.target.value ? +e.target.value : undefined })} className="input-field" placeholder={t('default', lang)} />
      </Field>

      <Field label={t('contextTurns', lang)}>
        <input type="number" min={0} max={50} value={mode.contextTurns ?? ''} onChange={(e) => onChange({ contextTurns: e.target.value ? +e.target.value : undefined })} className="input-field" placeholder={t('default', lang)} />
      </Field>

      {!isBuiltIn && (
        <button onClick={onDelete} className="flex items-center gap-1 text-xs text-red-500 hover:text-red-600">
          <Trash2 size={11} /> {t('deleteMode', lang)}
        </button>
      )}
    </div>
  )
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <label className="block space-y-0.5">
      <span className="text-[11px] font-medium text-gray-500">{label}</span>
      {children}
    </label>
  )
}
