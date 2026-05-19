import SwiftUI

struct AssistantView: View {
    @ObservedObject var viewModel: ChatViewModel
    let onOpenSettings: () -> Void
    let onDismiss: () -> Void

    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            modePicker
            Divider()
            transcript
            Divider()
            composer
        }
        .frame(minWidth: 680, minHeight: 560)
        .background(Color(nsColor: .windowBackgroundColor))
        .onChange(of: viewModel.inputFocusToken) { _ in
            isInputFocused = true
        }
        .onAppear {
            isInputFocused = true
        }
        .onExitCommand {
            onDismiss()
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
            Text("AskNow")
                .font(.headline)
            Spacer()
            Button {
                viewModel.togglePanelPinned()
            } label: {
                Image(systemName: viewModel.isPanelPinned ? "pin.fill" : "pin")
            }
            .buttonStyle(.borderless)
            .help(viewModel.isPanelPinned ? AppText.unpinWindow : AppText.pinWindow)

            Button {
                onOpenSettings()
            } label: {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.borderless)
            .help(AppText.settings)

            Button {
                viewModel.clear()
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .help(AppText.clearSession)

        }
        .padding(.leading, 76)
        .padding(.trailing, 16)
        .padding(.vertical, 12)
    }

    private var modePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.promptModes) { mode in
                    Button {
                        viewModel.selectedPromptModeID = mode.id
                    } label: {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color(hex: mode.colorHex))
                                .frame(width: 8, height: 8)
                            Text(mode.localizedName)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(viewModel.selectedPromptModeID == mode.id ? Color(hex: mode.colorHex).opacity(0.18) : Color(nsColor: .controlBackgroundColor))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
        }
    }

    private var transcript: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    if viewModel.messages.isEmpty {
                        emptyState
                    } else {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(
                                message: message,
                                onCopy: { viewModel.copyMessage(id: message.id) },
                                onDelete: { viewModel.deleteMessage(id: message.id) },
                                onRegenerate: {
                                    if message.role == .assistant {
                                        viewModel.regenerate(messageID: message.id)
                                    }
                                }
                            )
                                .id(message.id)
                        }
                    }

                    if let errorMessage = viewModel.errorMessage {
                        errorView(errorMessage)
                    }
                }
                .padding(16)
            }
            .onChange(of: viewModel.messages) { messages in
                if let last = messages.last {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(AppText.ready)
                .font(.title3.weight(.semibold))
            Text(AppText.emptyHint)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 24)
    }

    private func errorView(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(message)
                .foregroundStyle(.red)
            Button(AppText.retry) {
                viewModel.retry()
            }
        }
        .padding(12)
        .background(Color.red.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var composer: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField(AppText.typePlaceholder, text: $viewModel.input, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...6)
                .focused($isInputFocused)
                .onSubmit {
                    viewModel.submit()
                }
                .padding(10)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Button {
                if viewModel.isStreaming {
                    viewModel.cancelStreaming()
                } else {
                    viewModel.submit()
                }
            } label: {
                if viewModel.isStreaming {
                    Image(systemName: "stop.circle.fill")
                        .font(.title2)
                } else {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                }
            }
            .buttonStyle(.borderless)
            .disabled(!viewModel.isStreaming && viewModel.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .help(viewModel.isStreaming ? AppText.stop : AppText.send)
        }
        .padding(14)
    }
}

private struct MessageBubble: View {
    let message: ChatMessage
    let onCopy: () -> Void
    let onDelete: () -> Void
    let onRegenerate: () -> Void

    @State private var isHovering = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 6) {
                Text(message.role == .user ? AppText.you : "AskNow")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                MarkdownMessageText(content: message.content)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.trailing, 82)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 4) {
                if message.role == .assistant {
                    Button {
                        onRegenerate()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.borderless)
                    .help(AppText.regenerate)
                }

                Button {
                    onCopy()
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.borderless)
                .help(AppText.copy)

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .help(AppText.delete)
            }
            .opacity(isHovering ? 1 : 0)
            .allowsHitTesting(isHovering)
        }
        .padding(12)
        .background(message.role == .user ? Color.accentColor.opacity(0.12) : Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onHover { isHovering = $0 }
    }
}

private struct MarkdownMessageText: View {
    let content: String

