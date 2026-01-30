module world::inventory_service;

use format::format::format;
use ptb::ptb;
use std::type_name;
use sui::bcs;
use world::{
    assembly::Assembly,
    item::Item,
    request::ApplicationRequest,
    requirement::{Self, Requirement}
};

public struct HasItemQuantity has drop { type_id: u64, min_quantity: u32 }

/// Construct a requirement for a certain item type and its minimum quantity.
public fun requirement(type_id: u64, min_quantity: u32): Requirement {
    requirement::new<HasItemQuantity>(
        bcs::to_bytes(&HasItemQuantity { type_id, min_quantity }),
    )
}

/// Verify that the request has the required item in possession.
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

#[allow(unused_function)]
fun ptb_template(assembly: &Assembly): ptb::Command {
    let package_id = *type_name::with_defining_ids<HasItemQuantity>().as_string();
    let requirement = assembly.requirement_with_type<HasItemQuantity>().destroy_or!(abort);
    let (type_id, min_quantity) = from_bytes(requirement.data());

    let mut ptb = ptb::new();
    let result = ptb.command(ptb::move_call(
        package_id.to_string(),
        "inventory_service",
        "verify_possession",
        vector[
            ptb::ext_input("request"),
            ptb::ext_input(
                format("item({};{})", vector[type_id.to_string(), min_quantity.to_string()]),
            ),
        ],
        vector[],
    ));

    ptb.command(ptb::move_call(
        package_id.to_string(),
        "inventory_service",
        "show_proof_of_deposit",
        vector[
            result,
        ],
        vector[],
    ))

    abort
}

#[test_only]
public fun ptb_template_for_testing(assembly: &Assembly): ptb::Command {
    ptb_template(assembly)
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
