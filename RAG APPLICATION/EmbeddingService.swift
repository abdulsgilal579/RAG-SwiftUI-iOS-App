import Foundation
import NaturalLanguage

actor EmbeddingService {
    private let wordEmbedding: NLEmbedding?

    init() {
        self.wordEmbedding = NLEmbedding.wordEmbedding(for: .english)
    }

    var isAvailable: Bool { wordEmbedding != nil }

    func embed(_ text: String) -> [Float] {
        guard let embedding = wordEmbedding else { return [] }

        let normalized = text.lowercased()
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = normalized

        var vectors: [[Float]] = []
        tokenizer.enumerateTokens(in: normalized.startIndex..<normalized.endIndex) { range, _ in
            let word = String(normalized[range])
            if let vector = embedding.vector(for: word) {
                vectors.append(vector.map { Float($0) })
            }
            return true
        }

        guard !vectors.isEmpty else { return [] }
        let dim = vectors[0].count
        var avg = [Float](repeating: 0, count: dim)
        for v in vectors {
            for i in 0..<dim { avg[i] += v[i] }
        }
        let n = Float(vectors.count)
        return avg.map { $0 / n }
    }

    func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count, !a.isEmpty else { return 0 }
        var dot: Float = 0
        var normA: Float = 0
        var normB: Float = 0
        for i in 0..<a.count {
            dot += a[i] * b[i]
            normA += a[i] * a[i]
            normB += b[i] * b[i]
        }
        let denom = sqrt(normA) * sqrt(normB)
        return denom == 0 ? 0 : dot / denom
    }
}
