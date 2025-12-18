module world::inventory_service;

use sui::bcs;
use world::{request::ApplicationRequest, requirement::{Self, Requirement}};

// Mockup
public struct Item has key, store {
    id: UID,
    type_id: u64,
    quantity: u32,
}

public struct HasItemQuantity has drop { type_id: u64, min_quantity: u32 }

/// Construct a requirement for a certain item type and its minimum quantity.
public fun requirement(type_id: u64, min_quantity: u32): Requirement {
    requirement::new<HasItemQuantity>(
        bcs::to_bytes(&HasItemQuantity { type_id, min_quantity }),
    )
}

/// 
public fun complete_requirement(request: &mut ApplicationRequest, item: &Item) {
    let requirement = request.complete_requirement<HasItemQuantity>(internal::permit());
    let (type_id, min_quantity) = from_bytes(requirement.data());

    assert!(type_id == item.type_id);
    assert!(min_quantity <= item.quantity);
}

fun from_bytes(bytes: vector<u8>): (u64, u32) {
    let mut bcs = bcs::new(bytes);
    (bcs.peel_u64(), bcs.peel_u32())
}
