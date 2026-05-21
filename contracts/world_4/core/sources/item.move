/// As-is port from World 3.
module core::item;

use sui::table::{Self, Table};

public struct Item has key, store {
    id: UID,
    type_id: u64,
    quantity: u64,
}

public struct ItemBag(Table<u64, u64>) has store;

#[error(code = 1)]
const ENoSuchType: vector<u8> = b"No such item in bag";

#[error(code = 2)]
const ENotEnough: vector<u8> = b"Not enough of item in bag";

public fun new_bag(ctx: &mut TxContext): ItemBag {
    ItemBag(table::new(ctx))
}

public fun new(type_id: u64, quantity: u64, ctx: &mut TxContext): Item {
    Item {
        id: object::new(ctx),
        type_id,
        quantity,
    }
}

public fun deposit(bag: &mut ItemBag, item: Item) {
    let Item { id, type_id, quantity } = item;
    id.delete();

    if (bag.0.contains(type_id)) {
        let available = &mut bag.0[type_id];
        *available = *available + quantity;
    } else {
        bag.0.add(type_id, quantity);
    }
}

public fun withdraw(bag: &mut ItemBag, type_id: u64, quantity: u64, ctx: &mut TxContext): Item {
    assert!(bag.0.contains(type_id), ENoSuchType);

    let available = &mut bag.0[type_id];
    assert!(*available >= quantity, ENotEnough);
    *available = *available - quantity;

    if (*available == 0) {
        bag.0.remove(type_id);
    };

    Item {
        id: object::new(ctx),
        type_id,
        quantity,
    }
}

public fun split(item: &mut Item, quantity: u64, ctx: &mut TxContext): Item {
    assert!(item.quantity >= quantity);

    let new_item = Item {
        id: object::new(ctx),
        type_id: item.type_id,
        quantity,
    };

    item.quantity = item.quantity - quantity;
    new_item
}

public fun merge(item: &mut Item, another: Item) {
    let Item { id, type_id, quantity } = another;

    assert!(item.type_id == type_id);

    item.quantity = item.quantity + quantity;
    id.delete();
}

public fun destroy_zero(item: Item) {
    assert!(item.quantity == 0);
    let Item { id, .. } = item;
    id.delete();
}

public fun type_id(item: &Item): u64 {
    item.type_id
}

public fun quantity(item: &Item): u64 {
    item.quantity
}
