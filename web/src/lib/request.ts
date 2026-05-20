import type { ModelProfile } from '../models/types'

export function buildEndpointURL(baseURL: string): string {
  const trimmed = baseURL.replace(/\/+$/, '')
  if (trimmed.endsWith('/chat/completions')) return trimmed
  if (trimmed.endsWith('/v1') || trimmed.endsWith('/v3') || trimmed.endsWith('/v4')) {
    return `${trimmed}/chat/completions`
  }
  return `${trimmed}/chat/completions`
}

export interface NormalizedRequest {
  endpoint: string
  model: string
  temperature: number
  maxTokens: number
}

export function normalizeRequest(profile: ModelProfile): NormalizedRequest {
  let temperature = profile.temperature
  let maxTokens = profile.maxTokens

  // Z.AI / BigModel specific limits
  if (profile.providerID === 'zhipu') {
    temperature = Math.min(Math.max(temperature, 0), 1)
    maxTokens = Math.min(maxTokens, 131072)
  }

  return {
    endpoint: buildEndpointURL(profile.baseURL),
    model: profile.model,
    temperature,
    maxTokens,
  }
}
