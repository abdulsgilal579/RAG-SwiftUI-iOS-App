import SwiftUI

struct ChatView: View {
    @EnvironmentObject var rag: RAGService
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var inputFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if messages.isEmpty {
                    emptyState
                } else {
                    messageList
                }
                inputBar
            }
            .navigationTitle("RAG Chat")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    if !messages.isEmpty {
                        Button("Clear") { messages = [] }
                            .foregroundStyle(.red)
                    }
                }
            }
            .alert("Error", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("Ask anything")
                .font(.title2.bold())
            Text(rag.documents.isEmpty
                 ? "Add documents in the Documents tab first"
                 : "Questions will be answered using your \(rag.documents.count) document(s)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(messages) { msg in
                        MessageBubble(message: msg)
                            .id(msg.id)
                    }
                    if isLoading {
                        TypingIndicator()
                            .id("typing")
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .onChange(of: messages.count) {
                withAnimation {
                    if let last = messages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: isLoading) {
                if isLoading {
                    withAnimation { proxy.scrollTo("typing", anchor: .bottom) }
                }
            }
        }
    }

    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 10) {
                TextField("Ask a question…", text: $inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...4)
                    .focused($inputFocused)
                    .submitLabel(.send)
                    .onSubmit { sendMessage() }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.cellBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(canSend ? .blue : .secondary)
                }
                .disabled(!canSend)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
        .background(.regularMaterial)
    }

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isLoading else { return }

        inputText = ""
        inputFocused = false
        messages.append(ChatMessage(role: .user, content: text))
        isLoading = true

        Task {
            do {
                let (answer, sources) = try await rag.query(text)
                messages.append(ChatMessage(role: .assistant, content: answer, sources: sources))
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    @State private var showSources = false

    var isUser: Bool { message.role == .user }

    var body: some View {
        VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
            HStack {
                if isUser { Spacer(minLength: 60) }
                Text(message.content)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(isUser ? Color.blue : Color.cellBackground)
                    .foregroundStyle(isUser ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                if !isUser { Spacer(minLength: 60) }
            }

            if !isUser && !message.sources.isEmpty {
                Button {
                    withAnimation(.spring(duration: 0.3)) { showSources.toggle() }
                } label: {
                    Label("\(message.sources.count) source\(message.sources.count == 1 ? "" : "s")",
                          systemImage: showSources ? "chevron.up" : "doc.text")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if showSources {
                    ForEach(message.sources) { chunk in
                        SourceCard(chunk: chunk)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
    }
}

struct SourceCard: View {
    let chunk: DocumentChunk

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(chunk.sourceDocumentName, systemImage: "doc.fill")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            Text(chunk.text.prefix(200) + (chunk.text.count > 200 ? "…" : ""))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct TypingIndicator: View {
    @State private var animating = false

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3) { i in
                Circle()
                    .frame(width: 8, height: 8)
                    .foregroundStyle(.secondary)
                    .offset(y: animating ? -4 : 0)
                    .animation(
                        .easeInOut(duration: 0.5).repeatForever(autoreverses: true).delay(Double(i) * 0.15),
                        value: animating
                    )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.cellBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .onAppear { animating = true }
    }
}
