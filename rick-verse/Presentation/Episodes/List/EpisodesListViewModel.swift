//
//  EpisodesListViewModel.swift
//  rick-verse
//

import Foundation
import Observation

/// Drives the Episodes list screen: loads every episode up front, then groups
/// them into season sections for display. Depends only on the
/// `FetchAllEpisodesUseCase` protocol so it can be unit-tested with a trivial
/// mock. No infinite scroll — the whole (small) dataset is materialized on load.
@Observable
@MainActor
final class EpisodesListViewModel {
    /// One season's episodes, ready for the view. `season` is the parsed season
    /// number, or `nil` for episodes whose code didn't parse (the trailing
    /// "Unknown" bucket).
    struct SeasonSection: Identifiable, Equatable {
        let season: Int?
        let episodes: [Episode]

        /// Stable identity for `ForEach`. `-1` stands in for the `nil` bucket,
        /// which can't collide with a real 1-based season number.
        var id: Int { season ?? -1 }

        /// Section header text, e.g. "Season 1" or "Unknown".
        var title: String {
            season.map { "Season \($0)" } ?? "Unknown"
        }
    }

    /// State of the load, driving the whole-screen UI (skeleton / content /
    /// empty / error).
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case empty
        case failed
    }

    private(set) var sections: [SeasonSection] = []
    private(set) var totalCount = 0
    private(set) var loadState: LoadState = .idle

    private let fetchAllEpisodes: FetchAllEpisodesUseCase

    /// Monotonic token identifying the most recent load. A result tagged with an
    /// older token is stale (a newer reload superseded it) and must not be
    /// applied — guards against out-of-order completions racing on the main actor.
    private var generation = 0

    init(fetchAllEpisodes: FetchAllEpisodesUseCase) {
        self.fetchAllEpisodes = fetchAllEpisodes
    }

    /// Loads once on first appearance. No-ops after the first load starts.
    func onAppear() async {
        guard loadState == .idle else { return }
        await load()
    }

    /// Reloads from scratch (pull-to-refresh). Awaits so the refresh spinner
    /// stays up until done.
    func reload() async {
        await load()
    }

    /// Retries after a failure.
    func retry() async {
        await load()
    }

    private func load() async {
        generation += 1
        let token = generation
        // Only flash the skeleton when there's nothing on screen yet; a reload
        // over existing content keeps it until the fresh data arrives.
        if loadState != .loaded {
            loadState = .loading
        }

        do {
            let episodes = try await fetchAllEpisodes.execute()
            guard token == generation else { return }
            sections = Self.group(episodes)
            totalCount = episodes.count
            loadState = episodes.isEmpty ? .empty : .loaded
        } catch is CancellationError {
            // Superseded or the view went away — leave a reload's content in
            // place; reset a first load so re-appearing re-triggers it.
            guard token == generation else { return }
            if loadState == .loading {
                loadState = .idle
            }
        } catch {
            guard token == generation, !Task.isCancelled else { return }
            sections = []
            totalCount = 0
            loadState = .failed
        }
    }

    // MARK: - Grouping

    /// Groups episodes into season sections, ordered by season ascending and by
    /// episode number ascending within each section. Episodes whose code doesn't
    /// parse land in a trailing `nil`-season bucket rather than being dropped.
    private static func group(_ episodes: [Episode]) -> [SeasonSection] {
        let grouped = Dictionary(grouping: episodes) { season(from: $0.episodeCode) }

        let sections: [SeasonSection] = grouped.map { season, episodes in
            let sorted = episodes.sorted { number(from: $0.episodeCode) < number(from: $1.episodeCode) }
            return SeasonSection(season: season, episodes: sorted)
        }

        // Real seasons first (ascending); the `nil` bucket sorts last.
        return sections.sorted { ($0.season ?? .max) < ($1.season ?? .max) }
    }

    /// Parses the season number from an episode code like "S01E01" → 1. Returns
    /// `nil` if the code doesn't match the expected shape.
    private static func season(from code: String) -> Int? {
        component(of: code, marker: "S")
    }

    /// Parses the episode number from an episode code like "S01E02" → 2, used
    /// only for ordering within a section. Falls back to `.max` so unparseable
    /// codes sort to the end of their bucket.
    private static func number(from code: String) -> Int {
        component(of: code, marker: "E") ?? .max
    }

    /// Extracts the digits following `marker` in a code like "S01E02". `S` →
    /// season, `E` → episode. `nil` if the marker is absent or has no digits.
    private static func component(of code: String, marker: Character) -> Int? {
        guard let markerIndex = code.firstIndex(of: marker) else { return nil }
        let digits = code[code.index(after: markerIndex)...].prefix { $0.isNumber }
        return Int(digits)
    }
}
