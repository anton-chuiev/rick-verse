//
//  DeepLink.swift
//  rick-verse
//

import Foundation

/// A parsed deep-link intent: *what* the user wants to see, decoupled from
/// *how* navigation state achieves it. `AppCoordinator.handle(_:)` translates
/// an intent into concrete tab + navigation-stack state.
///
/// Reference sample: only the Characters cases are wired, showing the shape.
/// Real apps grow this enum per feature and cover more URL forms.
enum DeepLink: Equatable {
    /// The Characters list, e.g. `rickverse://characters`.
    case charactersList
    /// A specific character's detail, e.g. `rickverse://character/42`.
    case characterDetail(id: Int)
}

extension DeepLink {
    /// The URL scheme the app answers to (declare it under
    /// `CFBundleURLTypes` in Info.plist to actually receive links).
    static let scheme = "rickverse"

    /// Parses a deep-link URL into an intent, or `nil` if it isn't one we
    /// handle. Kept as a pure function so it's trivially unit-testable.
    ///
    /// Recognized forms:
    /// - `rickverse://characters`
    /// - `rickverse://character/<id>`
    init?(url: URL) {
        guard url.scheme == DeepLink.scheme else { return nil }

        // The "host" is the first path component for a custom-scheme URL.
        let host = url.host()
        let segments = url.pathComponents.filter { $0 != "/" }

        switch (host, segments.first) {
        case ("characters", nil):
            self = .charactersList
        case ("character", let idString?):
            guard let id = Int(idString) else { return nil }
            self = .characterDetail(id: id)
        default:
            return nil
        }
    }
}
