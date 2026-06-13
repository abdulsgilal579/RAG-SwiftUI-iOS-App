import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var rag: RAGService
    @State private var apiKey = ""
    @State private var isKeyVisible = false
    @State private var showSaved = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("GROQ API Key", systemImage: "key.fill")
                            .font(.subheadline.bold())
                        HStack {
                            if isKeyVisible {
                                TextField("gsk_…", text: $apiKey)
                                    .autocorrectionDisabled()
                                    .fontDesign(.monospaced)
                                    .keyboardAPIStyle()
                            } else {
                                SecureField("gsk_…", text: $apiKey)
                                    .fontDesign(.monospaced)
                            }
                            Button {
                                isKeyVisible.toggle()
                            } label: {
                                Image(systemName: isKeyVisible ? "eye.slash" : "eye")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Button("Save Key") {
                            rag.setAPIKey(apiKey)
                            showSaved = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                showSaved = false
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(apiKey.trimmingCharacters(in: .whitespaces).isEmpty)
                        if showSaved {
                            Label("Saved!", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("API Configuration")
                } footer: {
                    Text("Get your free API key at console.groq.com")
                }

                Section("Model") {
                    Picker("LLM Model", selection: Binding(
                        get: { rag.groqModel },
                        set: { rag.setModel($0) }
                    )) {
                        ForEach(RAGService.availableModels, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("How it works") {
                    InfoRow(icon: "1.circle.fill", color: .blue,
                            title: "Add Documents",
                            detail: "Paste any text — articles, notes, manuals")
                    InfoRow(icon: "2.circle.fill", color: .purple,
                            title: "Local Embedding",
                            detail: "Text is chunked and embedded on-device using Apple NL framework")
                    InfoRow(icon: "3.circle.fill", color: .orange,
                            title: "Semantic Search",
                            detail: "Your query finds the most relevant chunks via cosine similarity")
                    InfoRow(icon: "4.circle.fill", color: .green,
                            title: "GROQ Generation",
                            detail: "Retrieved chunks + your question are sent to GROQ LLM for a grounded answer")
                }

                Section("About") {
                    LabeledContent("Embeddings", value: "Apple NLEmbedding (on-device)")
                    LabeledContent("Vector Store", value: "Local JSON (Documents dir)")
                    LabeledContent("Generation", value: "GROQ API")
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                Task {
                    apiKey = await rag.getAPIKey()
                }
            }
        }
    }
}

private extension View {
    @ViewBuilder func keyboardAPIStyle() -> some View {
#if os(iOS)
        self.textInputAutocapitalization(.never)
#else
        self
#endif
    }
}

struct InfoRow: View {
    let icon: String
    let color: Color
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.bold())
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
