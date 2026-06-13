import Foundation
import SwiftUI
import Combine

@MainActor
class RAGService: ObservableObject {
    @Published var documents: [Document] = []
    @Published var chunkCount: Int = 0
    @Published var isIndexing = false
    @Published var groqModel: String = "llama-3.3-70b-versatile"

    let vectorStore: VectorStore
    let groqService: GroqService
    let embeddingService: EmbeddingService

    static let availableModels = [
        "llama-3.3-70b-versatile",
        "llama-3.1-8b-instant",
        "mixtral-8x7b-32768",
        "gemma2-9b-it"
    ]

    init() {
        let es = EmbeddingService()
        self.embeddingService = es
        self.vectorStore = VectorStore(embeddingService: es)
        self.groqService = GroqService()

        // Key priority: Keychain (user-entered) → Secrets.swift (dev hardcoded)
        let keychainKey = KeychainService.load(for: "groq_api_key") ?? ""
        let activeKey = keychainKey.isEmpty ? Secrets.groqAPIKey : keychainKey
        if !activeKey.isEmpty {
            Task { await groqService.setAPIKey(activeKey) }
        }

        if let savedModel = UserDefaults.standard.string(forKey: "groq_model") {
            groqModel = savedModel
        }

        Task { await refreshState() }
    }

    func setAPIKey(_ key: String) {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            KeychainService.delete(for: "groq_api_key")
        } else {
            KeychainService.save(trimmed, for: "groq_api_key")
        }
        Task { await groqService.setAPIKey(trimmed) }
    }

    func setModel(_ model: String) {
        groqModel = model
        UserDefaults.standard.set(model, forKey: "groq_model")
    }

    func getAPIKey() async -> String {
        // Return Keychain key if set; otherwise show nothing (Secrets.swift is intentionally hidden)
        KeychainService.load(for: "groq_api_key") ?? ""
    }

    func addDocument(name: String, content: String) async {
        isIndexing = true
        defer { isIndexing = false }
        let doc = Document(name: name, content: content)
        await vectorStore.addDocument(doc)
        await refreshState()
    }

    func removeDocument(id: UUID) async {
        await vectorStore.removeDocument(id: id)
        await refreshState()
    }

    func query(_ question: String) async throws -> (answer: String, sources: [DocumentChunk]) {
        let results = await vectorStore.search(query: question, topK: 3)
        let sources = results.map(\.chunk)

        let contextText: String
        if results.isEmpty {
            contextText = "No documents have been indexed yet."
        } else {
            contextText = results.enumerated().map { i, r in
                "[\(i + 1)] Source: \"\(r.chunk.sourceDocumentName)\"\n\(r.chunk.text)"
            }.joined(separator: "\n\n---\n\n")
        }

        let system = """
        You are a helpful AI assistant that answers questions based on provided context documents.
        Use only the information from the context to answer. If the context doesn't contain the answer, say so clearly.
        Be concise and accurate. Cite source names when relevant.

        CONTEXT:
        \(contextText)
        """

        let answer = try await groqService.complete(system: system, user: question, model: groqModel)
        return (answer, sources)
    }

    private func refreshState() async {
        documents = await vectorStore.allDocuments()
        chunkCount = await vectorStore.chunkCount()
    }
}
