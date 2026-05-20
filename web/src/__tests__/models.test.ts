import { describe, it, expect } from 'vitest'
import { isChinese, getModeName, getPlaceholder } from '../i18n'
import { BUILT_IN_PROMPT_MODES, DEFAULT_SETTINGS, DEFAULT_MODEL_PROFILE, MAX_TOKEN_PRESETS } from '../models/defaults'
import { getProviderPreset, PROVIDER_PRESETS } from '../models/providers'
import { buildEndpointURL, normalizeRequest } from '../lib/request'
import type { ModelProfile } from '../models/types'

describe('i18n', () => {
  it('detects Chinese language', () => {
    expect(isChinese('chinese')).toBe(true)
  })

  it('detects English language', () => {
    expect(isChinese('english')).toBe(false)
  })

  it('built-in mode names localize', () => {
    const askMode = BUILT_IN_PROMPT_MODES[0]
    expect(getModeName(askMode, 'english')).toBe('Ask')
    expect(getModeName(askMode, 'chinese')).toBe('问答')
  })

  it('custom mode names stay unchanged', () => {
    const custom = { id: 'my-mode', nameEn: 'My Mode', nameZh: 'My Mode', systemPromptEn: '', systemPromptZh: '', colorHex: '#000' }
    expect(getModeName(custom, 'chinese')).toBe('My Mode')
    expect(getModeName(custom, 'english')).toBe('My Mode')
  })

  it('returns correct placeholder', () => {
    expect(getPlaceholder('translate', 'english')).toBe('Paste text to translate...')
    expect(getPlaceholder('ask', 'chinese')).toBeTruthy()
  })
})

describe('defaults', () => {
  it('has 4 built-in prompt modes', () => {
    expect(BUILT_IN_PROMPT_MODES).toHaveLength(4)
  })

  it('modes have correct IDs', () => {
    const ids = BUILT_IN_PROMPT_MODES.map((m) => m.id)
    expect(ids).toEqual(['ask', 'translate', 'summarize', 'polish'])
  })

  it('each mode has a color hex', () => {
    for (const mode of BUILT_IN_PROMPT_MODES) {
      expect(mode.colorHex).toMatch(/^#[0-9A-Fa-f]{6}$/)
    }
  })

  it('default settings are sensible', () => {
    expect(DEFAULT_SETTINGS.defaultTemperature).toBe(0.7)
    expect(DEFAULT_SETTINGS.defaultContextTurns).toBe(6)
    expect(DEFAULT_SETTINGS.maxTokens).toBe(8192)
    expect(DEFAULT_SETTINGS.defaultPromptModeID).toBe('ask')
  })

  it('default model profile is valid', () => {
    expect(DEFAULT_MODEL_PROFILE.id).toBe('default')
    expect(DEFAULT_MODEL_PROFILE.providerID).toBe('openai')
    expect(DEFAULT_MODEL_PROFILE.temperature).toBeGreaterThanOrEqual(0)
  })

  it('max token presets include common values', () => {
    expect(MAX_TOKEN_PRESETS).toContain(1024)
    expect(MAX_TOKEN_PRESETS).toContain(8192)
  })
})

describe('providers', () => {
  it('has all expected providers', () => {
    const ids = PROVIDER_PRESETS.map((p) => p.id)
    expect(ids).toContain('openai')
    expect(ids).toContain('anthropic')
    expect(ids).toContain('deepseek')
    expect(ids).toContain('ollama')
    expect(ids).toContain('openrouter')
    expect(ids).toContain('custom')
  })

  it('getProviderPreset returns correct preset', () => {
    const openai = getProviderPreset('openai')
    expect(openai?.baseURL).toBe('https://api.openai.com/v1')
    expect(openai?.isOpenAICompatible).toBe(true)
  })

  it('getProviderPreset returns undefined for unknown', () => {
    expect(getProviderPreset('nonexistent')).toBeUndefined()
  })
})

describe('request normalization', () => {
  it('builds endpoint URL with /chat/completions', () => {
    expect(buildEndpointURL('https://api.openai.com/v1')).toBe('https://api.openai.com/v1/chat/completions')
  })

  it('does not duplicate /chat/completions', () => {
    expect(buildEndpointURL('https://api.openai.com/v1/chat/completions')).toBe('https://api.openai.com/v1/chat/completions')
  })

  it('handles trailing slashes', () => {
    expect(buildEndpointURL('https://api.openai.com/v1/')).toBe('https://api.openai.com/v1/chat/completions')
  })

  it('normalizes standard profile', () => {
    const profile: ModelProfile = {
      id: 'test',
      name: 'Test',
      providerID: 'openai',
      baseURL: 'https://api.openai.com/v1',
      model: 'gpt-4o',
      temperature: 0.7,
      maxTokens: 8192,
    }
    const result = normalizeRequest(profile)
    expect(result.endpoint).toBe('https://api.openai.com/v1/chat/completions')
    expect(result.model).toBe('gpt-4o')
    expect(result.temperature).toBe(0.7)
    expect(result.maxTokens).toBe(8192)
  })

  it('clamps zhipu provider temperature', () => {
    const profile: ModelProfile = {
      id: 'zhipu-test',
      name: 'Zhipu Test',
      providerID: 'zhipu',
      baseURL: 'https://open.bigmodel.cn/api/paas/v4',
      model: 'glm-5.1',
      temperature: 1.5,
      maxTokens: 200000,
    }
    const result = normalizeRequest(profile)
    expect(result.temperature).toBe(1)
    expect(result.maxTokens).toBe(131072)
  })
})
