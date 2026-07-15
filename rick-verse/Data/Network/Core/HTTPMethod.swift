//
//  HTTPMethod.swift
//  rick-verse
//

/// HTTP verb for a request. The Rick and Morty API is read-only, so `.get` is
/// the default, but the type keeps endpoints self-describing.
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}
