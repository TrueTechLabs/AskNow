
<h1 align="center">AskNow</h1>

<p align="center">
  <b>轻量、快速、原生的 macOS 菜单栏 AI 助手。</b><br>
  <b>A lightweight, fast, native AI assistant for your macOS menu bar.</b>
</p>

<p align="center">
  <img alt="macOS" src="https://img.shields.io/badge/macOS-14%2B-111827?style=for-the-badge&logo=apple&logoColor=white">
  <img alt="Swift" src="https://img.shields.io/badge/Swift-5.9-F05138?style=for-the-badge&logo=swift&logoColor=white">
  <img alt="Native" src="https://img.shields.io/badge/Native-AppKit%20%2B%20SwiftUI-2F80ED?style=for-the-badge">
  <img alt="No Electron" src="https://img.shields.io/badge/No-Electron-27AE60?style=for-the-badge">
</p>

<p align="center">
  <a href="#中文">中文</a>
  ·
  <a href="#english">English</a>
  ·
  <a href="#development">Development</a>
</p>

## 中文

AskNow 是一个放在 macOS 菜单栏里的 AI 助手。它不是一个新的工作台，也不想占满你的屏幕。你按下 <kbd>Option</kbd> + <kbd>Space</kbd>，它就在屏幕中央出现；问完、翻译完、总结完，就回到后台。



它适合那些每天都会发生的小任务：

- 快速问一个问题
- 翻译一段内容
- 总结剪贴板里的文本
- 润色一句话
- 解释一段代码或报错
- 用不同提示词模式处理重复工作

### 为什么做它

很多 AI 工具越来越重：浏览器标签、侧边栏、工作区、插件市场、复杂账号系统。AskNow 走另一条路：

- 原生 macOS 体验
- 打开速度快
- 占用空间小
- 不用切换到浏览器
- 不打断当前工作流
- 支持你自己的 API Key 和模型供应商

### 亮点

- 菜单栏常驻，点击图标即可打开
- 默认快捷键 <kbd>Option</kbd> + <kbd>Space</kbd>
- 居中浮窗，随用随走
- 系统语言自动切换中文 / 英文界面
- 多个提示词模式：问答、翻译、总结、润色、自定义
- 每个模式可以独立设置颜色、模型、温度、上下文轮次
- 不同模式的对话内容互相隔离
- 支持多个模型配置
- 内置主流 API 供应商，也支持自定义 OpenAI-compatible Base URL
- 原生 Swift / AppKit / SwiftUI 构建，不是 Electron



### 使用流程

1. 启动 AskNow 后，它会常驻在 macOS 菜单栏。
2. 点击菜单栏图标，或按 <kbd>Option</kbd> + <kbd>Space</kbd> 呼出居中窗口。
3. 在顶部切换问答、翻译、总结、润色或自定义模式。
4. 打开设置，选择语言、供应商、模型和提示词模式。
5. 输入问题或粘贴内容，获得回答后继续回到当前工作。

### 本地构建

构建应用：

```bash
Scripts/build_app.sh
```

启动应用：

```bash
open .build/AskNow.app
```

然后打开设置，选择供应商，填入 API Key 和模型名即可。

## English

AskNow is a tiny AI assistant that lives in your macOS menu bar. It is not another workspace, dashboard, or browser tab. Press <kbd>Option</kbd> + <kbd>Space</kbd>, ask something, translate a paragraph, summarize text, then get right back to what you were doing.


It is built for small, frequent AI tasks:

- Ask a quick question
- Translate pasted text
- Summarize a note
- Polish a sentence
- Explain code or errors
- Reuse custom prompt modes

### Why AskNow

Many AI apps are becoming heavier. AskNow stays small:

- Native macOS feel
- Fast launch
- Low footprint
- No browser switching
- No Electron runtime
- Bring your own API key and model provider

### Highlights

- Menu bar app with a centered assistant panel
- Global shortcut: <kbd>Option</kbd> + <kbd>Space</kbd>
- Automatic Chinese / English UI
- Prompt modes for Ask, Translate, Summarize, Polish, and custom workflows
- Per-mode model, color, temperature, and context settings
- Isolated conversations for each prompt mode
- Multiple model profiles
- Built-in popular provider presets
- Custom OpenAI-compatible Base URL support
- Built with Swift, AppKit, and SwiftUI

### Flow

1. Launch AskNow and keep it in the macOS menu bar.
2. Click the menu bar icon or press <kbd>Option</kbd> + <kbd>Space</kbd>.
3. Switch between Ask, Translate, Summarize, Polish, or custom modes.
4. Open Settings to choose language, provider, model, and prompt behavior.
5. Type or paste content, get the answer, then return to your flow.

## Development

Requirements:

- macOS 14+
- Xcode command line tools
- Swift 5.9+

Compile:

```bash
swift build
```

Create the app bundle:

```bash
Scripts/build_app.sh
```

Project structure:

```text
Sources/AskNow/
  AssistantView.swift            Main chat UI
  SettingsView.swift             Settings UI
  OpenAICompatibleProvider.swift Streaming chat client
  ProviderCatalog.swift          Built-in provider presets
  HotkeyManager.swift            Global shortcut
  Models.swift                   Settings and chat models
```

## Roadmap

- Signed release builds
- Import / export settings
- Optional secure key storage for release builds
- More native provider adapters
- Auto-update support

---

## Web Client

AskNow also provides a browser-based PWA client in the `web/` directory. It mirrors the macOS app's core experience: prompt modes, isolated conversations, OpenAI-compatible streaming, and responsive desktop/mobile layouts.

### Web Development

```bash
cd web
npm install
npm run dev        # Start dev server at http://localhost:5173
npm run build      # Production build to web/dist/
npm run preview    # Preview production build locally
```

### Static Deployment

The `web/dist/` directory is a fully static site. Deploy it to any static hosting service (Vercel, Netlify, Cloudflare Pages, GitHub Pages, S3, etc.):

```bash
cd web
npm run build
# Upload web/dist/ to your static host
```

No server-side runtime, API proxy, or build step is required on the host.

### Security Notes

- **API keys** are stored only in the current browser's IndexedDB. They are never uploaded to any AskNow server.
- API keys are sent directly from the browser to your configured provider endpoint.
- Some providers reject browser requests due to **CORS policies**. If you see a CORS error, use a CORS-enabled provider (e.g., OpenRouter, Together AI), a local proxy (e.g., Ollama, LiteLLM), or a provider that explicitly allows browser requests.
- For maximum security, use provider API keys with scoped permissions and rotate them regularly.

### Tech Stack

- React 19, TypeScript, Vite
- Tailwind CSS v4
- Zustand for state management
- Dexie / IndexedDB for browser persistence
- vite-plugin-pwa for service worker and installability
- Lucide React for icons

<p align="center">
  <b>Small window. Fast answers. Back to flow.</b><br>
  <b>小窗口，快回答，马上回到心流。</b>
</p>
