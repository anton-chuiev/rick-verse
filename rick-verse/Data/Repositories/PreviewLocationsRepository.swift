//
//  PreviewLocationsRepository.swift
//  rick-verse
//

#if DEBUG
/// `LocationsRepository` for SwiftUI previews: serves a fixed set of locations
/// with no network access, paged to exercise the view model's infinite-scroll
/// accumulation. Set `error` to preview the failure state.
struct PreviewLocationsRepository: LocationsRepository {
    var locations: [Location] = PreviewLocationsRepository.sample
    var pageSize = 3
    var error: Error?

    func locations(matching request: LocationsRequest) async throws -> LocationsResponse {
        if let error { throw error }

        let start = (request.page - 1) * pageSize
        guard start < locations.count else {
            return LocationsResponse(locations: [], totalCount: locations.count, hasNextPage: false)
        }
        let end = min(start + pageSize, locations.count)
        return LocationsResponse(
            locations: Array(locations[start..<end]),
            totalCount: locations.count,
            hasNextPage: end < locations.count
        )
    }
}

extension PreviewLocationsRepository {
    /// A handful of locations spanning several pages, including empty
    /// `type`/`dimension` values so previews exercise the "—" fallback.
    static let sample: [Location] = [
        Location(id: 1, name: "Earth (C-137)", type: "Planet", dimension: "Dimension C-137", residentIDs: [1, 2, 3]),
        Location(id: 2, name: "Abadango", type: "Cluster", dimension: "unknown", residentIDs: [6]),
        Location(id: 3, name: "Citadel of Ricks", type: "Space station", dimension: "", residentIDs: [8, 14, 15]),
        Location(id: 4, name: "Worldender's lair", type: "Planet", dimension: "", residentIDs: [22]),
        Location(id: 5, name: "Anatomy Park", type: "Microverse", dimension: "Dimension C-137", residentIDs: [30, 31]),
    ]
}
#endif
