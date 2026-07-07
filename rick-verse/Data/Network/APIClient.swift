//
//  APIClient.swift
//  rick-verse
//

import Foundation

/// Errors surfaced by ``APIClient``.
enum APIError: Error, Equatable {
    /// The endpoint returned 404 — the Rick and Morty API uses this for
    /// "no results match the filter". Callers may choose to map it to empty.
    case notFound
    /// A non-2xx (and non-404) HTTP status.
    case httpStatus(Int)
    /// The response body could not be decoded into the expected type.
    case decoding
    /// The URL could not be built from the given path/query.
    case invalidURL
    /// Transport-level failure (no connection, timeout, …).
    case transport
}

/// A request describing one endpoint call: a path relative to the base URL and
/// optional query items.
struct APIRequest {
    let path: String
    var queryItems: [URLQueryItem] = []
}

/// Generic networking client over `URLSession` + async/await. Knows nothing
/// about characters — it builds URLs, performs requests, and decodes JSON.
protocol APIClient: Sendable {
    func send<Response: Decodable>(_ request: APIRequest) async throws -> Response
}

/// Default `APIClient` backed by `URLSession`.
struct URLSessionAPIClient: APIClient {
    let baseURL: URL
    let session: URLSession
    let decoder: JSONDecoder

    init(
        baseURL: URL = URLSessionAPIClient.rickAndMortyBaseURL,
        session: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = decoder
    }

    static let rickAndMortyBaseURL = URL(string: "https://rickandmortyapi.com/api")!

    func send<Response: Decodable>(_ request: APIRequest) async throws -> Response {
        guard let url = makeURL(for: request) else {
            throw APIError.invalidURL
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            throw APIError.transport
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.transport
        }

        switch http.statusCode {
        case 200...299:
            break
        case 404:
            throw APIError.notFound
        default:
            throw APIError.httpStatus(http.statusCode)
        }

        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw APIError.decoding
        }
    }

    private func makeURL(for request: APIRequest) -> URL? {
        let path = request.path.hasPrefix("/") ? String(request.path.dropFirst()) : request.path
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        ) else {
            return nil
        }
        if !request.queryItems.isEmpty {
            components.queryItems = request.queryItems
        }
        return components.url
    }
}
