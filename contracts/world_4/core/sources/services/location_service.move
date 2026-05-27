module core::location_service;

use core::{request::Request, requirement::{Self, Requirement}, transaction as tx};
use ptb::ptb;

public struct Proximity(vector<u8>) has drop;

public fun proximity_requirement(loc: vector<u8>): Requirement {
    requirement::from_config(option::none(), Proximity(loc))
}

#[allow(unused)]
/// TODO: we need to chat about location proofs and verification in the world v1
public fun verify_proximity_proof(
    request: &mut Request,
    location_hash: vector<u8>,
    proof: vector<u8>, // actually, a signature
) {
    // TODO: assert whatever happens here
    let (_requirement, frame) = request.take_next(internal::permit<Proximity>());
    frame.destroy_empty();
}

#[allow(unused)]
fun verify_requirement_template(
    req: &Requirement,
    ptb: &mut ptb::Transaction,
    args: vector<ptb::Argument>,
) {
    assert!(req.is<Proximity>());
    assert!(args.length() == 0);

    ptb.command(
        ptb::move_call(
            "mvr:@frontier/core",
            "location_service",
            "verify_proximity",
            vector[tx::request(), tx::location_target(), tx::proof()],
            vector[],
        ),
    );
}
