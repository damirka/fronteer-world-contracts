module world::assembly;

use std::{string::String, type_name::{Self, TypeName}};
use sui::dynamic_field as df;
use world::{
    location_service::{Self, Location},
    request::{Self, ApplicationRequest},
    requirement::{Self, Requirement},
    system_service::SystemAuthorization
};

const VERSION: u64 = 1;

/// Key for the inner type of the Assembly.
public struct InnerKey() has copy, drop, store;

public struct OwnerCap has key, store { id: UID, assembly_id: ID }

/// A base Assembly type which stores different types / categories of assemblies.
public struct Assembly has key {
    id: UID,
    /// Purely visuals, I guess;
    /// Plus benefit of upgradeability (compared to enums).
    category: String,
    location: Location,
    inner_type: TypeName,
    owner_cap_id: Option<ID>,
    /// (Extra) requirements for interaction with the assembly.
    requirements: vector<Requirement>,
    // TODO: base requirements - ones that cannot be deleted by the owner
}

public fun new<T: store>(
    inner: T,
    location_hash: vector<u8>,
    category: String,
    requirements: vector<Requirement>,
    ctx: &mut TxContext,
): (Assembly, OwnerCap, ApplicationRequest) {
    let location = location_service::new(location_hash);
    let mut assembly = Assembly {
        id: object::new(ctx),
        inner_type: type_name::with_original_ids<T>(),
        owner_cap_id: option::none(),
        category,
        location,
        requirements,
    };

    df::add(&mut assembly.id, InnerKey(), inner);
    let id = object::new(ctx);
    assembly.owner_cap_id.fill(id.to_inner());
    let owner_cap = OwnerCap { id, assembly_id: object::id(&assembly) };

    (
        assembly,
        owner_cap,
        request::new(b"assembly:new".to_string())
            .with_requirement(requirement::new<SystemAuthorization>(vector[]))
            .with_version(VERSION)
            .build(),
    )
}

// === Public Accessors ===

/// Get the location of the Assembly.
public fun location(assembly: &Assembly): &Location { &assembly.location }

/// Get the category of the Assembly.
public fun category(assembly: &Assembly): &String { &assembly.category }

/// Get the requirements of the Assembly.
public fun requirements(assembly: &Assembly): vector<Requirement> {
    assembly.requirements
}

/// Get the requirement with the given type. Returns None if the requirement is not found.
public fun requirement_with_type<T>(assembly: &Assembly): Option<Requirement> {
    assembly
        .requirements
        .find_index!(|requirement| requirement.is<T>())
        .map!(|index| assembly.requirements[index])
}

/// Get the inner type of the Assembly.
public fun inner_type(assembly: &Assembly): &TypeName { &assembly.inner_type }

// === Internal Methods ===

/// Get access to the inner type of the `Assembly`.
/// Requires a `Permit`.
public fun inner<T: /* internal */ store>(assembly: &Assembly, _: internal::Permit<T>): &T {
    df::borrow(&assembly.id, InnerKey())
}

/// Get mutable access to the inner type of the `Assembly`.
/// Requires a `Permit`.
public fun inner_mut<T: /* internal */ store>(
    assembly: &mut Assembly,
    _: internal::Permit<T>,
): &mut T {
    df::borrow_mut(&mut assembly.id, InnerKey())
}

/// Allow modification of requirements of the Assembly.
/// Requires a `Permit`.
public fun requirements_mut<T: /* internal */ store>(
    assembly: &mut Assembly,
    _: internal::Permit<T>,
): &mut vector<Requirement> {
    assert!(df::exists_with_type<_, T>(&assembly.id, InnerKey())); // either
    assert!(type_name::with_original_ids<T>() == assembly.inner_type); // or
    &mut assembly.requirements
}

/// Interact with the Assembly. This function is used to initiate authorization
/// requests.
public fun interact<T: /* internal */ store>(
    assembly: &Assembly,
    name: String,
    _: internal::Permit<T>,
): ApplicationRequest {
    assert!(df::exists_with_type<_, T>(&assembly.id, InnerKey()));
    assert!(type_name::with_original_ids<T>() == assembly.inner_type);

    assembly
        .requirements
        .fold!(request::new(name), |request, requirement| request.with_requirement(requirement))
        .with_assembly_id(assembly.id.to_inner())
        .with_version(VERSION)
        .build()
}

/// Share the Assembly after creating it with `new`.
public fun share(assembly: Assembly) {
    transfer::share_object(assembly);
}

/// Check if the given cap matches the owner cap of the Assembly.
public fun cap_matches(assembly: &Assembly, cap: &OwnerCap): bool {
    assembly.owner_cap_id.is_some_and!(|owner_cap_id| owner_cap_id == cap.id.to_inner())
}
