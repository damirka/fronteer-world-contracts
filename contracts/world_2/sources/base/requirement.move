/// Base component of the Request + Requirement system.
/// Defines the `Requirement` type and the associated functions.
module world::requirement;

use std::{bcs, type_name::{Self, TypeName}};

/// A requirement is a tuple of a type name and a vector of bytes.
/// Bytes can be anything: a bcs-encoded data, a hash or a simple boolean.
public struct Requirement(TypeName, vector<u8>) has copy, drop, store;

/// Create a new requirement for the given type and data.
public fun new<T>(data: vector<u8>): Requirement {
    Requirement(type_name::with_original_ids<T>(), data)
}

/// Create a new requirement from a config object.
public fun from_config<T: drop>(c: T): Requirement {
    new<T>(bcs::to_bytes(&c))
}

/// Check if the requirement is for the given type.
public fun is<T>(requirement: &Requirement): bool {
    requirement.0 == type_name::with_original_ids<T>()
}

/// Get the type name of the requirement.
public fun type_name(requirement: &Requirement): TypeName {
    requirement.0
}

/// Get the data of the requirement.
public fun data(requirement: &Requirement): vector<u8> {
    requirement.1
}

/// Unwrap the requirement into its inner `TypeName` and data.
public fun unwrap(requirement: Requirement): (TypeName, vector<u8>) {
    let Requirement(type_name, data) = requirement;
    (type_name, data)
}
