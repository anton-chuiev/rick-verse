//
//  Location.swift
//  rick-verse
//

/// A location in the Rick and Morty universe. Pure domain entity — no
/// persistence or network dependency. `type` and `dimension` are often empty
/// strings from the API; the presentation layer shows "—" in that case.
struct Location: Identifiable, Equatable {
    let id: Int
    let name: String
    let type: String
    let dimension: String
    let residentIDs: [Int]
}
