#[allow(unused)]
module 333::grid;

use core::{entity::Entity, request::Request};
use std::{string::String, type_name::{Self, TypeName}};
use sui::table::{Self, Table};

const VERSION: u64 = 1;

public struct Grid has store {
    power_supply: u32,
    used_power: u32,
}

/// NOTE: unlike inventory, this module can be installed only once!
public fun install(e: &mut Entity, ctx: &mut TxContext): Request {
    e.install(
        "grid", // here it is! key is not configurable!
        Grid { power_supply: 0, used_power: 0 },
        VERSION,
        internal::permit(),
        ctx,
    )
}



// === Grid Components Table ===

/// Stores links between modules and their power requirements.
/// Attempt to avoid congestion by only allowing reads except for 2 ops.
public struct PowerRequirements has key {
    id: UID,
    version: u64,
    table: Table<TypeName, PowerBehavior>,
}

///
public struct PowerManagerCap has key, store {
    id: UID,
    // TODO: version? for scenario when Cap is compromised?
}

///
public enum PowerBehavior has copy, drop, store {
    Consume(u32),
    Produce(u32),
    Other(vector<u8>),
}

public fun add_power_consumer<T: store>(
    pr: &mut PowerRequirements,
    cap: &mut PowerManagerCap,
    value: u32,
    ctx: &mut TxContext,
) {
    pr.table.add(type_name::with_defining_ids<T>(), PowerBehavior::Consume(value))
}

public fun add_power_producer<T: store>(
    pr: &mut PowerRequirements,
    cap: &mut PowerManagerCap,
    value: u32,
    ctx: &mut TxContext,
) {
    pr.table.add(type_name::with_defining_ids<T>(), PowerBehavior::Produce(value))
}

/// Public read for power requirement for `T`.
public fun power<T: store>(pr: &PowerRequirements): PowerBehavior {
    pr.table[type_name::with_defining_ids<T>()]
}

public fun is_consume(pb: &PowerBehavior): bool {
    match (pb) {
        PowerBehavior::Consume(..) => true,
        _ => false,
    }
}

public fun is_produce(pb: &PowerBehavior): bool {
    match (pb) {
        PowerBehavior::Produce(..) => true,
        _ => false,
    }
}

public fun inner(pb: &PowerBehavior): u32 {
    match (pb) {
        PowerBehavior::Produce(value) => *value,
        PowerBehavior::Consume(value) => *value,
        _ => abort,
    }
}

// TODO: remove
// TODO: view

fun init(ctx: &mut TxContext) {
    transfer::share_object(PowerRequirements {
        id: object::new(ctx),
        table: table::new(ctx),
        version: VERSION,
    })
}
