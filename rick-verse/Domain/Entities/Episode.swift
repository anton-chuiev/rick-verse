//
//  Episode.swift
//  rick-verse
//

/// An episode in the Rick and Morty universe. Pure domain entity — no
/// persistence or network dependency. `airDate` and `episodeCode` stay as the
/// API's display strings (e.g. "December 2, 2013", "S01E01"); parsing them is a
/// presentation concern, not a domain one.
struct Episode: Identifiable, Equatable {
    let id: Int
    let name: String
    let airDate: String
    let episodeCode: String
    let characterIDs: [Int]
}
