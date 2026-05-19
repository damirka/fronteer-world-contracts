module world::requirement;

use std::bcs;
use std::string::String;
use std::type_name::{Self, TypeName};

public struct Requirement has copy, drop, store {
    type_name: TypeName,
    name: Option<String>,
    data: vector<u8>,
}

public fun new<T>(name: Option<String>, data: vector<u8>): Requirement {
    Requirement {
        type_name: type_name::with_original_ids<T>(),
        name,
        data,
    }
}

public fun from_config<T: drop>(name: Option<String>, c: T): Requirement {
    new<T>(name, bcs::to_bytes(&c))
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