    var body: some View {
        if content.isEmpty {
            Text(AppText.thinking)
        } else {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(parseSegments(content)) { segment in
                    switch segment.kind {
                    case .text:
                        Text(markdownText(segment.content))
                    case .math:
                        ScrollView(.horizontal, showsIndicators: false) {
                            Text(displayMath(segment.content))
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 5)
                                .background(Color(nsColor: .textBackgroundColor).opacity(0.9))
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                        }
                    case .code:
                        CodeBlockView(code: segment.content, language: segment.language)
                    }
                }
            }
        }
    }

    private func markdownText(_ value: String) -> AttributedString {
        do {
            return try AttributedString(
                markdown: value,
                options: AttributedString.MarkdownParsingOptions(
                    interpretedSyntax: .full
                )
            )
        } catch {
            return AttributedString(value)
        }
    }

    private func parseSegments(_ value: String) -> [MarkdownSegment] {
        var segments: [MarkdownSegment] = []
        var textBuffer = ""
        var index = value.startIndex

        func flushText() {
            guard !textBuffer.isEmpty else { return }
            segments.append(MarkdownSegment(kind: .text, content: textBuffer))
            textBuffer = ""
        }

        while index < value.endIndex {
            if let codeBlock = codeBlockSegment(in: value, from: index) {
                flushText()
                segments.append(MarkdownSegment(kind: .code, content: codeBlock.content, language: codeBlock.language))
                index = codeBlock.endIndex
                continue
            }

            if let match = mathRange(in: value, from: index, opening: "$$", closing: "$$") {
                flushText()
                segments.append(MarkdownSegment(kind: .math, content: String(value[match])))
                index = match.upperBound
                continue
            }

            if let match = mathRange(in: value, from: index, opening: "\\[", closing: "\\]") {
                flushText()
                segments.append(MarkdownSegment(kind: .math, content: String(value[match])))
                index = match.upperBound
                continue
            }

            if let match = mathRange(in: value, from: index, opening: "\\(", closing: "\\)") {
                flushText()
                segments.append(MarkdownSegment(kind: .math, content: String(value[match])))
                index = match.upperBound
                continue
            }

            if value[index] == "$",
               let end = value[value.index(after: index)...].firstIndex(of: "$") {
                flushText()
                segments.append(MarkdownSegment(kind: .math, content: String(value[index...end])))
                index = value.index(after: end)
                continue
            }

            if let match = bracketMathRange(in: value, from: index) {
                flushText()
                segments.append(MarkdownSegment(kind: .math, content: String(value[match])))
                index = match.upperBound
                continue
            }

            let lineEnd = value[index...].firstIndex(of: "\n") ?? value.endIndex
            let line = String(value[index..<lineEnd])
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if isBracketMath(trimmed) {
                flushText()
                segments.append(MarkdownSegment(kind: .math, content: trimmed))
                index = lineEnd == value.endIndex ? lineEnd : value.index(after: lineEnd)
                continue
            }

            textBuffer.append(value[index])
            index = value.index(after: index)
        }

        flushText()
        return segments.isEmpty ? [MarkdownSegment(kind: .text, content: value)] : segments
    }

    private func mathRange(in value: String, from index: String.Index, opening: String, closing: String) -> Range<String.Index>? {
        guard value[index...].hasPrefix(opening) else { return nil }

        let contentStart = value.index(index, offsetBy: opening.count)
        guard let closingRange = value[contentStart...].range(of: closing) else { return nil }

        return index..<closingRange.upperBound
    }

    private func bracketMathRange(in value: String, from index: String.Index) -> Range<String.Index>? {
        guard value[index] == "[" else { return nil }

        let contentStart = value.index(after: index)
        guard let closing = value[contentStart...].firstIndex(of: "]") else { return nil }
        let afterClosing = value.index(after: closing)
        if afterClosing < value.endIndex, value[afterClosing] == "(" {
            return nil
        }

        let candidate = String(value[index...closing])
        return isBracketMath(candidate) ? index..<afterClosing : nil
    }

    private func displayMath(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let source: String

        if trimmed.hasPrefix("$$"), trimmed.hasSuffix("$$"), trimmed.count >= 4 {
            source = String(trimmed.dropFirst(2).dropLast(2))
            return prettifyMathSource(source)
        }

        if trimmed.hasPrefix("$"), trimmed.hasSuffix("$"), trimmed.count >= 2 {
            source = String(trimmed.dropFirst().dropLast())
            return prettifyMathSource(source)
        }

        if trimmed.hasPrefix("\\["), trimmed.hasSuffix("\\]"), trimmed.count >= 4 {
            source = String(trimmed.dropFirst(2).dropLast(2))
            return prettifyMathSource(source)
        }

        if trimmed.hasPrefix("\\("), trimmed.hasSuffix("\\)"), trimmed.count >= 4 {
            source = String(trimmed.dropFirst(2).dropLast(2))
            return prettifyMathSource(source)
        }

        if isBracketMath(trimmed) {
            source = String(trimmed.dropFirst().dropLast())
            return prettifyMathSource(source)
        }

        return prettifyMathSource(trimmed)
    }

    private func prettifyMathSource(_ value: String) -> String {
        var result = replaceFractions(in: value)
        result = replaceTextCommands(in: result)

        let replacements: [(String, String)] = [
            ("\\cdot", "·"),
            ("\\times", "×"),
            ("\\div", "÷"),
            ("\\pm", "±"),
            ("\\leq", "≤"),
            ("\\geq", "≥"),
            ("\\neq", "≠"),
            ("\\approx", "≈"),
            ("\\to", "→"),
            ("\\rightarrow", "→"),
            ("\\left", ""),
            ("\\right", ""),
            ("\\,", " "),
            ("\\;", " "),
            ("\\:", " "),
            ("\\ ", " "),
            ("\\neg", "¬")
        ]

        for (target, replacement) in replacements {
            result = result.replacingOccurrences(of: target, with: replacement)
        }

        return result
            .replacingOccurrences(of: #" {2,}"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func replaceFractions(in value: String) -> String {
        var result = value

        while let range = result.range(of: "\\frac{") {
            let numeratorStart = range.upperBound
            guard let numeratorRange = bracedContentRange(in: result, openingBrace: result.index(before: numeratorStart)) else { break }

            let afterNumerator = result.index(after: numeratorRange.upperBound)
            guard afterNumerator < result.endIndex,
                  result[afterNumerator] == "{",
                  let denominatorRange = bracedContentRange(in: result, openingBrace: afterNumerator) else {
                break
            }

            let fullRange = range.lowerBound..<result.index(after: denominatorRange.upperBound)
            let numerator = String(result[numeratorRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            let denominator = String(result[denominatorRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            result.replaceSubrange(fullRange, with: "(\(numerator)) / (\(denominator))")
        }

        return result
    }

    private func replaceTextCommands(in value: String) -> String {
        var result = value

        while let range = result.range(of: "\\text{") {
            let contentStart = range.upperBound
            guard let contentRange = bracedContentRange(in: result, openingBrace: result.index(before: contentStart)) else { break }

            let replacement = String(result[contentRange])
            result.replaceSubrange(range.lowerBound..<result.index(after: contentRange.upperBound), with: replacement)
        }

        return result
    }

    private func bracedContentRange(in value: String, openingBrace: String.Index) -> Range<String.Index>? {
        guard openingBrace < value.endIndex, value[openingBrace] == "{" else { return nil }

        var depth = 0
        var index = openingBrace
        let contentStart = value.index(after: openingBrace)

        while index < value.endIndex {
            if value[index] == "{" {
                depth += 1
            } else if value[index] == "}" {
                depth -= 1
                if depth == 0 {
                    return contentStart..<index
                }
            }

            index = value.index(after: index)
        }

        return nil
    }

    private func codeBlockSegment(in value: String, from index: String.Index) -> (content: String, language: String?, endIndex: String.Index)? {
        guard value[index...].hasPrefix("```") else { return nil }

        let infoStart = value.index(index, offsetBy: 3)
        guard let openingLineEnd = value[infoStart...].firstIndex(of: "\n") else {
            return (content: "", language: codeLanguage(String(value[infoStart...])), endIndex: value.endIndex)
        }

        let language = codeLanguage(String(value[infoStart..<openingLineEnd]))
        let codeStart = value.index(after: openingLineEnd)

        guard let closingRange = value[codeStart...].range(of: "\n```") else {
            return (content: String(value[codeStart...]), language: language, endIndex: value.endIndex)
        }

        let closingTicksStart = value.index(after: closingRange.lowerBound)
        let afterClosingTicks = value.index(closingTicksStart, offsetBy: 3)
        let closingLineEnd = value[afterClosingTicks...].firstIndex(of: "\n")
        let endIndex = closingLineEnd.map { value.index(after: $0) } ?? value.endIndex

        return (content: String(value[codeStart..<closingRange.lowerBound]), language: language, endIndex: endIndex)
    }

    private func codeLanguage(_ value: String) -> String? {
        let language = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return language.isEmpty ? nil : language
    }

    private func isBracketMath(_ value: String) -> Bool {
        guard value.hasPrefix("["), value.hasSuffix("]"), !value.contains("](") else {
            return false
        }

        let inner = value.dropFirst().dropLast()
        return inner.contains("\\") || inner.contains("=") || inner.contains("^") || inner.contains("_") || inner.contains("{")
    }
}

private struct CodeBlockView: View {
    let code: String
    let language: String?

    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Text(language?.isEmpty == false ? language! : "text")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(code, forType: .string)
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                        copied = false
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        Text(AppText.copy)
                    }
                    .font(.caption)
                    .frame(width: 54, alignment: .trailing)
                }
                .buttonStyle(.borderless)
                .help(AppText.copy)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.65))

            ScrollView(.horizontal, showsIndicators: false) {
                Text(highlightedCode)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(8)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .textBackgroundColor).opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var highlightedCode: AttributedString {
        var highlighted = AttributedString(code)
        guard shouldHighlight(language) else { return highlighted }

        apply(pattern: #"(?m)(//.*$|#.*$)"#, color: .secondary, to: &highlighted)
        apply(pattern: #""(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'"#, color: .green, to: &highlighted)
        apply(pattern: #"\b\d+(?:\.\d+)?\b"#, color: .blue, to: &highlighted)
        apply(pattern: keywordPattern(for: language), color: .purple, to: &highlighted)

        return highlighted
    }

    private func shouldHighlight(_ language: String?) -> Bool {
        guard let language = language?.lowercased() else { return true }
        return ["swift", "js", "jsx", "javascript", "ts", "tsx", "typescript", "python", "py", "bash", "sh", "zsh", "json", "css", "html", "xml", "md", "markdown", "sql", "yaml", "yml"].contains(language)
    }

    private func keywordPattern(for language: String?) -> String {
        let common = ["return", "if", "else", "for", "while", "switch", "case", "break", "continue", "try", "catch", "throw", "throws", "async", "await", "true", "false", "nil", "null"]
        let extra: [String]

        switch language?.lowercased() {
        case "swift":
            extra = ["let", "var", "func", "struct", "class", "enum", "protocol", "extension", "import", "private", "public", "internal", "guard", "defer", "in", "self"]
        case "python", "py":
            extra = ["def", "class", "import", "from", "as", "with", "lambda", "None", "True", "False", "elif", "except", "finally", "yield"]
        case "bash", "sh", "zsh":
            extra = ["do", "done", "then", "fi", "case", "esac", "function", "export", "local"]
        case "sql":
            extra = ["select", "from", "where", "join", "left", "right", "inner", "outer", "group", "order", "by", "insert", "update", "delete", "create", "table", "values"]
        default:
            extra = ["const", "let", "var", "function", "class", "interface", "type", "import", "export", "extends", "implements", "new", "this", "typeof"]
        }

        return "\\b(" + (common + extra).joined(separator: "|") + ")\\b"
    }

    private func apply(pattern: String, color: Color, to attributed: inout AttributedString) {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return }
        let fullRange = NSRange(code.startIndex..<code.endIndex, in: code)
        let matches = regex.matches(in: code, range: fullRange)

        for match in matches {
            guard let range = Range(match.range, in: code),
                  let attributedRange = Range(range, in: attributed) else {
                continue
            }

            attributed[attributedRange].foregroundColor = color
        }
    }
}

private struct MarkdownSegment: Identifiable {
    enum Kind {
        case text
        case math
        case code
    }

    let id = UUID()
    let kind: Kind
    let content: String
    let language: String?

    init(kind: Kind, content: String, language: String? = nil) {
        self.kind = kind
        self.content = content
        self.language = language
    }
}
