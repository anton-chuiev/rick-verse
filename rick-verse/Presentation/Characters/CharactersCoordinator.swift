//
//  CharactersCoordinator.swift
//  rick-verse
//

import Observation

/// Flow coordinator for the Characters tab. Owns the tab's navigation state and
/// decides navigation on the view models' behalf.
///
/// Navigation has two independent axes, modeled as separate state:
/// - **Push** — a `path` stack driving `NavigationStack` (many screens deep).
/// - **Present** — an optional `presentedSheet` driving a modal `.sheet` (one
///   at a time). `fullScreenCover` would be a third, analogous axis.
///
/// Keeping them separate matters: `NavigationStack` only does push/pop, so a
/// sheet can't live in `path`. Note the different protocols — pushed `Route`
/// values are `Hashable` (the stack hashes them), while a presented `Sheet` is
/// `Identifiable` (`.sheet(item:)` only needs "what, if anything, is shown").
@Observable
final class CharactersCoordinator {

    // MARK: Push axis

    /// A screen pushed onto the navigation stack.
    enum Route: Hashable {
        case characterDetail(id: Int)
    }

    var path: [Route] = []

    /// Pushes the Character Detail screen for the given character id.
    func showCharacterDetail(id: Int) {
        path.append(.characterDetail(id: id))
    }

    // MARK: Present axis

    /// A modally presented screen. Only one can be up at a time, so this is an
    /// optional rather than a stack.
    enum Sheet: Identifiable {
        /// Half-height filters sheet (see `.presentationDetents` in the view).
        case filters

        var id: String {
            switch self {
            case .filters: "filters"
            }
        }
    }

    var presentedSheet: Sheet?

    /// Presents the filters sheet.
    func showFilters() {
        presentedSheet = .filters
    }

    /// Dismisses whatever is presented. Setting the binding to `nil` also
    /// happens automatically when the user swipes the sheet down.
    func dismissSheet() {
        presentedSheet = nil
    }
}
