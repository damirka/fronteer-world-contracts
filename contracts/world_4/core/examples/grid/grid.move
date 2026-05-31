#[allow(unused)]
module 333::grid;

use core::{entity::Entity, request::Request};
use std::string::String;

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
