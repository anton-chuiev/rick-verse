//
//  StubAPIClient.swift
//  Tests
//

import Foundation
@testable import rick_verse

/// A second implementation of the `APIClient` protocol, for tests.
///
/// `APIClient` has exactly one method — `send(_:)` — and two implementations:
///
///     DefaultCharactersRepository → APIClient ─┬─ URLSessionAPIClient  (app: calls the network)
///                                              └─ StubAPIClient        (tests: returns canned JSON)
///
/// The repository can't tell them apart: it hands over an `Endpoint` and gets a
/// decoded value back. Swapping this one in is what lets repository tests run
/// with no network at all — nothing here touches `URLSession`, and this type is
/// never compiled into the app.
///
/// A test scripts it with the JSON the real API would have returned:
///
///     let client = StubAPIClient(json: pageJSON)          // …or (error: APIError.notFound)
///     let repository = DefaultCharactersRepository(apiClient: client)
///     let response = try await repository.characters(matching: request)
///
/// **Why JSON and not a ready-made object?** `send` is generic over its return
/// type (`Response: Decodable`), so the stub only learns what to return when the
/// repository calls it. It therefore stores raw bytes and decodes them on demand,
/// exactly as `URLSessionAPIClient` does with the bytes off the wire. That's a
/// bonus, not a workaround: repository tests end up exercising the real DTO
/// decoding — coding keys included — instead of hand-built DTOs that could drift
/// from the actual API shape.
///
/// It also records every `Endpoint` it receives, which is how tests assert the
/// path and query parameters the repository built.
///
/// `@MainActor` because its mutable state has no synchronization of its own —
/// isolation is what actually makes it `Sendable`, rather than an `@unchecked`
/// promise the type can't keep. Matches `MockCharactersRepository`.
@MainActor
final class StubAPIClient: APIClient {
    /// What the next `send` returns: JSON bytes to decode, or an error to throw.
    var result: Result<Data, Error>

    /// Every endpoint received, oldest first.
    private(set) var receivedEndpoints: [Endpoint] = []

    init(json: String) {
        result = .success(Data(json.utf8))
    }

    init(error: Error) {
        result = .failure(error)
    }

    /// Stands in for the real network round-trip: record what was asked for,
    /// then either throw the scripted error or decode the scripted JSON into
    /// whatever type the caller expects.
    func send<Response: Decodable>(_ endpoint: Endpoint) async throws -> Response {
        receivedEndpoints.append(endpoint)
        let data = try result.get()
        return try JSONDecoder().decode(Response.self, from: data)
    }
}

// MARK: - Endpoint inspection

extension Endpoint {
    /// The endpoint's query parameters flattened to `[String: String]`, mirroring
    /// how `URLSessionAPIClient` encodes them into query items — `nil` fields
    /// drop out. Lets tests assert which filters were actually sent.
    func encodedQueryParameters() throws -> [String: String] {
        guard let queryParameters else { return [:] }
        let data = try JSONEncoder().encode(queryParameters)
        let object = try JSONSerialization.jsonObject(with: data)
        guard let dictionary = object as? [String: Any] else { return [:] }
        return dictionary.mapValues { "\($0)" }
    }
}
