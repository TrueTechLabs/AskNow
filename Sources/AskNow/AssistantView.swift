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
        .frame(width: 680, height: 560)
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

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.borderless)
            .help(AppText.close)
        }
        .padding(.horizontal, 16)
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
                viewModel.submit()
            } label: {
                if viewModel.isStreaming {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                }
            }
            .buttonStyle(.borderless)
            .disabled(viewModel.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isStreaming)
            .help(AppText.send)
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

                Text(message.content.isEmpty ? AppText.thinking : message.content)
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
