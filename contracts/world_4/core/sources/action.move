module core::action;

use core::{request::{Self, Request}, requirement::Requirement};

const VERSION: u64 = 1;

public struct Action has drop, store {
    /// Requirements must be in order!
    requirements: vector<Requirement>,
    version: u64,
}

public fun new(mut requirements: vector<Requirement>): Action {
    requirements.reverse(); // declaration order
    Action { requirements, version: VERSION }
}

/// Convert an `Action` to a `Request` with `pre_requirements` added before
/// Action's requirements.
public(package) fun to_request(
    action: &Action,
    entity_id: Option<ID>,
    pre_requirements: vector<Requirement>,
): Request {
    let mut requirements = action.requirements.map_ref!(|r| r.clone());
    pre_requirements.do!(|r| requirements.push_back(r));

    // NOTE: ^ above is to maintain declaration and resolution order correctly
    //       we declare in order, but resolve in reverse.

    request::new(entity_id, requirements)
}

#[mode(test)]
public fun requirements(a: &Action): &vector<Requirement> {
    &a.requirements
}
