//
//  LocationsListViewModel.swift
//  rick-verse
//

import Foundation
import Observation

/// Drives the Locations list screen: loading, paging, and pull-to-refresh.
/// Depends only on the `LocationsRepository` protocol so it can be unit-tested
/// with a trivial mock. Fetching a page is a single repository call with no
/// orchestration, so per the Use Case Convention the view model talks to the
/// repository directly rather than through a pass-through use case.
@Observable
@MainActor
final class LocationsListViewModel {
    /// State of the first-page load, which drives the whole-screen UI
    /// (skeleton / content / empty / error).
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case empty
        case failed
    }

    private(set) var locations: [Location] = []
    private(set) var totalCount = 0
    private(set) var loadState: LoadState = .idle
    /// True while a subsequent page is being appended (drives the footer
    /// spinner). Independent from the first-page `loadState`.
    private(set) var isLoadingNextPage = false

    private let repository: LocationsRepository

    /// Whether the API reported another page after the current one. Drives the
    /// list footer: the view shows a loading sentinel while this is true, and
    /// that sentinel is what triggers the next page.
    private(set) var hasNextPage = false

    /// Changes every time a next-page attempt finishes. The footer sentinel
    /// keys its `.task` on this, so a *failed* attempt (e.g. the API's HTTP 429
    /// rate limit) re-arms the trigger and the still-visible sentinel retries —
    /// instead of getting stuck until the user scrolls to recreate the row.
    private(set) var paginationToken = 0

    private var currentPage = 1
    /// Monotonic token identifying the most recent first-page query. Any result
    /// tagged with an older token is stale and must not be applied — this guards
    /// against out-of-order completions racing on the main actor (pull-to-refresh
    /// can start while an earlier load is still in flight).
    private var generation = 0

    init(repository: LocationsRepository) {
        self.repository = repository
    }

    /// Loads the first page if nothing has loaded yet. Safe to call on every
    /// `onAppear` — it no-ops once content or an error is present.
    func onAppear() async {
        guard loadState == .idle else { return }
        await performFirstPageLoad()
    }

    /// Reloads page 1, replacing the list. Awaits completion so pull-to-refresh
    /// keeps its spinner up until done.
    func reload() async {
        await performFirstPageLoad()
    }

    /// Loads the next page when the list's end sentinel becomes visible. Called
    /// from the footer's `.task(id: paginationToken)`, so it re-fires after every
    /// attempt — the sentinel reappears under the new last row on success, or in
    /// place on failure. State-driven ("the end is on screen") rather than
    /// event-driven, so it can't get stuck if a trigger is missed while a load is
    /// already in flight.
    func loadNextPageIfNeeded() async {
        guard hasNextPage, !isLoadingNextPage else { return }
        await loadNextPage()
    }

    /// Retries after a first-page failure.
    func retry() async {
        await performFirstPageLoad()
    }

    // MARK: - Loading

    private func performFirstPageLoad() async {
        generation += 1
        let token = generation
        // Only show the full-screen skeleton when there's nothing on screen yet.
        // A reload over an existing list (pull-to-refresh) keeps the current
        // content in place — the list is swapped in when the new page arrives —
        // so it doesn't flash to skeleton and jump scroll.
        let isFirstLoad = loadState != .loaded
        if isFirstLoad {
            loadState = .loading
        }

        do {
            let page = try await repository.locations(matching: LocationsRequest(page: 1))
            // A newer load started while this one was in flight — drop it so an
            // out-of-order completion can't overwrite fresher results.
            guard token == generation else { return }
            locations = page.locations
            totalCount = page.totalCount
            currentPage = 1
            hasNextPage = page.hasNextPage
            loadState = page.locations.isEmpty ? .empty : .loaded
        } catch is CancellationError {
            // Cancelled (superseded, or the view was covered/dismissed before the
            // load finished). If this was the first load, reset to `.idle` so
            // re-appearing re-triggers it — otherwise the screen would stay stuck
            // on the skeleton. A reload over existing content keeps it.
            guard token == generation else { return }
            if isFirstLoad {
                loadState = .idle
            }
        } catch {
            // A cancelled task must not surface as a failure — only a real error
            // should. `token` staleness covers superseding loads.
            guard token == generation, !Task.isCancelled else { return }
            locations = []
            totalCount = 0
            hasNextPage = false
            loadState = .failed
        }
    }

    private func loadNextPage() async {
        let token = generation
        isLoadingNextPage = true
        // Bumping the pagination token re-arms the footer sentinel's `.task`,
        // whether the load succeeds (list grew, sentinel moved down under the new
        // last row) or fails (sentinel still on screen, needs to retry). Done on
        // every exit so pagination can never silently stall.
        defer {
            isLoadingNextPage = false
            if token == generation {
                paginationToken += 1
            }
        }

        do {
            let page = try await repository.locations(matching: LocationsRequest(page: currentPage + 1))
            // A first-page reload happened mid-fetch — this page belongs to the
            // old query, so discard it.
            guard token == generation else { return }
            locations.append(contentsOf: page.locations)
            totalCount = page.totalCount
            currentPage += 1
            hasNextPage = page.hasNextPage
        } catch is CancellationError {
            // Superseded or the view went away — leave state as-is.
        } catch {
            // A page-N failure (typically the API's HTTP 429 rate limit under a
            // fast scroll) keeps already-loaded items. Back off briefly so the
            // sentinel's re-armed `.task` doesn't hammer the API immediately.
            guard token == generation else { return }
            try? await Task.sleep(for: .seconds(1))
        }
    }
}
