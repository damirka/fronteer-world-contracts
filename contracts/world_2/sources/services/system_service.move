/// A service that manages system-level authorization and verification.
///
/// The `SystemAuthorization` requirement is used to confirm that the request is
/// authorized by the system — either by using a system cap or if a transaction
/// is sponsored by a system address.
module world::system_service;

use ptb::ptb;
use std::type_name;
use world::{request::ApplicationRequest, requirement::{Self, Requirement}};

/// A cap for the system service.
public struct SystemCap has key, store { id: UID }

/// The requirement managed by the system service.
public struct SystemAuthorization has drop {}

/// List of system addresses authorized to create proofs of actions.
public struct SystemAddresses has key {
    id: UID,
    sponsors: vector<address>,
}

/// The requirement for the system service.
public fun requirement(): Requirement {
    requirement::new<SystemAuthorization>(vector[])
}

/// Confirm the request with the system cap.
public fun confirm_with_cap(request: &mut ApplicationRequest, _cap: &SystemCap) {
    request.complete_requirement<SystemAuthorization>(internal::permit());
}

/// Confirm that the sponsor is a system address.
public fun confirm_sponsor_is_system(
    sa: &SystemAddresses,
    request: &mut ApplicationRequest,
    ctx: &TxContext,
) {
    assert!(sa.sponsors.contains(&ctx.sponsor().destroy_or!(abort)));
    request.complete_requirement<SystemAuthorization>(internal::permit());
}

#[allow(unused_function)]
fun ptb_template(): ptb::Command {
    let package_id = *type_name::with_defining_ids<SystemAuthorization>().as_string();

    // alternatively, we could pass in the system addresses as an argument
    // and it would look like:
    // ptb::object_by_id(object::id(&system_addresses));

    ptb::move_call(
        package_id.to_string(),
        "system_service",
        "confirm_sponsor_is_system",
        vector[ptb::ext_input("system_addresses"), ptb::ext_input("request")],
        vector[],
    )
}

#[test_only]
public fun confirm_for_testing(request: &mut ApplicationRequest) {
    request.complete_requirement<SystemAuthorization>(internal::permit());
}

#[test_only]
public fun ptb_template_for_testing(): ptb::Command {
    ptb_template()
}
