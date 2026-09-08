import Foundation

struct APIClient {
    let baseURL: URL
    let session: URLSession

    enum Endpoint {
        case pairGenerate
        case pairBind
        case sendTouch
        case registerToken

        var path: String {
            switch self {
            case .pairGenerate: return "/pair/generate"
            case .pairBind: return "/pair/bind"
            case .sendTouch: return "/touch"
            case .registerToken: return "/device/register"
            }
        }
    }

    func post<Body: Encodable>(_ endpoint: Endpoint, body: Body, token: String? = nil) async throws -> Data {
        var request = URLRequest(url: baseURL.appendingPathComponent(endpoint.path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try JSONEncoder().encode(body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw TransportError.network(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw TransportError.network(URLError(.badServerResponse))
        }
        guard (200..<300).contains(http.statusCode) else {
            let message = String(decoding: data, as: UTF8.self)
            throw TransportError.serverRejected(message.isEmpty ? "服务器错误（\(http.statusCode)）" : message)
        }
        return data
    }
}