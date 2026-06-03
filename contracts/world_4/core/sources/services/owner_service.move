module core::owner_service;

use core::{request::Request, requirement::{Self, Requirement}, transaction as tx};
use ptb::ptb;
use sui::bcs;

public struct Owner(ID) has drop;

public fun requirement(owner_cap_id: ID): Requirement {
    requirement::from_config(option::none(), Owner(owner_cap_id))
}

#[allow(unused)]
/// TODO: we need to chat about location proofs and verification in the world v1
public fun verify_owner_cap(
    request: &mut Request,
    // owner_cap:
) {
    // TODO: assert on whatever happens here
    let (requirement, frame) = request.take_next(internal::permit<Owner>());
    let _owner_cap_id = bcs::new(requirement.data()).peel_address().to_id();
    frame.destroy_empty();
}

#[allow(unused)]
public fun verify_as_admin(
    request: &mut Request,
    // admin
) {
    let (requirement, frame) = request.take_next(internal::permit<Owner>());
    let _owner_cap_id = bcs::new(requirement.data()).peel_address().to_id();
    frame.destroy_empty();
}

public fun verify_owner_cap_template(
    req: &Requirement,
    ptb: &mut ptb::Transaction,
    mut args: vector<ptb::Argument>,
) {
    assert!(req.is<Owner>());
    assert!(args.length() <= 1);

    let owner_cap_id = bcs::new(req.data()).peel_address().to_id();
    let owner_cap = if (args.length() == 1) {
        args.pop_back()
    } else {
        tx::owner_cap(owner_cap_id)
    };

    ptb.command(
        ptb::move_call(
            "mvr:@frontier/core",
            "location_service",
            "verify_proximity",
            vector[tx::request(), owner_cap],
            vector[],
        ),
    );
}
