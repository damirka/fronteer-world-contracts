/// Mockup for the item type.
module world::item;

public struct Item has key, store {
    id: UID,
    type_id: u64,
    quantity: u32,
}

public fun new(type_id: u64, quantity: u32, ctx: &mut TxContext): Item {
    Item {
        id: object::new(ctx),
        type_id,
        quantity,
    }
}

public fun split(item: &mut Item, quantity: u32, ctx: &mut TxContext): Item {
    assert!(item.quantity() >= quantity);
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

    assert!(item.type_id() == type_id);

    item.quantity = item.quantity() + quantity;
    id.delete();
}

public fun destroy_zero(item: Item) {
    assert!(item.quantity() == 0);
    let Item { id, .. } = item;
    id.delete();
}

public fun type_id(item: &Item): u64 {
    item.type_id
}

public fun quantity(item: &Item): u32 {
    item.quantity
}
