#[allow(unused_variable)]
/// Idea: services could define their requirement and proof type, together with
///   custom types holding the logic. Maybe worth experimenting with other types
///   with requirements and proofs. What could work? Perhaps, Inventory?
module world::location_service;

use world::{request::ApplicationRequest, requirement::{Self, Requirement}};

/// Location type, holds the in-game location hash.
public struct Location(vector<u8>) has copy, drop, store;

#[allow(unused_field)]
/// Requirement for the location service.
public struct ProximityToLocation has drop { location_hash: vector<u8> }

/// Create a new location.
public fun new(location_hash: vector<u8>): Location {
    Location(location_hash)
}

/// Get the requirement for the location service.
public fun requirement(location_hash: vector<u8>): Requirement {
    requirement::new<ProximityToLocation>(location_hash)
}

/// Verify proximity of a certain location. Implementation details omitted.
public fun verify_proximity(request: &mut ApplicationRequest, proof: vector<u8>) {
    request.complete_requirement<ProximityToLocation>(internal::permit());
}
