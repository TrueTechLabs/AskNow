import { useState } from 'react'
import ReactMarkdown from 'react-markdown'
import remarkGfm from 'remark-gfm'
import remarkMath from 'remark-math'
import rehypeKatex from 'rehype-katex'
import hljs from 'highlight.js/lib/core'
import bash from 'highlight.js/lib/languages/bash'
import css from 'highlight.js/lib/languages/css'
import javascript from 'highlight.js/lib/languages/javascript'
import json from 'highlight.js/lib/languages/json'
import markdown from 'highlight.js/lib/languages/markdown'
import python from 'highlight.js/lib/languages/python'
import sql from 'highlight.js/lib/languages/sql'
import swift from 'highlight.js/lib/languages/swift'
import typescript from 'highlight.js/lib/languages/typescript'
import xml from 'highlight.js/lib/languages/xml'
import yaml from 'highlight.js/lib/languages/yaml'
import type { Components } from 'react-markdown'
import { Copy } from 'lucide-react'
import { copyRawMessageContent } from '../lib/clipboard'
import 'katex/dist/katex.min.css'

hljs.registerLanguage('bash', bash)
hljs.registerLanguage('css', css)
hljs.registerLanguage('javascript', javascript)
hljs.registerLanguage('json', json)
hljs.registerLanguage('markdown', markdown)
hljs.registerLanguage('python', python)
hljs.registerLanguage('sql', sql)
hljs.registerLanguage('swift', swift)
hljs.registerLanguage('typescript', typescript)
hljs.registerLanguage('xml', xml)
hljs.registerLanguage('yaml', yaml)
hljs.registerAliases(['sh', 'shell', 'zsh'], { languageName: 'bash' })
hljs.registerAliases(['js', 'jsx'], { languageName: 'javascript' })
hljs.registerAliases(['ts', 'tsx'], { languageName: 'typescript' })
hljs.registerAliases(['html', 'svg'], { languageName: 'xml' })
hljs.registerAliases(['md'], { languageName: 'markdown' })
hljs.registerAliases(['yml'], { languageName: 'yaml' })

const markdownComponents: Components = {
  a: ({ children, ...props }) => (
    <a {...props} target="_blank" rel="noreferrer">
      {children}
    </a>
  ),
  table: ({ children }) => (
    <div className="asknow-markdown-table-wrap">
      <table>{children}</table>
    </div>
  ),
  code: ({ children, className, ...props }) => {
    const text = String(children)
    const isInline = !className && !text.includes('\n')

    if (isInline) {
      return <code {...props}>{children}</code>
    }

    return <CodeBlock code={text.replace(/\n$/, '')} language={languageFromClassName(className)} />
  },
}

interface MarkdownMessageProps {
  content: string
}

const bracketMathPattern = /^\[\s*((?=.*(?:\\[a-zA-Z]+|[=^_{}]|[A-Za-z]\([^)]*\))).+?)\s*\]$/
const embeddedBracketMathPattern = /(^|[^\]])\[\s*((?=.*(?:\\[a-zA-Z]+|[=^_{}]|[A-Za-z]\([^)]*\))).+?)\s*\](?!\()/g
const singleLineDisplayMathPattern = /^\$\$(.+)\$\$$/
const escapedDisplayMathPattern = /\\\[\s*([\s\S]*?)\s*\\\]/g

function languageFromClassName(className?: string) {
  return className?.match(/language-([\w-]+)/)?.[1]?.toLowerCase()
}

function highlightedCode(code: string, language?: string) {
  if (!language || !hljs.getLanguage(language)) return undefined
  return hljs.highlight(code, { language, ignoreIllegals: true }).value
}

interface CodeBlockProps {
  code: string
  language?: string
}

function CodeBlock({ code, language }: CodeBlockProps) {
  const [copied, setCopied] = useState(false)
  const highlighted = highlightedCode(code, language)

  const copyCode = async () => {
    await copyRawMessageContent(code)
    setCopied(true)
    window.setTimeout(() => setCopied(false), 1100)
  }

  return (
    <div className="asknow-code-block">
      <div className="asknow-code-header">
        <span>{language || 'text'}</span>
        <button type="button" className="asknow-code-copy" onClick={copyCode} title="Copy code">
          <Copy size={12} />
          <span>{copied ? 'Copied' : 'Copy'}</span>
        </button>
      </div>
      <pre>
        {highlighted ? (
          <code
            className={language ? `language-${language} hljs` : 'hljs'}
            dangerouslySetInnerHTML={{ __html: highlighted }}
          />
        ) : (
          <code>{code}</code>
        )}
      </pre>
    </div>
  )
}

function normalizeMathSource(content: string) {
  const fenceChunks = content.split(/(```[\s\S]*?```)/g)

  return fenceChunks
    .map((chunk) => {
      if (chunk.startsWith('```')) return chunk

      return normalizeMathText(chunk)
    })
    .join('')
}

function normalizeMathText(content: string) {
  return content
    .replace(/\\\(([\s\S]*?)\\\)/g, (_, formula: string) => `$${formula}$`)
    .replace(escapedDisplayMathPattern, (_, formula: string) => `\n\n$$\n${formula.trim()}\n$$\n\n`)
    .split('\n')
    .map((line) => {
      const trimmed = line.trim()
      if (!trimmed || trimmed.includes('](')) return line

      const displayMatch = trimmed.match(singleLineDisplayMathPattern)
      if (displayMatch) {
        const leadingWhitespace = line.match(/^\s*/)?.[0] ?? ''
        return `${leadingWhitespace}$$\n${displayMatch[1]}\n${leadingWhitespace}$$`
      }

      const match = trimmed.match(bracketMathPattern)
      if (!match) {
        return line.replace(embeddedBracketMathPattern, (_, prefix: string, formula: string) => (
          `${prefix}\n\n$$\n${formula.trim()}\n$$\n`
        ))
      }

      const leadingWhitespace = line.match(/^\s*/)?.[0] ?? ''
      return `${leadingWhitespace}$$\n${match[1]}\n${leadingWhitespace}$$`
    })
    .join('\n')
}

export function MarkdownMessage({ content }: MarkdownMessageProps) {
  return (
    <ReactMarkdown
      remarkPlugins={[remarkGfm, remarkMath]}
      rehypePlugins={[rehypeKatex]}
      components={markdownComponents}
      skipHtml
    >
      {normalizeMathSource(content)}
    </ReactMarkdown>
  )
}
