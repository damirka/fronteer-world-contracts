module world::requirement;

use std::type_name::{Self, TypeName};

/// A requirement is a tuple of a type name and a vector of bytes.
/// Bytes can be anything: a bcs-encoded data, a hash or a simple boolean.
public struct Requirement(TypeName, vector<u8>) has copy, drop, store;

public fun new<T>(data: vector<u8>): Requirement {
    Requirement(type_name::with_original_ids<T>(), data)
}

public fun is<T>(requirement: &Requirement): bool {
    requirement.0 == type_name::with_original_ids<T>()
}

public fun type_name(requirement: &Requirement): TypeName {
    requirement.0
}

public fun data(requirement: &Requirement): vector<u8> {
    requirement.1
}
