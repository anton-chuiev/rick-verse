//
//  ResourceURL.swift
//  rick-verse
//

/// Helpers for parsing Rick and Morty API resource URLs.
enum ResourceURL {
    /// Extracts the trailing integer ID from a resource URL such as
    /// `https://rickandmortyapi.com/api/episode/42` → `42`.
    static nonisolated func trailingID(from urlString: String) -> Int? {
        Int(urlString.split(separator: "/").last ?? "")
    }
}
