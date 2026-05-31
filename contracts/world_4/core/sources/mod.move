/// Very simple wrapper for very simple things.
/// Adds versioning and name to module definitions.
/// NOTE: I think we can add magic like `extra_fields: Bag` or similar
/// NOTE: I wonder if there's a way to migrate this type, like we can do with Action
module core::mod;

use std::string::String;

public struct Module<T: store> has store {
    version: u64,
    inner: T,
    name: String,
}

/// Can only be called by Entity.
public(package) fun new<T: store>(
    name: String,
    inner: T,
    version: u64,
    _ctx: &mut TxContext,
): Module<T> {
    Module {
        name,
        inner,
        version,
    }
}

/// TODO: think about authorization guards on this function. It has to be public
///       (though, now that I think about it may be unwrapped in a different way?)
///       the reason we add explicit unwrap is to maintain version access... hmm
public fun unwrap<T: store>(m: Module<T>, _: internal::Permit<T>): T {
    let Module { inner, .. } = m;
    inner
}

public fun inner_mut<T: store>(m: &mut Module<T>): &mut T {
    &mut m.inner
}

public fun inner<T: store>(m: &Module<T>): &T {
    &m.inner
}

public fun version<T: store>(m: &Module<T>): u64 {
    m.version
}

public fun name<T: store>(m: &Module<T>): String {
    m.name
}
