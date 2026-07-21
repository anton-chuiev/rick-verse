//
//  LocationDTO+Mapping.swift
//  rick-verse
//

extension LocationDTO {
    /// Maps this wire model to the domain `Location`. Each `residents` URL's
    /// trailing ID is parsed into `residentIDs`; `name`, `type`, and `dimension`
    /// carry over as-is (empty strings included). `url` and `created` are dropped.
    func toDomain() -> Location {
        Location(
            id: id,
            name: name,
            type: type,
            dimension: dimension,
            residentIDs: residents.compactMap(ResourceURL.trailingID(from:))
        )
    }
}
