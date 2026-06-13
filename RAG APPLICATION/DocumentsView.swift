import SwiftUI

struct DocumentsView: View {
    @EnvironmentObject var rag: RAGService
    @State private var showAddSheet = false

    var body: some View {
        NavigationStack {
            Group {
                if rag.documents.isEmpty {
                    emptyState
                } else {
                    documentList
                }
            }
            .navigationTitle("Documents")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddDocumentSheet(isPresented: $showAddSheet)
            }
            .overlay {
                if rag.isIndexing {
                    indexingOverlay
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("No documents yet")
                .font(.title2.bold())
            Text("Tap + to add text documents.\nThey'll be chunked and embedded locally.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                showAddSheet = true
            } label: {
                Label("Add Document", systemImage: "plus")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private var documentList: some View {
        List {
            Section {
                HStack {
                    Label("\(rag.documents.count) document\(rag.documents.count == 1 ? "" : "s")", systemImage: "doc.fill")
                    Spacer()
                    Text("\(rag.chunkCount) chunks indexed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Documents") {
                ForEach(rag.documents) { doc in
                    DocumentRow(document: doc)
                }
                .onDelete { indexSet in
                    for i in indexSet {
                        let doc = rag.documents[i]
                        Task { await rag.removeDocument(id: doc.id) }
                    }
                }
            }
        }
    }

    private var indexingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3).ignoresSafeArea()
            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.5)
                Text("Indexing document…")
                    .font(.subheadline.bold())
            }
            .padding(24)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

struct DocumentRow: View {
    let document: Document

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(document.name)
                .font(.headline)
            HStack {
                Text("\(document.content.split(separator: " ").count) words")
                Text("·")
                Text(document.createdAt.formatted(date: .abbreviated, time: .omitted))
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

struct AddDocumentSheet: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var rag: RAGService

    @State private var name = ""
    @State private var content = ""

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Document Name") {
                    TextField("e.g. Company Overview", text: $name)
                }

                Section("Content") {
                    TextEditor(text: $content)
                        .frame(minHeight: 200)
                        .font(.body)
                }

                Section {
                    Button("Load Sample Document") {
                        loadSample()
                    }
                    .foregroundStyle(.blue)
                }
            }
            .navigationTitle("Add Document")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            await rag.addDocument(
                                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                                content: content.trimmingCharacters(in: .whitespacesAndNewlines)
                            )
                            isPresented = false
                        }
                    }
                    .bold()
                    .disabled(!canSave)
                }
            }
        }
    }

    private func loadSample() {
        name = "AI & Machine Learning Overview"
        content = """
        Artificial Intelligence (AI) is the simulation of human intelligence in machines that are programmed to think and learn. Machine learning is a subset of AI that enables systems to learn and improve from experience without being explicitly programmed.

        Deep learning is a type of machine learning that uses neural networks with many layers. These neural networks are inspired by the structure of the human brain. Convolutional Neural Networks (CNNs) are commonly used for image recognition tasks, while Recurrent Neural Networks (RNNs) and Transformers are used for natural language processing.

        Natural Language Processing (NLP) is the branch of AI that deals with the interaction between computers and human language. Large Language Models (LLMs) like GPT-4 and LLaMA are trained on vast amounts of text data and can generate human-like text, answer questions, summarize content, and perform many other language tasks.

        Retrieval-Augmented Generation (RAG) is a technique that combines information retrieval with language generation. In a RAG system, when a user asks a question, the system first searches a knowledge base for relevant documents, then passes those documents as context to an LLM to generate a grounded answer. This reduces hallucinations and keeps answers factual.

        Vector databases store data as high-dimensional vectors (embeddings) and enable fast similarity search. When text is embedded into a vector, semantically similar texts will have vectors that are close together in vector space. Cosine similarity is a common metric to measure how similar two vectors are.

        GROQ is an AI inference company that provides extremely fast LLM inference. Their Language Processing Unit (LPU) hardware achieves token generation speeds significantly faster than GPU-based solutions, making it ideal for real-time applications.
        """
    }
}
