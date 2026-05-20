import { lazy, Suspense, useCallback, useRef, useState } from 'react'
import { useAppStore } from '../stores/settings'
import { t, getModeName, getPlaceholder } from '../i18n'
import { streamChat, composeMessages, StreamingError } from '../lib/streaming'
import { copyRawMessageContent } from '../lib/clipboard'
import type { ChatMessage } from '../models/types'
import { Copy, Trash2, RefreshCw, Settings, X, Send, Maximize2, Minimize2, Moon, Sun } from 'lucide-react'
import { MarkdownMessage } from './MarkdownMessage'

const SettingsPanel = lazy(() => import('./Settings'))

export default function App() {
  const {
    settings, promptModes, modelProfiles, hydrated,
    activePromptModeID, setActivePromptMode,
    getConversation, addMessage, updateMessage, removeMessage, clearConversation,
    getAPIKey, setSettingsOpen, settingsOpen, setSettings,
  } = useAppStore()

  const [input, setInput] = useState('')
  const [streaming, setStreaming] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [expanded, setExpanded] = useState(false)
  const abortRef = useRef<AbortController | null>(null)

  const lang = settings.language
  const activeMode = promptModes.find((m) => m.id === activePromptModeID) ?? promptModes[0]
  const messages = getConversation(activePromptModeID)

  const send = useCallback(async () => {
    const text = input.trim()
    if (!text || streaming) return

    const profileID = activeMode.modelProfileID ?? settings.defaultModelProfileID
    const profile = modelProfiles.find((p) => p.id === profileID)
    if (!profile) {
      setError(t('errorInvalidConfig', lang))
      return
    }
    const apiKey = getAPIKey(profileID)
    if (!apiKey) {
      setError(t('errorNoAPIKey', lang))
      return
    }

    setError(null)
    setStreaming(true)

    const userMsg: ChatMessage = { id: crypto.randomUUID(), role: 'user', content: text }
    addMessage(activePromptModeID, userMsg)
    setInput('')

    const assistantMsg: ChatMessage = { id: crypto.randomUUID(), role: 'assistant', content: '', sourceUserMessageID: userMsg.id }
    addMessage(activePromptModeID, assistantMsg)

    const abort = new AbortController()
    abortRef.current = abort

    const composed = composeMessages(activeMode, getConversation(activePromptModeID).slice(0, -1), text, settings)

    await streamChat(profile, apiKey, composed, {
      onToken: (token) => {
        const msgs = getConversation(activePromptModeID)
        const current = msgs.find((m) => m.id === assistantMsg.id)
        if (current) updateMessage(activePromptModeID, assistantMsg.id, current.content + token)
      },
      onDone: () => setStreaming(false),
      onError: (err: StreamingError) => {
        if (err.type !== 'abort') {
          let msg = err.message
          if (err.type === 'network') msg = t('errorNetwork', lang)
          else if (err.type === 'cors') msg = t('errorCORS', lang)
          else if (err.type === 'nokey') msg = t('errorNoAPIKey', lang)
          else if (err.type === 'http') msg = t('errorHTTP', lang).replace('{status}', String(err.status))
          setError(msg)
        }
        setStreaming(false)
      },
    }, abort.signal)
  }, [input, streaming, activeMode, settings, modelProfiles, activePromptModeID, addMessage, updateMessage, getConversation, getAPIKey, lang])

  const cancel = useCallback(() => {
    abortRef.current?.abort()
    setStreaming(false)
  }, [])

  const regenerate = useCallback(
    (msg: ChatMessage) => {
      const msgs = getConversation(activePromptModeID)
      const userIdx = msgs.findIndex((m) => m.id === msg.sourceUserMessageID)
      if (userIdx < 0) return
      const userMsg = msgs[userIdx]
      removeMessage(activePromptModeID, msg.id)
      setInput(userMsg.content)
      setTimeout(() => {
        const store = useAppStore.getState()
        const mode = store.promptModes.find((m) => m.id === activePromptModeID) ?? store.promptModes[0]
        const profileID = mode.modelProfileID ?? store.settings.defaultModelProfileID
        const profile = store.modelProfiles.find((p) => p.id === profileID)
        if (!profile) return
        const apiKey = store.getAPIKey(profileID)
        if (!apiKey) return

        const assistantMsg: ChatMessage = { id: crypto.randomUUID(), role: 'assistant', content: '', sourceUserMessageID: userMsg.id }
        store.addMessage(activePromptModeID, assistantMsg)

        const abort = new AbortController()
        const composed = composeMessages(mode, store.getConversation(activePromptModeID).slice(0, -1), userMsg.content, store.settings)
        streamChat(profile, apiKey, composed, {
          onToken: (token) => {
            const msgs = store.getConversation(activePromptModeID)
            const current = msgs.find((m) => m.id === assistantMsg.id)
            if (current) store.updateMessage(activePromptModeID, assistantMsg.id, current.content + token)
          },
          onDone: () => {},
          onError: () => {},
        }, abort.signal)
      }, 0)
    },
    [activePromptModeID, getConversation, removeMessage],
  )

  const copyMessage = useCallback(async (content: string) => {
    await copyRawMessageContent(content)
  }, [])

  const handleClear = useCallback(() => {
    cancel()
    clearConversation(activePromptModeID)
  }, [activePromptModeID, cancel, clearConversation])

  const modeColor = activeMode.colorHex
  const expandLabel = expanded ? t('restoreWindow', lang) : t('maximizeWindow', lang)
  const isDark = settings.theme === 'dark'
  const themeLabel = isDark ? t('switchToLight', lang) : t('switchToDark', lang)

  return (
    <div className={`asknow-app asknow-theme-${settings.theme}`}>
      <div className={`asknow-shell${expanded ? ' asknow-shell-expanded' : ''}`}>
      {/* Header */}
      <header className="asknow-header">
        <div className="flex items-center gap-2">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke={modeColor} strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
            <path d="M12 2L2 7l10 5 10-5-10-5z" />
            <path d="M2 17l10 5 10-5" />
            <path d="M2 12l10 5 10-5" />
          </svg>
          <span className="asknow-title">AskNow</span>
        </div>
        <div className="flex items-center gap-1">
          <button
            onClick={() => setSettings({ theme: isDark ? 'light' : 'dark' })}
            className="asknow-icon-btn"
            title={themeLabel}
            aria-label={themeLabel}
          >
            {isDark ? <Sun size={15} /> : <Moon size={15} />}
          </button>
          <button onClick={handleClear} className="asknow-icon-btn" title={t('clear', lang)}>
            <Trash2 size={15} />
          </button>
          <button onClick={() => setSettingsOpen(true)} className="asknow-icon-btn" title={t('settings', lang)}>
            <Settings size={15} />
          </button>
          <button
            onClick={() => setExpanded((value) => !value)}
            className="asknow-icon-btn"
            title={expandLabel}
            aria-label={expandLabel}
          >
            {expanded ? <Minimize2 size={15} /> : <Maximize2 size={15} />}
          </button>
        </div>
      </header>

      {/* Mode Selector */}
      <div className="asknow-modes scrollbar-none">
        {promptModes.map((mode) => (
          <button
            key={mode.id}
            onClick={() => setActivePromptMode(mode.id)}
            className="asknow-mode-btn"
            style={{
              backgroundColor: mode.id === activePromptModeID ? mode.colorHex + '2e' : 'transparent',
              color: mode.id === activePromptModeID ? mode.colorHex : 'var(--asknow-text-subtle)',
              borderColor: mode.id === activePromptModeID ? mode.colorHex : 'transparent',
            }}
          >
            <span
              className="asknow-mode-dot"
              style={{ backgroundColor: mode.colorHex }}
            />
            {getModeName(mode, lang)}
          </button>
        ))}
      </div>

      {/* Transcript */}
      <div className="asknow-transcript">
        {messages.length === 0 && !streaming && (
          <div className="asknow-empty">
            {t('emptyHint', lang)}
          </div>
        )}
        {messages
          .filter((m) => m.role !== 'system')
          .map((msg) => (
            <div key={msg.id} className={`asknow-msg ${msg.role === 'user' ? 'asknow-msg-user' : 'asknow-msg-assistant'}`}>
              <div
                className={`asknow-bubble ${
                  msg.role === 'user'
                    ? 'asknow-bubble-user'
                    : 'asknow-bubble-assistant'
                }`}
              >
                {msg.content ? (
                  <MarkdownMessage content={msg.content} />
                ) : (
                  streaming ? '' : '\u00A0'
                )}
                {streaming && msg.role === 'assistant' && !msg.content && (
                  <span className="asknow-cursor" />
                )}
              </div>
              <div className="asknow-msg-actions">
                <button onClick={() => copyMessage(msg.content)} className="asknow-action-btn" title={t('copy', lang)}>
                  <Copy size={12} />
                </button>
                <button onClick={() => removeMessage(activePromptModeID, msg.id)} className="asknow-action-btn" title={t('delete', lang)}>
                  <Trash2 size={12} />
                </button>
                {msg.role === 'assistant' && msg.sourceUserMessageID && (
                  <button onClick={() => regenerate(msg)} className="asknow-action-btn" title={t('regenerate', lang)}>
                    <RefreshCw size={12} />
                  </button>
                )}
              </div>
            </div>
          ))}
        {streaming && messages.filter((m) => m.role === 'assistant').at(-1)?.content && (
          <span className="asknow-cursor ml-1" />
        )}
      </div>

      {/* Error */}
      {error && (
        <div className="asknow-error">
          <span>{error}</span>
          <button onClick={() => setError(null)} className="asknow-action-btn"><X size={11} /></button>
        </div>
      )}

      {/* Composer */}
      <div className="asknow-composer">
        <form
          onSubmit={(e) => { e.preventDefault(); send() }}
          className="flex items-end gap-2"
        >
          <textarea
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); send() }
            }}
            placeholder={getPlaceholder(activePromptModeID, lang)}
            rows={1}
            className="asknow-input"
            onInput={(e) => {
              const el = e.currentTarget
              el.style.height = 'auto'
              el.style.height = Math.min(el.scrollHeight, 100) + 'px'
            }}
            disabled={!hydrated}
          />
          {streaming ? (
            <button type="button" onClick={cancel} className="asknow-cancel-btn">
              <X size={14} />
            </button>
          ) : (
            <button
              type="submit"
              disabled={!input.trim() || !hydrated}
              className="asknow-send-btn"
              style={{ backgroundColor: modeColor }}
            >
              <Send size={14} color="#fff" />
            </button>
          )}
        </form>
      </div>

      {/* Settings (lazy loaded) */}
      {settingsOpen && (
        <Suspense fallback={null}>
          <SettingsPanel onClose={() => setSettingsOpen(false)} />
        </Suspense>
      )}
      </div>
    </div>
  )
}
