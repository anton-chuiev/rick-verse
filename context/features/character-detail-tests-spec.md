# Character Detail Tests Spec

## Overview

Unit tests for the Character Detail slice, which shipped (2026-07-15) before the project had tests and was skipped by the Unit Tests feature (which covered the Characters list only). This closes the gap found by the CI coverage gate work (`ci-lint-coverage-spec.md`): once the test host stopped running the live app, honest business-logic coverage was 76.3%, below the 80% bar, and Character Detail was the largest untested logic.

Tests only. No production changes: every seam already exists (`CharacterDetailRepository` and `FetchEpisodeBatchUseCase` protocols for the view model, `APIClient` for the repositories).

## Scope

| Unit | Lines (before) | Tested here |
|---|---|---|
| `CharacterDetailViewModel` | 0 / 58 | ✅ state transitions, progressive loading, retry, cancellation |
| `DefaultEpisodeBatchRepository` | 0 / 17 | ✅ single-vs-array quirk, empty-IDs short-circuit, endpoint, errors |
| `DefaultCharacterDetailRepository` | 0 / 4 | ✅ mapping + endpoint, 404 surfaces as an error |
| `FetchEpisodeBatchUseCase` | 0 / 3 | ❌ pure pass-through: skipped per the testing guidelines |

## Requirements

### Test doubles (`Tests/Mocks/`)

- `MockCharacterDetailRepository`: scripted results in call order, records requests
- `MockFetchEpisodeBatchUseCase`: scripted results in call order, records requests
- Both `@MainActor final class`, matching the existing mocks
- `RMCharacter.fixture` gains an `episodeIDs:` parameter (default `[1]`, so existing call sites are unchanged)

### `CharacterDetailViewModelTests`

- Appearing loads the character, then its episodes. The batch request carries the character's episode IDs, and the character request carries the screen's `characterID`.
- `firstSeenIn` is the first episode's name; `nil` when episodes failed
- A failed character load → `.failed`, and episodes are never requested
- A character with no episode IDs → episodes `.empty` with no batch request; an empty batch response → `.empty`
- A failed episodes load keeps the character on screen; episodes `.failed`
- Appearing again after a load doesn't refetch
- Cancellation is not an error: a cancelled character load stays `.loading` and the next appear refetches; a cancelled episodes load stays `.loading`
- `retryCharacter()` after a failure recovers the whole screen
- `retryEpisodes()` after an episodes failure recovers them without refetching the character; before the character has loaded it's a no-op

### `DefaultEpisodeBatchRepositoryTests` (real wire JSON via `StubAPIClient`)

- Several IDs: the array response maps to domain, and the endpoint path is `episode/1,2`
- One ID: the single-object response decodes into a one-element list (the API quirk)
- Empty IDs: empty response and no network call
- Errors propagate

### `DefaultCharacterDetailRepositoryTests`

- Maps the response to domain and builds `character/{id}` with no query
- Errors propagate, including `notFound` (unlike the list repository, which maps 404 to empty)

## Verification

- Full suite green via `xcodebuild test` with per-test timeouts
- Coverage of the three units re-measured; result recorded in the history entry
