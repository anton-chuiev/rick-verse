# Unit Tests — Characters List Spec

## Overview

First unit tests in the project, establishing the testing foundation the rest of the codebase will follow: where tests live, how seams are mocked, and what is worth asserting. Scope is the Characters List vertical slice — its view model, its DTO → domain mapping, and its repository — covering every layer that carries real logic between `GET /character` and the rendered list.

A piece belongs to this feature if the Characters List screen depends on it. That takes in `ResourceURL`, which is shared but called directly by the character mapper, and leaves out the Character Detail stack.

This is a test-only feature: no production code changes. The architecture already exposes every seam needed — view models depend on repository protocols, `APIClient` is itself a protocol, and the search debounce is injected — so the tests need neither the network nor the wall clock.

## Requirements

### Test target & layout

The `Tests` target already exists with Swift Testing and a placeholder `Tests/Tests.swift`, which should go once real tests replace it. Tests mirror the app's layer-first structure, so a test's location maps to the code it covers, with shared mocks and fixtures in their own folder:

```
Tests/
├── Mocks/
├── Presentation/
└── Data/
```

The test target does not inherit the app target's default main-actor isolation, so `@MainActor` has to be written explicitly on suites and doubles that need it.

### Mocking approach

Two seams carry the whole feature.

**The characters repository** is mocked for the view model tests. Most of them need nothing more than a spy: canned responses, plus a record of every request received, in order — that is how debounce is proven (three keystrokes must produce one request) and how filter and paging are verified.

Only the race tests need more: a repository that can hold a call open and release it on demand, so responses can be forced to complete out of order. That belongs in a **separate** test double rather than complicating the spy every other test uses — the machinery it takes (continuations, resume-by-index) should sit where it's earned, next to the reason it exists.

**The API client** is stubbed for the repository tests. It is scripted with raw JSON — the same wire payloads the real API returns — and decodes them exactly as the production client does, so the repository tests exercise real DTO decoding rather than hand-built objects. It also records the endpoint it was handed, which is how the built path and query parameters get asserted.

Both should stay as simple as Swift 6 strict concurrency allows; the view model is `@MainActor`, so its tests and mock live there too.

### Coverage — Characters List view model

This holds the most subtle logic in the codebase, and the tests exist to protect it.

**Race guarding** is the highest-value target. The view model tags each first-page load with a generation token and drops results from superseded loads. The tests must prove that when a slow load is overtaken by a newer one, the slow result is discarded even though it arrives last — and likewise that a next-page response landing after a reload does not append to the fresh list. These are the bugs that surface once in a hundred runs and never in manual testing.

**Cancellation must not read as failure.** A cancelled first load returns to idle so that re-appearing retriggers it, while a cancelled reload keeps the content already on screen. Neither may end in the error state.

**Search debounce** collapses rapid typing into a single request carrying the last value, ignores a set that doesn't change the text, and trims whitespace — a whitespace-only query sends no name filter at all. Tests inject a negligible debounce; none waits out the production interval.

**Filter changes** reload immediately rather than debounced, map to the right API value, send nothing for "All", and ignore a repeat selection.

**Load states and pagination** round it out: populated, empty, and failed first loads; a repeated appear firing one request; next-page requests suppressed when there is no next page or one is already running; a successful page appending rather than replacing; a failed page keeping what was already loaded; and the pagination token advancing on both success and failure so the list footer re-arms.

### Coverage — Data layer

**Resource URL parsing** is a pure function with an obvious set of edges: a well-formed URL, a non-numeric tail, an empty string, and a trailing slash.

**Character mapping** is tested from real API-shaped JSON rather than hand-constructed DTOs, so the coding keys are covered alongside the mapping. It should pin down case-insensitive status parsing, an unrecognized status falling back to unknown, episode URLs becoming IDs with unparseable entries dropped rather than fatal, nested origin and location names lifting to flat fields, and a malformed image URL yielding nil. An empty type maps through untouched — rendering it as a dash is the view's job, not the mapper's.

**The characters repository** carries one genuinely important behavior: the API answers "nothing matched your filter" with a 404, and the repository turns that into an empty page instead of an error. Its mirror image matters just as much — every other error must propagate, because a slightly-too-broad catch would silently show "no results" whenever the network fails. Beyond that: mapping a page response through to the domain, deriving whether a next page exists, and building the expected endpoint and query parameters from a request, omitting absent filters.

## Behavior / Conventions

- One behavior per test, named for the behavior rather than the method under test.
- Assert against observable state and recorded requests, never private internals.
- Determinism is non-negotiable: no network, no dependence on the wall clock. Timing is driven by the injected debounce and by releasing mocked calls explicitly, never by sleeping and hoping.
- JSON fixtures live inline in the test that uses them; the volume here doesn't warrant bundle resources.
- A test that resists being written cleanly is a finding about the production code. Report it — don't reshape production code to suit a test without asking. Two are already known: the next-page error path sleeps for a second as an API rate-limit back-off, which a failure test must not simply wait out; and trailing-slash URL parsing looks questionable. Pin current behavior and flag it.

## Out of Scope

Deferred, in rough priority order:

- Character Detail view model tests — progressive loading, and a character with no episodes never reaching the network
- The Character Detail data stack: episode mapping, the episode repository and its single-object-vs-array decoding quirk, and the character detail repository. The API client stub carries over unchanged.
- Tests for the URL session client itself — status mapping, cancellation translation, URL building. Considered during this feature and **declined**: covering it means stubbing `URLProtocol`, whose Foundation machinery (subclassing, static state behind a lock, hand-assembled HTTP responses) costs more than it protects for a thin client that rarely changes. The client's own behavior stays uncovered; this feature stubs the protocol above it. Revisit if that client grows logic.
- UI tests, excluded during scaffolding per the coding standards
- CI wiring and coverage gates
- Views, design tokens, coordinators, and pass-through use cases — no logic to protect

## References

- @context/coding-standards.md (Testing Requirements, Swift 6 strict concurrency)
- @context/project-overview.md (Module Structure, Use Case Convention, Repository Convention)
- @context/features/characters-list-spec.md (API response shape for the JSON fixtures)
- @rick-verse/Presentation/Characters/List/CharactersListViewModel.swift
- @rick-verse/Data/Repositories/DefaultCharactersRepository.swift
- @rick-verse/Data/Network/Character/CharacterDTO+Mapping.swift
- @rick-verse/Data/Network/Core/ResourceURL.swift
- @rick-verse/Domain/Repositories/CharactersRepository.swift (the mocked protocol)
- @rick-verse/Data/Network/Core/APIClient.swift (the stubbed protocol)
