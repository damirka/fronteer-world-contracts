module core::action;

use core::{request::{Self, Request}, requirement::Requirement};

const VERSION: u64 = 1;

public struct Action has drop, store {
    /// Requirements must be in order!
    requirements: vector<Requirement>,
    version: u64,
}

public fun new(requirements: vector<Requirement>): Action {
    Action { requirements, version: VERSION }
}

public(package) fun to_request(action: &Action, structure_id: Option<ID>): Request {
    request::new(structure_id, action.requirements.map_ref!(|r| r.clone()))
}
