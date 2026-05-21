module inventory::inventory;

use sui::bcs;

use world::item::{Item, ItemBag};
use world::module_::Module;
use world::request;
use world::structure::Request;
use ptb::ptb;

public struct Inventory has store {
    unused: u64,
    items: ItemBag,
}

// TODO Behaviour versioning

public struct Withdrawal() has copy, drop, store;
public struct Deposit has copy, drop, store {
    type_id: Option<u64>,
    min_quantity: Option<u64>,
    max_quantity: Option<u64>,
}


public fun deposit(
    request: &mut Request,
    module_: &mut Module<Inventory>,
    item: Item,
) {
    let (req, frame) = request.satisfy_on_module<Inventory, Deposit>(
        module_,
        internal::permit()
    );

    let mut bcs = bcs::new(req.data());
    let deposit = Deposit {
        type_id: bcs.peel_option!(|b| b.peel_u64()),
        min_quantity: bcs.peel_option!(|b| b.peel_u64()),
        max_quantity: bcs.peel_option!(|b| b.peel_u64()),
    };

    assert!(deposit.type_id.is_none_or!(|id| id == item.type_id()));
    assert!(deposit.min_quantity.is_none_or!(|q| *q <= item.quantity()));
    assert!(deposit.max_quantity.is_none_or!(|q| *q >= item.quantity()));

    let inventory = module_.inner_mut(internal::permit());
    assert!(inventory.unused >= item.quantity());
    inventory.unused = inventory.unused - item.quantity();
    inventory.items.deposit(item);

    // TODO: Provenance of `item` (prevent callers from teleporting items by
    // starting concurrent requests in distinct structures and swapping items
    // at a distance)

    // TODO: Offer `satisfy` variants that don't supply a frame to push further
    // requirements into?
    request.enqueue(frame);
}

public fun withdraw(
    request: &mut Request,
    module_: &mut Module<Inventory>,
    type_id: u64,
    quantity: u64,
    ctx: &mut TxContext,
): Item {
    let inventory = module_.inner_mut(internal::permit());
    let item = inventory.items.withdraw(type_id, quantity, ctx);
    inventory.unused = inventory.unused + item.quantity();

    let (_, frame) = request.satisfy_on_module<Inventory, Withdrawal>(
        module_,
        internal::permit()
    );

    // TODO: Provenance of `item` (prevent callers from teleporting items by
    // starting concurrent requests in distinct structures and swapping items
    // at a distance)

    request.enqueue(frame);
    item
}

// === PTB Templates ===

public fun deposit_template(
    ptb: &mut ptb::Transaction,
    mut args: vector<ptb::Argument>,
): vector<ptb::Argument> {
    assert!(args.length() == 1);
    let item = args.pop_back();

    ptb.command(ptb::move_call(
        "mvr:@frontier/inventory",
        "inventory",
        "deposit",
        vector[
          request::request(),
          request::module_(),
          item,
        ],
        vector[],
    ));

    vector[]
}

public fun withdraw_template(
    ptb: &mut ptb::Transaction,
    mut args: vector<ptb::Argument>,
): vector<ptb::Argument> {
    assert!(args.length() == 2);
    let quantity = args.pop_back();
    let type_id = args.pop_back();

    let item = ptb.command(ptb::move_call(
        "mvr:@frontier/inventory",
        "inventory",
        "withdraw",
        vector[
          request::request(),
          request::module_(),
          type_id,
          quantity,
        ],
        vector[],
    ));

    vector[item]
}
