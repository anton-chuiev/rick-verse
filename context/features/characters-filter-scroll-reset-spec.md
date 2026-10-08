# Characters Filter Scroll Reset — Fix Spec

## Overview

On the Characters list, scrolling deep into one filter (e.g. All) and then switching to another (e.g. Dead) appears to load "not the first page". The page number is in fact reset — every first-page load requests page 1 and sets `currentPage = 1` — so the bug is in what the user *sees*, plus one real race behind it.

**Bug 1 — scroll position survives the reload (the visible symptom).** A reload over existing content deliberately keeps the old list on screen until the new page arrives (no skeleton flash). The `ScrollView` is the same view throughout, so it keeps its offset. When ~20 Dead characters replace a long All list, the offset is clamped to the bottom of the short new list: the user lands at the end of page 1, the footer sentinel is immediately visible and starts pulling pages 2, 3…

**Bug 2 — a next page can start while a reload is in flight (real page mixing).** `loadNextPage` captures the *current* `generation` but builds its request from the *old* `currentPage` and the *new* filter. If the sentinel fires after a filter change but before the new first page lands, it requests e.g. "Dead, page 6" tagged with the fresh generation. That result passes the stale-token guard and is appended to Dead page 1, with `currentPage` advancing to 2.

## Approach

The first draft fixed both bugs with two more pieces of state (`isLoadingFirstPage`, `firstPageToken`) on top of an already crowded view model. Its complexity came from discarding stale responses two ways at once: a `generation` token checked in five places *and* cancelling `reloadTask` — needed because `reload()` / `onAppear()` loaded in their own tasks, which nothing could cancel. So the fix doubles as a simplification.

## Requirements

### View model (`CharactersListViewModel`)

- **One load in flight.** A single `loadTask` holds whatever is loading, first page or next page. Starting a first-page load (filter, search, refresh, retry, appear) cancels it; a cancelled load never applies its result. `onAppear` / `reload` / `retry` await the task, so pull-to-refresh keeps its spinner.
- **No next page during a reload.** `loadNextPageIfNeeded()` only starts when `loadTask` is `nil` — the race closes by construction.
- **Removed:** `generation` and its token checks, `reloadTask`, `isLoadingNextPage` (unused by the view).
- **Injectable retry back-off** (`retryBackOff`, default 1s), like `searchDebounce`. Tests used to dodge the hard-coded 1s by cancelling the caller, which no longer reaches the load task.
- **Behavior change:** leaving the screen mid-first-load no longer cancels it; the load finishes and the content is there on return.

### View (`CharactersListView`)

- On `statusFilter` / `searchText` change, scroll the list to its first row (`ScrollViewReader`) — before the new page lands, so it swaps in at offset 0. No view-model state; pull-to-refresh doesn't scroll.
- The keep-old-content-until-new-arrives behavior stays (no skeleton on reload).

### Out of scope

- `LocationsListViewModel` has the same shape (minus filters); could get the same simplification as a separate task.

## Tests (`CharactersListViewModelTests`)

- New: a next page is not requested while a filter reload is in flight; once it lands, paging requests page 2 with the new filter.
- Existing race tests (superseded first page, stale next page) kept unchanged.
- Each of the three guards (idle-only paging, discard on cancel for first and next page) verified to fail its test when removed.
- Failure tests inject a zero back-off instead of cancelling the caller.

## Verification

- Full suite green via `xcodebuild test` with per-test timeouts
- Manual check on the simulator: scroll All down several pages, switch to Dead → list starts at the top with Dead page 1
