module world::gate;

use world::{
    assembly::{Self, Assembly, OwnerCap},
    location_service,
    request::{Self, ApplicationRequest},
    requirement::Requirement
};

public struct Gate has store {}

#[allow(lint(self_transfer))]
public fun new(
    location_hash: vector<u8>,
    ctx: &mut TxContext,
): (Assembly, OwnerCap, ApplicationRequest) {
    let (assembly, owner_cap, request) = assembly::new(
        Gate {
            /* Gate fields could be here */
        },
        location_hash,
        b"Gate".to_string(),
        vector[location_service::requirement(location_hash)],
        ctx,
    );

    (assembly, owner_cap, request)
}

/// Should have more arguments.
public fun jump(assembly: &mut Assembly /* location, smth else ??? */): ApplicationRequest {
    assembly
        .requirements()
        .fold!(
            request::new(b"gate:interact".to_string()),
            |request, requirement| request.with_requirement(requirement),
        )
        .build()
}

///
public fun add_requirement(assembly: &mut Assembly, cap: &OwnerCap, requirement: Requirement) {
    assert!(assembly.cap_matches(cap));

    let requirements = assembly.requirements_mut<Gate>(internal::permit());
    requirements.push_back(requirement);
}
