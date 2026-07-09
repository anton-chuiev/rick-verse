//
//  Endpoint.swift
//  rick-verse
//

import Foundation

/// A self-describing API endpoint: its path relative to the client's base URL,
/// its HTTP method, and its query parameters as an `Encodable` value. The
/// `APIClient` turns any `Endpoint` into a request, so this knowledge lives with
/// each endpoint instead of being rebuilt inside every repository.
protocol Endpoint {
    var path: String { get }
    var method: HTTPMethod { get }
    var queryParameters: Encodable? { get }
}

extension Endpoint {
    /// The Rick and Morty API is read-only — endpoints are GET unless they say
    /// otherwise.
    var method: HTTPMethod { .get }

    /// No query parameters by default.
    var queryParameters: Encodable? { nil }
}
