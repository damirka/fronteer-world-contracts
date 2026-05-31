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

public(package) fun to_request(action: &Action, entity_id: Option<ID>): Request {
    request::new(entity_id, action.requirements.map_ref!(|r| r.clone()))
}
