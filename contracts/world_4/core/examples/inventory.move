module 101::inventory;

use core::{
    entity::Entity,
    item::{Self, Item, ItemBag},
    request::Request,
    requirement::{Self, Requirement}
};
use std::string::String;

// use ptb::ptb;

public struct Withdrawal() has drop;
public struct Deposit() has drop;

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

public fun deposit_requirement(mod: String): Requirement {
    requirement::from_config(option::some(mod), Deposit())
}

public fun withdraw_requirement(mod: String): Requirement {
    requirement::from_config(option::some(mod), Withdrawal())
}

// // TODO Behaviour versioning

public fun deposit(e: &mut Entity, request: &mut Request, item: Item) {
    let inventory = e.module_mut<Inventory>(request, internal::permit()).inner_mut();
    let _requirement = request.satisfy(internal::permit<Deposit>());
    inventory.items.deposit(item);
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

// public fun withdraw(
//     request: &mut Request,
//     module_: &mut Module<Inventory>,
//     type_id: u64,
//     quantity: u64,
//     ctx: &mut TxContext,
// ): Item {
//     let inventory = module_.inner_mut(internal::permit());
//     let item = inventory.items.withdraw(type_id, quantity, ctx);
//     inventory.unused = inventory.unused + item.quantity();

//     let (_, frame) = request.satisfy_on_module<Inventory, Withdrawal>(
//         module_,
//         internal::permit(),
//     );

//     // TODO: Provenance of `item` (prevent callers from teleporting items by
//     // starting concurrent requests in distinct structures and swapping items
//     // at a distance)

//     request.enqueue(frame);
//     item
// }

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
