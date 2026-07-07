//
//  CharactersListViewModel.swift
//  rick-verse
//

import Foundation
import Observation

/// Drives the Characters list screen: loading, paging, search, and status
/// filtering. Depends only on the `FetchCharactersUseCase` protocol so it can
/// be unit-tested with a trivial mock.
@Observable
@MainActor
final class CharactersListViewModel {
    /// Status filter options shown as chips. `all` clears the API `status`
    /// param; the rest map to a `RMCharacter.Status`.
    enum StatusFilter: CaseIterable, Identifiable {
        case all
        case alive
        case dead
        case unknown

        var id: Self { self }

        var title: String {
            switch self {
            case .all: "All"
            case .alive: "Alive"
            case .dead: "Dead"
            case .unknown: "Unknown"
            }
        }

        /// The domain status this chip filters by, or `nil` for `.all`.
        var status: RMCharacter.Status? {
            switch self {
            case .all: nil
            case .alive: .alive
            case .dead: .dead
            case .unknown: .unknown
            }
        }
    }

    /// State of the first-page load, which drives the whole-screen UI
    /// (skeleton / content / empty / error).
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case empty
        case failed
    }

    private(set) var characters: [RMCharacter] = []
    private(set) var totalCount: Int = 0
    private(set) var loadState: LoadState = .idle
    /// True while a subsequent page is being appended (drives the footer
    /// spinner). Independent from the first-page `loadState`.
    private(set) var isLoadingNextPage = false

    var searchText = "" {
        didSet {
            guard searchText != oldValue else { return }
            scheduleSearch()
        }
    }

    var statusFilter: StatusFilter = .all {
        didSet {
            guard statusFilter != oldValue else { return }
            scheduleReload(debounced: false)
        }
    }

    private let fetchCharacters: FetchCharactersUseCase
    private let searchDebounce: Duration

    private var currentPage = 1
    private var hasNextPage = false
    /// The in-flight first-page load (debounced search, filter change, or
    /// pull-to-refresh). Stored so a newer request cancels the previous one.
    private var reloadTask: Task<Void, Never>?
    /// Monotonic token identifying the most recent first-page query. Any result
    /// tagged with an older token is stale and must not be applied — this
    /// guards against out-of-order completions racing on the main actor.
    private var generation = 0

    init(
        fetchCharacters: FetchCharactersUseCase,
        searchDebounce: Duration = .milliseconds(300)
    ) {
        self.fetchCharacters = fetchCharacters
        self.searchDebounce = searchDebounce
    }

    /// Loads the first page if nothing has loaded yet. Safe to call on every
    /// `onAppear` — it no-ops once content or an error is present.
    func onAppear() async {
        guard loadState == .idle else { return }
        await performFirstPageLoad()
    }

    /// Reloads page 1 with the current search + filter, replacing the list.
    /// Awaits completion so pull-to-refresh keeps its spinner up until done.
    func reload() async {
        await performFirstPageLoad()
    }

    /// Called by the view as rows appear; triggers the next page when the user
    /// nears the end of the loaded list.
    func onRowAppear(_ character: RMCharacter) async {
        guard let index = characters.firstIndex(of: character) else { return }
        let thresholdCrossed = index >= characters.count - Self.prefetchDistance
        guard thresholdCrossed, hasNextPage, !isLoadingNextPage else { return }
        await loadNextPage()
    }

    /// Retries after a first-page failure.
    func retry() async {
        await performFirstPageLoad()
    }

    // MARK: - Loading

    /// Kicks off a first-page load, cancelling any in-flight one. When
    /// `debounced` is true the request waits out the debounce interval first
    /// (used by search typing); filter changes reload immediately.
    private func scheduleReload(debounced: Bool) {
        reloadTask?.cancel()
        reloadTask = Task { [searchDebounce] in
            if debounced {
                try? await Task.sleep(for: searchDebounce)
                guard !Task.isCancelled else { return }
            }
            await performFirstPageLoad()
        }
    }

    private func scheduleSearch() {
        scheduleReload(debounced: true)
    }

    private func performFirstPageLoad() async {
        generation += 1
        let token = generation
        loadState = .loading

        let query = makeQuery(page: 1)
        do {
            let page = try await fetchCharacters.execute(query)
            // A newer load started while this one was in flight — drop it so an
            // out-of-order completion can't overwrite fresher results.
            guard token == generation else { return }
            characters = page.characters
            totalCount = page.totalCount
            currentPage = 1
            hasNextPage = page.hasNextPage
            loadState = page.characters.isEmpty ? .empty : .loaded
        } catch is CancellationError {
            // Superseded by a newer load; leave state to the newer task.
        } catch {
            guard token == generation else { return }
            characters = []
            totalCount = 0
            hasNextPage = false
            loadState = .failed
        }
    }

    private func loadNextPage() async {
        let token = generation
        isLoadingNextPage = true
        defer { isLoadingNextPage = false }

        let query = makeQuery(page: currentPage + 1)
        do {
            let page = try await fetchCharacters.execute(query)
            // A first-page reload happened mid-fetch — this page belongs to the
            // old query, so discard it.
            guard token == generation else { return }
            characters.append(contentsOf: page.characters)
            totalCount = page.totalCount
            currentPage += 1
            hasNextPage = page.hasNextPage
        } catch {
            // A page-N failure keeps already-loaded items and lets the user
            // try again by scrolling; it must not blow away the list.
        }
    }

    private func makeQuery(page: Int) -> CharacterQuery {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return CharacterQuery(
            page: page,
            name: trimmed.isEmpty ? nil : trimmed,
            status: statusFilter.status
        )
    }

    /// How many rows from the end triggers a prefetch of the next page.
    private static let prefetchDistance = 5
}
