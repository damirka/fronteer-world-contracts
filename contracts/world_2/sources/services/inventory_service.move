module world::inventory_service;

use sui::bcs;
use world::{item::Item, request::ApplicationRequest, requirement::{Self, Requirement}};

public struct HasItemQuantity has drop { type_id: u64, min_quantity: u32 }

/// Construct a requirement for a certain item type and its minimum quantity.
public fun requirement(type_id: u64, min_quantity: u32): Requirement {
    requirement::new<HasItemQuantity>(
        bcs::to_bytes(&HasItemQuantity { type_id, min_quantity }),
    )
}

///
public fun verify_possession(request: &mut ApplicationRequest, item: &Item) {
    let requirement = request.complete_requirement<HasItemQuantity>(internal::permit());
    let (type_id, min_quantity) = from_bytes(requirement.data());

    assert!(type_id == item.type_id());
    assert!(min_quantity <= item.quantity());
}

fun from_bytes(bytes: vector<u8>): (u64, u32) {
    let mut bcs = bcs::new(bytes);
    (bcs.peel_u64(), bcs.peel_u32())
}

// Thoughts on conventions for services:
// - standard `requirement` function which returns a `Requirement` instance,
// however, arguments to it are not standardized, so it's purely for discovery
// - standard `complete_requirement` function which completes a requirement.
// again, due to variation in the context of the requirement, the arguments can
// not be standardized;
//
// Other ways to approach this:
// - PTB mock ups on-chain which guide off-chain PTB building, eg:
//   * pass in this object as first argument always
//   * argument 2 is a location hash
//   * arguments 3, 4 are item properties
// - perhaps, there can be a standard way of describing arguments for functions,
// there's only so many properties in the game, so it's not an impossible task
// to create an off-chain standard for argument descriptions
// - PTB (with unresolved versions) could be constructed as a dry run as well
