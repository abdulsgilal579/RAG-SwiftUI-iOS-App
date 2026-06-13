import Foundation

struct Document: Identifiable, Codable {
    let id: UUID
    let name: String
    let content: String
    let createdAt: Date

    init(name: String, content: String) {
        self.id = UUID()
        self.name = name
        self.content = content
        self.createdAt = Date()
    }
}

struct DocumentChunk: Identifiable, Codable {
    let id: UUID
    let text: String
    let embedding: [Float]
    let sourceDocumentId: UUID
    let sourceDocumentName: String
    let chunkIndex: Int

    init(text: String, embedding: [Float], sourceDocumentId: UUID, sourceDocumentName: String, chunkIndex: Int) {
        self.id = UUID()
        self.text = text
        self.embedding = embedding
        self.sourceDocumentId = sourceDocumentId
        self.sourceDocumentName = sourceDocumentName
        self.chunkIndex = chunkIndex
    }
}

struct SearchResult {
    let chunk: DocumentChunk
    let similarity: Float
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: Role
    let content: String
    let sources: [DocumentChunk]
    let timestamp: Date

    enum Role {
        case user, assistant
    }

    init(role: Role, content: String, sources: [DocumentChunk] = []) {
        self.role = role
        self.content = content
        self.sources = sources
        self.timestamp = Date()
    }
}
