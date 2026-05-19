import type { ChatMessage, ModelProfile, PromptMode, Settings } from '../models/types'
import { normalizeRequest } from './request'
import { getModePrompt } from '../i18n'

export type StreamingErrorType = 'network' | 'http' | 'cors' | 'nokey' | 'config' | 'abort'

export class StreamingError extends Error {
  readonly type: StreamingErrorType
  readonly status?: number
  constructor(message: string, type: StreamingErrorType, status?: number) {
    super(message)
    this.type = type
    this.status = status
  }
}

export interface StreamCallbacks {
  onToken: (token: string) => void
  onDone: () => void
  onError: (error: StreamingError) => void
}

export function composeMessages(
  mode: PromptMode,
  history: ChatMessage[],
  userInput: string,
  settings: Settings,
): ChatMessage[] {
  const systemPrompt = getModePrompt(mode, settings.language)
  const contextTurns = mode.contextTurns ?? settings.defaultContextTurns

  // Take last N pairs (user + assistant) from history, excluding system messages
  const nonSystem = history.filter((m) => m.role !== 'system')
  const recent = nonSystem.slice(-contextTurns * 2)

  const messages: ChatMessage[] = [
    { id: 'system', role: 'system', content: systemPrompt },
    ...recent,
    { id: crypto.randomUUID(), role: 'user', content: userInput },
  ]

  return messages
}

export async function streamChat(
  profile: ModelProfile,
  apiKey: string | undefined,
  messages: ChatMessage[],
  callbacks: StreamCallbacks,
  signal?: AbortSignal,
): Promise<void> {
  if (!apiKey) {
    callbacks.onError(new StreamingError('No API key', 'nokey'))
    return
  }

  const normalized = normalizeRequest(profile)

  try {
    const response = await fetch(normalized.endpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model: normalized.model,
        messages: messages.map((m) => ({ role: m.role, content: m.content })),
        temperature: normalized.temperature,
        max_tokens: normalized.maxTokens,
        stream: true,
      }),
      signal,
    })

    if (!response.ok) {
      const status = response.status
      let type: StreamingError['type'] = 'http'
      if (status === 0 || (status >= 400 && status < 500 && response.type === 'opaque')) {
        type = 'cors'
      }
      callbacks.onError(new StreamingError(`HTTP ${status}`, type, status))
      return
    }

    const reader = response.body?.getReader()
    if (!reader) {
      callbacks.onError(new StreamingError('No response body', 'network'))
      return
    }

    const decoder = new TextDecoder()
    let buffer = ''

    while (true) {
      const { done, value } = await reader.read()
      if (done) break

      buffer += decoder.decode(value, { stream: true })
      const lines = buffer.split('\n')
      buffer = lines.pop() ?? ''

      for (const line of lines) {
        const trimmed = line.trim()
        if (!trimmed || trimmed === 'data: [DONE]') continue
        if (!trimmed.startsWith('data: ')) continue

        try {
          const json = JSON.parse(trimmed.slice(6))
          const token = json.choices?.[0]?.delta?.content
          if (token) callbacks.onToken(token)
        } catch {
          // Skip malformed chunks
        }
      }
    }

    callbacks.onDone()
  } catch (err) {
    if (signal?.aborted) {
      callbacks.onError(new StreamingError('Aborted', 'abort'))
      return
    }
    if (err instanceof TypeError) {
      callbacks.onError(new StreamingError('Network error', 'cors'))
      return
    }
    callbacks.onError(new StreamingError(String(err), 'network'))
  }
}
