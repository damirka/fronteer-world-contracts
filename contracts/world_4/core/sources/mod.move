module core::mod;

use std::string::String;

const VERSION: u64 = 1;

public struct Module<T: store> has store {
    version: u64,
    inner: T,
    name: String,
}

public(package) fun new<T: store>(name: String, inner: T, _ctx: &mut TxContext): Module<T> {
    Module {
        name,
        inner,
        version: VERSION,
    }
}

public fun inner_mut<T: store>(m: &mut Module<T>): &mut T { &mut m.inner }

public fun inner<T: store>(m: &Module<T>): &T { &m.inner }

public fun name<T: store>(m: &Module<T>): String {
    m.name
}
