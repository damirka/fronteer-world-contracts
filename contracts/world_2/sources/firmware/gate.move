module world::gate;

use world::{
    assembly::{Self, Assembly},
    location_service,
    request::{Self, ApplicationRequest},
    requirement::Requirement
};

public struct Gate has store {
    owner_cap_id: ID,
}

public struct GateOwnerCap has key, store {
    id: UID,
    gate_id: ID,
}

#[allow(lint(self_transfer))]
public fun new(
    location_hash: vector<u8>,
    ctx: &mut TxContext,
): (Assembly, GateOwnerCap, ApplicationRequest) {
    let cap_id = object::new(ctx);
    let (assembly, request) = assembly::new(
        Gate {
            owner_cap_id: cap_id.to_inner(),
        },
        location_hash,
        b"Gate".to_string(),
        vector[location_service::requirement(location_hash)],
        ctx,
    );

    let cap = GateOwnerCap { id: cap_id, gate_id: object::id(&assembly) };
    (assembly, cap, request)
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
public fun add_requirement(assembly: &mut Assembly, cap: &GateOwnerCap, requirement: Requirement) {
    assert!(cap.gate_id == object::id(assembly));

    let requirements = assembly.requirements_mut<Gate>(internal::permit());
    requirements.push_back(requirement);
}
