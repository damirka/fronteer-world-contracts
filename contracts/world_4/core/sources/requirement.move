#[allow(unused)]
/// Changes:
/// - no more `new`
/// - no more `copy` but adds `clone`
module core::requirement;

use std::{bcs, string::String, type_name::{Self, TypeName}};

public struct Requirement has drop, store {
    type_name: TypeName,
    name: Option<String>,
    data: vector<u8>,
}

public fun new<T>(name: Option<String>, data: vector<u8>): Requirement {
    abort /* Allows anyone to mess with constraints */
}

public fun from_config<T: drop>(name: Option<String>, c: T): Requirement {
    Requirement {
        type_name: type_name::with_original_ids<T>(),
        data: bcs::to_bytes(&c),
        name,
    }
}

public(package) fun clone(r: &Requirement): Requirement {
    Requirement {
        type_name: r.type_name,
        data: r.data,
        name: r.name
    }
}

public fun is<T>(requirement: &Requirement): bool {
    requirement.type_name == type_name::with_original_ids<T>()
}

public fun type_name(requirement: &Requirement): TypeName {
    requirement.type_name
}

public fun module_name(requirement: &Requirement): Option<String> {
    requirement.name
}

public fun data(requirement: &Requirement): vector<u8> {
    requirement.data
}
