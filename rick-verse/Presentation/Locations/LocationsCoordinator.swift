//
//  LocationsCoordinator.swift
//  rick-verse
//

import Observation

/// Flow coordinator for the Locations tab.
@Observable
final class LocationsCoordinator {
    enum Route: Hashable {}

    var path: [Route] = []
}
