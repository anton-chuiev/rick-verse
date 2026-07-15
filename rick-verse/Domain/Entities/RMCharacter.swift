//
//  RMCharacter.swift
//  rick-verse
//

import Foundation

/// A character in the Rick and Morty universe. Pure domain entity — no
/// persistence or network dependency. Prefixed `RM` to avoid colliding with
/// the standard library's `Character`.
struct RMCharacter: Identifiable, Equatable {
    let id: Int
    let name: String
    let status: Status
    let species: String
    let imageURL: URL?
    let episodeIDs: [Int]
    let locationName: String
    /// Detail-only fields — the list doesn't display them, but the same entity
    /// serves both screens (no parallel detail entity). `type` is often an empty
    /// string; the detail screen shows "—" in that case.
    let gender: String
    let type: String
    let originName: String
}

extension RMCharacter {
    /// Alive/dead/unknown state, mapped case-insensitively from the API's
    /// capitalized `status` string.
    enum Status: Equatable {
        case alive
        case dead
        case unknown

        /// Maps the API string (`"Alive"`, `"Dead"`, or anything else) to a
        /// case. Unrecognized or `"unknown"` values fall back to `.unknown`.
        init(apiValue: String) {
            switch apiValue.lowercased() {
            case "alive": self = .alive
            case "dead": self = .dead
            default: self = .unknown
            }
        }
    }
}
