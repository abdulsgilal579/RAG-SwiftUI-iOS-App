import Foundation

actor GroqService {
    private var apiKey: String = ""
    private let baseURL = URL(string: "https://api.groq.com/openai/v1/chat/completions")!

    private struct Request: Encodable {
        struct Message: Encodable {
            let role: String
            let content: String
        }
        let model: String
        let messages: [Message]
        let temperature: Double
        let max_tokens: Int
    }

    private struct Response: Decodable {
        struct Choice: Decodable {
            struct Message: Decodable { let content: String }
            let message: Message
        }
        let choices: [Choice]
    }

    func setAPIKey(_ key: String) { apiKey = key }
    func getAPIKey() -> String { apiKey }

    func complete(system: String, user: String, model: String = "llama-3.3-70b-versatile") async throws -> String {
        guard !apiKey.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw GroqError.missingKey
        }

        var urlRequest = URLRequest(url: baseURL)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = Request(
            model: model,
            messages: [
                .init(role: "system", content: system),
                .init(role: "user", content: user)
            ],
            temperature: 0.7,
            max_tokens: 1024
        )
        urlRequest.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let http = response as? HTTPURLResponse else { throw GroqError.badResponse }
        guard http.statusCode == 200 else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw GroqError.apiError(http.statusCode, msg)
        }

        let decoded = try JSONDecoder().decode(Response.self, from: data)
        return decoded.choices.first?.message.content ?? ""
    }

    enum GroqError: LocalizedError {
        case missingKey
        case badResponse
        case apiError(Int, String)

        var errorDescription: String? {
            switch self {
            case .missingKey: return "No GROQ API key set. Add it in Settings."
            case .badResponse: return "Invalid response from GROQ API."
            case .apiError(let code, let msg): return "GROQ API error \(code): \(msg)"
            }
        }
    }
}
