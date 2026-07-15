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

/// Generic networking client over `URLSession` + async/await. Knows nothing
/// about characters — it builds a request from any `Endpoint`, performs it, and
/// decodes the JSON response.
protocol APIClient: Sendable {
    func send<Response: Decodable>(_ endpoint: Endpoint) async throws -> Response
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

    func send<Response: Decodable>(_ endpoint: Endpoint) async throws -> Response {
        let request: URLRequest
        do {
            request = try buildRequest(from: endpoint)
        } catch {
            throw APIError.invalidURL
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError where error.code == .cancelled {
            // The request was cancelled (e.g. the view went away). Surface it as
            // cancellation, not a transport failure, so callers don't show an
            // error state for a normal lifecycle event.
            throw CancellationError()
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

    /// Builds a `URLRequest` from any endpoint: resolves the path against the
    /// base URL, expands the endpoint's `Encodable` query parameters into query
    /// items, and sets the HTTP method. Written once here so repositories never
    /// assemble requests themselves.
    private func buildRequest(from endpoint: Endpoint) throws -> URLRequest {
        let path = endpoint.path.hasPrefix("/") ? String(endpoint.path.dropFirst()) : endpoint.path
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        ) else {
            throw APIError.invalidURL
        }

        let queryParameters = try endpoint.queryParameters?.toDictionary() ?? [:]
        if !queryParameters.isEmpty {
            // Sorted for stable, readable URLs (dictionaries are unordered).
            components.queryItems = queryParameters
                .map { URLQueryItem(name: $0.key, value: "\($0.value)") }
                .sorted { $0.name < $1.name }
        }

        guard let url = components.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        return request
    }
}

// MARK: - Encodable → query dictionary

private extension Encodable {
    /// Flattens an `Encodable` value into `[String: Any]` via JSON, for use as
    /// query parameters. `nil` optionals drop out, so absent parameters aren't
    /// sent.
    func toDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        let object = try JSONSerialization.jsonObject(with: data)
        return object as? [String: Any] ?? [:]
    }
}
