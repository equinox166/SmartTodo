import Foundation

/// DeepSeek Chat Completions client. The API is OpenAI-compatible.
/// Docs: https://api-docs.deepseek.com/
struct DeepSeekClient {
    enum ClientError: LocalizedError {
        case missingAPIKey
        case invalidResponse
        case server(String)
        case decoding

        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                return "未配置 DeepSeek API Key，请在设置中填写。"
            case .invalidResponse:
                return "AI 返回内容无法解析，请重试。"
            case .server(let msg):
                return msg
            case .decoding:
                return "AI 返回内容格式不正确。"
            }
        }
    }

    struct GeneratedItem: Decodable {
        let title: String
        let detail: String
    }

    private let endpoint = URL(string: "https://api.deepseek.com/chat/completions")!
    private let model = "deepseek-chat"

    func generateChecklist(goal: String) async throws -> (title: String, items: [GeneratedItem]) {
        guard let apiKey = KeychainHelper.read(SecretKeys.deepSeekAPIKey),
              !apiKey.isEmpty else {
            throw ClientError.missingAPIKey
        }

        let systemPrompt = """
        你是一名高效的任务拆解助手。用户会告诉你他们想完成的一件事，\
        你需要把它拆成可执行的待办清单。
        必须严格返回 JSON，格式如下（不要任何多余解释，不要使用 Markdown 代码块）：
        {
          "title": "清单标题（简短，不超过 12 个字）",
          "items": [
            {"title": "步骤标题（简洁，不超过 20 个字）", "detail": "简短说明（1-2 句）"}
          ]
        }
        要求：
        - items 数量 5-10 条，按执行先后顺序排列；
        - 每一条应当是可立即行动的具体任务；
        - 根据用户语言作答（用户说中文就用中文）。
        """

        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": goal]
            ],
            "response_format": ["type": "json_object"],
            "temperature": 0.3,
            "stream": false
        ]

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ClientError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            throw ClientError.server(message)
        }

        let envelope = try JSONDecoder().decode(ChatCompletion.self, from: data)
        guard let content = envelope.choices.first?.message.content else {
            throw ClientError.invalidResponse
        }

        return try Self.parseChecklist(from: content)
    }

    // MARK: - Parsing

    private static func parseChecklist(from raw: String) throws -> (title: String, items: [GeneratedItem]) {
        let cleaned = stripCodeFences(raw).trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = cleaned.data(using: .utf8) else { throw ClientError.decoding }
        struct Payload: Decodable {
            let title: String
            let items: [GeneratedItem]
        }
        let payload = try JSONDecoder().decode(Payload.self, from: data)
        return (payload.title, payload.items)
    }

    private static func stripCodeFences(_ s: String) -> String {
        var text = s.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.hasPrefix("```") {
            if let firstNewline = text.firstIndex(of: "\n") {
                text = String(text[text.index(after: firstNewline)...])
            }
            if text.hasSuffix("```") {
                text = String(text.dropLast(3))
            }
        }
        return text
    }

    // MARK: - OpenAI-compatible response

    private struct ChatCompletion: Decodable {
        struct Choice: Decodable {
            struct Message: Decodable { let content: String }
            let message: Message
        }
        let choices: [Choice]
    }
}
