//
//  CharactersListViewModel.swift
//  rick-verse
//

import Foundation
import Observation

/// Drives the Characters list screen: loading, paging, search, and status
/// filtering. Depends only on the `CharactersRepository` protocol so it can be
/// unit-tested with a trivial mock. Fetching a page is a single repository call
/// with no orchestration, so per the Use Case Convention the view model talks to
/// the repository directly rather than through a pass-through use case.
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

    /// Whether the API reported another page after the current one. Drives the
    /// list footer: the view shows a loading sentinel while this is true, and
    /// that sentinel is what triggers the next page.
    private(set) var hasNextPage = false

    /// Changes every time a next-page attempt finishes. The footer sentinel
    /// keys its `.task` on this, so a *failed* attempt (e.g. the API's HTTP 429
    /// rate limit) re-arms the trigger and the still-visible sentinel retries —
    /// instead of getting stuck until the user scrolls to recreate the row.
    private(set) var paginationToken = 0

    var searchText = "" {
        didSet {
            guard searchText != oldValue else { return }
            startFirstPageLoad(debounce: searchDebounce)
        }
    }

    var statusFilter: StatusFilter = .all {
        didSet {
            guard statusFilter != oldValue else { return }
            startFirstPageLoad()
        }
    }

    private let repository: CharactersRepository
    private let searchDebounce: Duration
    private let retryBackOff: Duration

    private var currentPage = 1
    /// The one load in flight — first page or next page — or `nil` when idle.
    /// Starting a first-page load cancels it, and a cancelled load never applies
    /// its result, so a stale response can't land over a newer one. A next page
    /// only starts when this is `nil`, so it can't mix the previous list's page
    /// number with a new query.
    private var loadTask: Task<Void, Never>?

    init(
        repository: CharactersRepository,
        searchDebounce: Duration = .milliseconds(300),
        retryBackOff: Duration = .seconds(1)
    ) {
        self.repository = repository
        self.searchDebounce = searchDebounce
        self.retryBackOff = retryBackOff
    }

    /// Loads the first page if nothing has loaded yet. Safe to call on every
    /// `onAppear` — it no-ops once content or an error is present.
    func onAppear() async {
        guard loadState == .idle else { return }
        await startFirstPageLoad().value
    }

    /// Reloads page 1 with the current search + filter, replacing the list.
    /// Awaits completion so pull-to-refresh keeps its spinner up until done.
    func reload() async {
        await startFirstPageLoad().value
    }

    /// Retries after a first-page failure.
    func retry() async {
        await startFirstPageLoad().value
    }

    /// Loads the next page when the list's end sentinel becomes visible. Called
    /// from the footer's `.task(id: paginationToken)`, so it re-fires after every
    /// attempt. This is state-driven ("the end is on screen") rather than
    /// event-driven ("a row appeared once"), so it can't get stuck if a trigger
    /// is missed while a load is already in flight.
    func loadNextPageIfNeeded() async {
        guard hasNextPage, loadTask == nil else { return }
        await startLoad { await self.loadNextPage() }.value
    }

    // MARK: - Loading

    /// Makes `work` the one load in flight, cancelling the previous one.
    @discardableResult
    private func startLoad(_ work: @escaping @MainActor () async -> Void) -> Task<Void, Never> {
        loadTask?.cancel()
        let task = Task {
            await work()
            // Only a superseded load is cancelled, so an uncancelled one is
            // still the current load.
            if !Task.isCancelled {
                loadTask = nil
            }
        }
        loadTask = task
        return task
    }

    /// Starts a first-page load. `debounce` (search typing) waits before the
    /// request, so a newer keystroke cancels this one before it hits the API.
    @discardableResult
    private func startFirstPageLoad(debounce: Duration? = nil) -> Task<Void, Never> {
        startLoad {
            if let debounce {
                try? await Task.sleep(for: debounce)
                guard !Task.isCancelled else { return }
            }
            await self.loadFirstPage()
        }
    }

    private func loadFirstPage() async {
        // Only show the full-screen skeleton when there's nothing on screen
        // yet. A reload over an existing list (pull-to-refresh, filter, search)
        // keeps the current content in place — the list is swapped in when the
        // new page arrives — so it doesn't flash to skeleton and jump scroll.
        let isFirstLoad = loadState != .loaded
        if isFirstLoad {
            loadState = .loading
        }

        do {
            let page = try await repository.characters(matching: makeRequest(page: 1))
            // Superseded while in flight — the newer load owns the state now.
            guard !Task.isCancelled else { return }
            characters = page.characters
            totalCount = page.totalCount
            currentPage = 1
            hasNextPage = page.hasNextPage
            loadState = page.characters.isEmpty ? .empty : .loaded
        } catch is CancellationError {
            // Not a failure. If nothing superseded it and nothing is on screen,
            // reset to `.idle` so re-appearing re-triggers the load instead of
            // leaving the skeleton up. A reload over existing content keeps it.
            if isFirstLoad, !Task.isCancelled {
                loadState = .idle
            }
        } catch {
            // A superseded load must not surface as a failure (URLSession
            // reports cancellation as `URLError`, not `CancellationError`).
            guard !Task.isCancelled else { return }
            characters = []
            totalCount = 0
            hasNextPage = false
            loadState = .failed
        }
    }

    private func loadNextPage() async {
        // Bumping the pagination token re-arms the footer sentinel's `.task`,
        // whether the load succeeds (list grew, sentinel moved down under the
        // new last row) or fails (sentinel still on screen, needs to retry).
        // Done on every exit so pagination can never silently stall.
        defer { paginationToken += 1 }

        do {
            let page = try await repository.characters(matching: makeRequest(page: currentPage + 1))
            // A first-page reload replaced the list mid-fetch — this page
            // belongs to the old query, so discard it.
            guard !Task.isCancelled else { return }
            characters.append(contentsOf: page.characters)
            totalCount = page.totalCount
            currentPage += 1
            hasNextPage = page.hasNextPage
        } catch {
            // A page-N failure (typically the API's HTTP 429 rate limit under a
            // fast scroll) keeps already-loaded items. Back off briefly so the
            // sentinel's re-armed `.task` doesn't hammer the API immediately; a
            // first-page reload cancels the wait.
            try? await Task.sleep(for: retryBackOff)
        }
    }

    private func makeRequest(page: Int) -> CharactersRequest {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return CharactersRequest(
            page: page,
            name: trimmed.isEmpty ? nil : trimmed,
            status: statusFilter.status
        )
    }
}
