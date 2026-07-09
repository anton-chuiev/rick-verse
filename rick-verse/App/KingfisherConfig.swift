//
//  KingfisherConfig.swift
//  rick-verse
//

import Foundation
import Kingfisher

/// One-time Kingfisher setup, applied at app launch.
enum KingfisherConfig {
    /// Caps how many image downloads run at once. The Rick and Morty API
    /// rate-limits (HTTP 429) when a fast scroll fires a burst of avatar
    /// requests; throttling the pipeline keeps the burst under that limit while
    /// the on-disk cache absorbs re-scrolls. Kept low (2) because the limit is
    /// strict and shared with the paging requests — a higher value lets a fast
    /// flick trip it, leaving cards blank until they scroll back into view.
    private static let maxConcurrentDownloads = 2

    /// Retries a throttled avatar load rather than leaving it as a blank
    /// placeholder forever. Kingfisher surfaces HTTP 429 as a `responseError`,
    /// which `DelayRetryStrategy` retries; the `.accumulated` interval spaces the
    /// attempts out (3s, 6s, 9s, …) so recovery doesn't itself re-flood the API
    /// the way a fixed short per-image retry would. Applied globally via
    /// `defaultOptions` so every `KFImage` inherits it without per-view setup.
    private static let retryStrategy = DelayRetryStrategy(
        maxRetryCount: 4,
        retryInterval: .accumulated(3)
    )

    /// Applies the shared configuration. Call once, early in app startup.
    static func apply() {
        ImageDownloader.default.sessionConfiguration.httpMaximumConnectionsPerHost = maxConcurrentDownloads
        KingfisherManager.shared.defaultOptions += [.retryStrategy(retryStrategy)]
    }
}
