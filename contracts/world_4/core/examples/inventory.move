module 101::inventory;

use core::{
    entity::Entity,
    item::{Self, Item, ItemBag},
    request::Request,
    requirement::{Self, Requirement}
};
use std::string::String;
use sui::bcs;

// use ptb::ptb;

public struct ItemRequirement has drop {
    type_id: Option<u64>,
    min_quantity: Option<u64>,
    max_quantity: Option<u64>,
}

public struct Withdrawal(ItemRequirement) has drop;
public struct Deposit(ItemRequirement) has drop;

public struct Inventory has store {
    unused: u64,
    items: ItemBag,
}

public fun new(/* TODO: Auth */ ctx: &mut TxContext): Inventory {
    Inventory {
        unused: 100,
        items: item::new_bag(ctx),
    }
}

// NOTE: Ashok, I don't like that name is not enforced. Maybe there's a better way?
//       maybe we can spawn requirements for modules FROM modules? Inner() or something?
public fun deposit_requirement(
    mod: String,
    type_id: Option<u64>,
    min_quantity: Option<u64>,
    max_quantity: Option<u64>,
): Requirement {
    requirement::from_config(
        option::some(mod),
        Deposit(ItemRequirement {
            type_id,
            min_quantity,
            max_quantity,
        }),
    )
}

// NOTE: ditto
public fun withdraw_requirement(
    mod: String,
    type_id: Option<u64>,
    min_quantity: Option<u64>,
    max_quantity: Option<u64>,
): Requirement {
    requirement::from_config(
        option::some(mod),
        Withdrawal(ItemRequirement {
            type_id,
            min_quantity,
            max_quantity,
        }),
    )
}
// TODO Behaviour versioning

public fun deposit(e: &mut Entity, request: &mut Request, item: Item) {
    let inventory = e.module_mut<Inventory>(request, internal::permit()).inner_mut();
    let (requirement, frame) = request.satisfy(internal::permit<Deposit>());

    // Enforce extra  if there are any.
    let item_req = parse_bcs_requirement(requirement.data());
    item_req.type_id.do!(|type_id| assert!(item.type_id() == type_id));
    item_req.min_quantity.do!(|min_quantity| assert!(item.quantity() >= min_quantity));
    item_req.max_quantity.do!(|max_quantity| assert!(item.quantity() <= max_quantity));

    // NOTE: Oh, Ashok, you also considered not getting a Frame here. Good!
    request.enqueue(frame);
    inventory.items.deposit(item);
}

fun parse_bcs_requirement(bytes: vector<u8>): ItemRequirement {
    let mut bcs = bcs::new(bytes);
    ItemRequirement {
        type_id: bcs.peel_option!(|bcs| bcs.peel_u64()),
        min_quantity: bcs.peel_option!(|bcs| bcs.peel_u64()),
        max_quantity: bcs.peel_option!(|bcs| bcs.peel_u64()),
    }
}

//     let inventory = module_.inner_mut(internal::permit());

//     assert!(inventory.unused >= item.quantity());
//     inventory.unused = inventory.unused - item.quantity();
//     inventory.items.deposit(item);

//     let (_, frame) = request.satisfy_on_module<Inventory, Deposit>(
//         module_,
//         internal::permit(),
//     );

//     // TODO: Provenance of `item` (prevent callers from teleporting items by
//     // starting concurrent requests in distinct structures and swapping items
//     // at a distance)

//     // TODO: Offer `satisfy` variants that don't supply a frame to push further
//     // requirements into?
//     request.enqueue(frame);
// }

public fun withdraw(
    e: &mut Entity,
    request: &mut Request,
    type_id: u64,
    quantity: u64,
    ctx: &mut TxContext,
): Item {
    let inventory = e.module_mut<Inventory>(request, internal::permit()).inner_mut();
    let (requirement, frame) = request.satisfy(internal::permit<Withdrawal>());

    // enforce constraints
    let item_req = parse_bcs_requirement(requirement.data());
    item_req.type_id.do!(|c_type_id| assert!(type_id == c_type_id));
    item_req.min_quantity.do!(|min_quantity| assert!(quantity >= min_quantity));
    item_req.max_quantity.do!(|max_quantity| assert!(quantity <= max_quantity));

    // withdraw an item and update inventory
    let item = inventory.items.withdraw(type_id, quantity, ctx);
    inventory.unused = inventory.unused + item.quantity();

    // let (request, frame) = request.satisfy_on_module<Inventory, Withdrawal>(
    //     module_,
    //     internal::permit(),
    // );

    // TODO: Provenance of `item` (prevent callers from teleporting items by
    // starting concurrent requests in distinct structures and swapping items
    // at a distance)

    request.enqueue(frame);
    item
}

// // === PTB Templates ===

// public fun deposit_template(
//     ptb: &mut ptb::Transaction,
//     mut args: vector<ptb::Argument>,
// ): vector<ptb::Argument> {
//     assert!(args.length() == 1);
//     let item = args.pop_back();

//     ptb.command(
//         ptb::move_call(
//             "mvr:@frontier/inventory",
//             "inventory",
//             "deposit",
//             vector[request::request(), request::module_(), item],
//             vector[],
//         ),
//     );

//     vector[]
// }

// public fun withdraw_template(
//     ptb: &mut ptb::Transaction,
//     mut args: vector<ptb::Argument>,
// ): vector<ptb::Argument> {
//     assert!(args.length() == 2);
//     let quantity = args.pop_back();
//     let type_id = args.pop_back();

//     let item = ptb.command(
//         ptb::move_call(
//             "mvr:@frontier/inventory",
//             "inventory",
//             "withdraw",
//             vector[request::request(), request::module_(), type_id, quantity],
//             vector[],
//         ),
//     );

//     vector[item]
// }
