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
    /// the on-disk cache absorbs re-scrolls. 4 keeps scrolling responsive
    /// without tripping the limit.
    private static let maxConcurrentDownloads = 4

    /// Applies the shared configuration. Call once, early in app startup.
    static func apply() {
        ImageDownloader.default.sessionConfiguration.httpMaximumConnectionsPerHost = maxConcurrentDownloads
    }
}
