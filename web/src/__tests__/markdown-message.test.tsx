import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { describe, expect, it, vi } from 'vitest'
import { MarkdownMessage } from '../components/MarkdownMessage'
import { copyRawMessageContent } from '../lib/clipboard'

describe('MarkdownMessage', () => {
  it('renders common Markdown structures', () => {
    const { container } = render(
      <MarkdownMessage content={'# Title\n\n- **Bold** item\n\n`inline`\n\n```ts\nconst ok = true\n```'} />,
    )

    expect(screen.getByRole('heading', { name: 'Title' })).toBeTruthy()
    expect(screen.getByText('Bold')).toBeTruthy()
    expect(container.querySelector('ul')).toBeTruthy()
    expect(container.querySelector('.asknow-code-block code')?.textContent).toContain('const ok = true')
    expect(container.querySelector('p code')?.textContent).toBe('inline')
  })

  it('renders fenced code as a copyable highlighted code panel', async () => {
    const writeText = vi.fn().mockResolvedValue(undefined)
    Object.assign(navigator, {
      clipboard: { writeText },
    })

    const { container } = render(
      <MarkdownMessage content={'```ts\nconst ok = true\n```'} />,
    )

    expect(screen.getByText('ts')).toBeTruthy()
    expect(container.querySelector('.asknow-code-block .hljs-keyword')).toBeTruthy()

    fireEvent.click(screen.getByRole('button', { name: /copy/i }))

    await waitFor(() => {
      expect(writeText).toHaveBeenCalledWith('const ok = true')
    })
  })

  it('does not render math inside fenced code blocks', () => {
    const { container } = render(
      <MarkdownMessage content={'```ts\nconst formula = "$P(A|B)$"\n```'} />,
    )

    expect(container.querySelector('.asknow-code-block code')?.textContent).toContain('$P(A|B)$')
    expect(container.querySelector('.katex')).toBeNull()
  })

  it('skips raw HTML instead of exposing executable DOM', () => {
    const { container } = render(
      <MarkdownMessage content={'Hello <script>window.bad = true</script><img src=x onerror=alert(1)> **safe**'} />,
    )

    expect(container.querySelector('script')).toBeNull()
    expect(container.querySelector('img')).toBeNull()
    expect(screen.getByText('safe')).toBeTruthy()
  })

  it('wraps tables for compact transcript overflow', () => {
    const { container } = render(
      <MarkdownMessage content={'| A | B |\n| - | - |\n| 1 | 2 |'} />,
    )

    expect(container.querySelector('.asknow-markdown-table-wrap table')).toBeTruthy()
  })

  it('renders inline math with KaTeX', () => {
    const { container } = render(
      <MarkdownMessage content={'Bayes: $P(A|B)=\\frac{P(B|A)P(A)}{P(B)}$'} />,
    )

    expect(container.querySelector('.katex')).toBeTruthy()
    expect(container.querySelector('.katex-display')).toBeNull()
  })

  it('renders display math with KaTeX', () => {
    const { container } = render(
      <MarkdownMessage content={'$$P(A|B)=\\frac{P(B|A)P(A)}{P(B)}$$'} />,
    )

    expect(container.querySelector('.katex-display .katex')).toBeTruthy()
  })

  it('treats standalone bracketed formulas as display math', () => {
    const { container } = render(
      <MarkdownMessage content={'[ P(A|B) = \\frac{P(B|A) \\cdot P(A)}{P(B)} ]'} />,
    )

    expect(container.querySelector('.katex-display .katex')).toBeTruthy()
  })

  it('renders escaped LaTeX display delimiters from model output', () => {
    const { container } = render(
      <MarkdownMessage content={'公式：\\[\nP(A|B) = \\frac{P(B|A) \\cdot P(A)}{P(B)}\n\\]'} />,
    )

    expect(container.querySelector('.katex-display .katex')).toBeTruthy()
    expect(container.textContent).not.toContain('\\[')
  })

  it('renders prefixed escaped display math as a KaTeX block', () => {
    const { container } = render(
      <MarkdownMessage content={'基本形式：\\[ P(A|B) = \\frac{P(B|A) \\cdot P(A)}{P(B)} \\]'} />,
    )

    expect(container.textContent).toContain('基本形式')
    expect(container.querySelector('.katex-display .katex')).toBeTruthy()
    expect(container.textContent).not.toContain('\\[')
  })

  it('renders prefixed bracket formulas as KaTeX blocks', () => {
    const { container } = render(
      <MarkdownMessage content={'基本形式：[ P(A|B) = \\frac{P(B|A) \\cdot P(A)}{P(B)} ]'} />,
    )

    expect(container.textContent).toContain('基本形式')
    expect(container.querySelector('.katex-display .katex')).toBeTruthy()
  })

  it('renders escaped LaTeX inline delimiters from model output', () => {
    const { container } = render(
      <MarkdownMessage content={'其中 \\(P(A|B)\\) 是后验概率。'} />,
    )

    expect(container.querySelector('.katex')).toBeTruthy()
    expect(container.querySelector('.katex-display')).toBeNull()
    expect(container.textContent).not.toContain('\\(')
  })

  it('does not treat Markdown links as bracketed math', () => {
    const { container } = render(
      <MarkdownMessage content={'Read [Bayes theorem](https://example.com) before $P(A|B)$.'} />,
    )

    const link = screen.getByRole('link', { name: 'Bayes theorem' })
    expect(link.getAttribute('href')).toBe('https://example.com')
    expect(container.querySelector('.katex')).toBeTruthy()
  })
})

describe('copyRawMessageContent', () => {
  it('copies the raw Markdown source', async () => {
    const writeText = vi.fn().mockResolvedValue(undefined)
    Object.assign(navigator, {
      clipboard: { writeText },
    })

    await copyRawMessageContent('**raw** `markdown`')

    expect(writeText).toHaveBeenCalledWith('**raw** `markdown`')
  })
})
