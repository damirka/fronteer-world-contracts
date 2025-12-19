module world::storage_unit;

use sui::bag::{Self, Bag};
use world::{assembly::{Self, Assembly}, item::Item, location_service, request::ApplicationRequest};

public struct StorageUnit has store {
    items: Bag,
}

/// Create a new Storage Unit assembly.
public fun new(location_hash: vector<u8>, ctx: &mut TxContext): (Assembly, ApplicationRequest) {
    let storage_unit = StorageUnit { items: bag::new(ctx) };
    let (assembly, request) = assembly::new(
        storage_unit,
        location_hash,
        b"StorageUnit".to_string(),
        vector[location_service::requirement(location_hash)],
        ctx,
    );

    (assembly, request)
}

/// Store an item in the Storage Unit.
public fun store_item(assembly: &mut Assembly, item: Item): ApplicationRequest {
    assembly.inner_mut(internal::permit<StorageUnit>()).items.add(item.type_id(), item);
    assembly.interact(b"storage_unit:store_item".to_string(), internal::permit<StorageUnit>())
}

#[allow(unused_variable)]
/// Retrieve an item from the Storage Unit.
public fun retrieve_item(assembly: &mut Assembly, type_id: u64, quantity: u32): (Item, ApplicationRequest) {
    let request = assembly.interact(b"storage_unit:retrieve_item".to_string(), internal::permit<StorageUnit>());
    abort
}
