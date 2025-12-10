/// This module defines the key type used to derive object IDs in world contracts
/// using game ID and tenant.
module world::game_id;

use std::string::String;

// === Structs ===
/// Represents a unique in-game identifier used to deterministically derive on-chain object IDs. 
public struct DerivationKey has copy, drop, store {
    item_id: u64,
    tenant: String,
}

// === View Functions ===
public fun item_id(key: &DerivationKey): u64 {
    key.item_id
}

public fun tenant(key: &DerivationKey): String {
    key.tenant
}

public(package) fun create_key(item_id: u64, tenant: String): DerivationKey {
    DerivationKey { item_id, tenant }
}
