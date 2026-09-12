import Foundation

struct TodoistTask: Decodable {
    let id: String
    let content: String
}

enum TodoistError: LocalizedError {
    case missingToken
    case badStatus(Int)

    var errorDescription: String? {
        switch self {
        case .missingToken: return "Set your API token in Settings…"
        case .badStatus(401): return "Invalid API token"
        case .badStatus(let code): return "Todoist returned HTTP \(code)"
        }
    }
}

struct TodoistClient {
    let token: String

    private struct Page: Decodable {
        let results: [TodoistTask]
        let nextCursor: String?
    }

    /// Fetches every active task matching a Todoist filter query (e.g. "today", "overdue").
    func tasks(matching filter: String) async throws -> [TodoistTask] {
        var all: [TodoistTask] = []
        var cursor: String? = nil
        repeat {
            var components = URLComponents(string: "https://api.todoist.com/api/v1/tasks/filter")!
            var items = [URLQueryItem(name: "query", value: filter), URLQueryItem(name: "limit", value: "200")]
            if let cursor { items.append(URLQueryItem(name: "cursor", value: cursor)) }
            components.queryItems = items

            var request = URLRequest(url: components.url!)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard (200..<300).contains(status) else { throw TodoistError.badStatus(status) }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let page = try decoder.decode(Page.self, from: data)
            all += page.results
            cursor = page.nextCursor
        } while cursor != nil
        return all
    }
}
