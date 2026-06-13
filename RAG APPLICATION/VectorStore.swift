import Foundation

actor VectorStore {
    private var documents: [Document] = []
    private var chunks: [DocumentChunk] = []
    private let embeddingService: EmbeddingService
    private let storageURL: URL

    private struct Persistence: Codable {
        var documents: [Document]
        var chunks: [DocumentChunk]
    }

    init(embeddingService: EmbeddingService) {
        self.embeddingService = embeddingService
        let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.storageURL = docsDir.appendingPathComponent("rag_vector_store.json")
        self.load()
    }

    func addDocument(_ document: Document) async {
        documents.append(document)
        let textChunks = Self.chunkText(document.content)
        for (index, chunkText) in textChunks.enumerated() {
            let embedding = await embeddingService.embed(chunkText)
            let chunk = DocumentChunk(
                text: chunkText,
                embedding: embedding,
                sourceDocumentId: document.id,
                sourceDocumentName: document.name,
                chunkIndex: index
            )
            chunks.append(chunk)
        }
        persist()
    }

    func removeDocument(id: UUID) {
        documents.removeAll { $0.id == id }
        chunks.removeAll { $0.sourceDocumentId == id }
        persist()
    }

    func search(query: String, topK: Int = 3) async -> [SearchResult] {
        guard !chunks.isEmpty else { return [] }
        let queryEmbedding = await embeddingService.embed(query)
        guard !queryEmbedding.isEmpty else { return [] }

        var results: [SearchResult] = []
        for chunk in chunks {
            let sim = await embeddingService.cosineSimilarity(queryEmbedding, chunk.embedding)
            results.append(SearchResult(chunk: chunk, similarity: sim))
        }
        return Array(results.sorted { $0.similarity > $1.similarity }.prefix(topK))
    }

    func allDocuments() -> [Document] { documents }
    func chunkCount() -> Int { chunks.count }

    private static func chunkText(_ text: String, chunkSize: Int = 150, overlap: Int = 30) -> [String] {
        let words = text.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
        guard !words.isEmpty else { return [] }
        if words.count <= chunkSize { return [text] }

        var result: [String] = []
        var start = 0
        while start < words.count {
            let end = min(start + chunkSize, words.count)
            result.append(words[start..<end].joined(separator: " "))
            start += chunkSize - overlap
        }
        return result
    }

    private func persist() {
        let data = Persistence(documents: documents, chunks: chunks)
        if let encoded = try? JSONEncoder().encode(data) {
            try? encoded.write(to: storageURL)
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: storageURL),
              let decoded = try? JSONDecoder().decode(Persistence.self, from: data) else { return }
        documents = decoded.documents
        chunks = decoded.chunks
    }
}
