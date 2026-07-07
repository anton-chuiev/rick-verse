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
