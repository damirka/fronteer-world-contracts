module world::module_;

use std::string::String;

public struct Module<M> has store {
    structure: ID,
    name: String,
    inner: M,
}

public(package) fun new<M>(structure: ID, name: String, inner: M): Module<M> {
    Module {
        structure,
        name,
        inner,
    }
}

public fun structure<M>(module_: &Module<M>): ID {
    module_.structure
}

public fun name<M>(module_: &Module<M>): String {
    module_.name
}

public fun inner_mut<M>(module_: &mut Module<M>, _: internal::Permit<M>): &mut M {
    &mut module_.inner
}
