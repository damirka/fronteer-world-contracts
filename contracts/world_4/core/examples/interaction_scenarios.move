#[allow(unused)]
module 0::interaction_scenarios;

use 101::inventory;
use core::{action, entity, item, requirement as req};
use std::unit_test::destroy;

#[test]
fun install_a_module() {
    let ctx = &mut tx_context::dummy();
    let mut e = entity::new(ctx);

    // I install Inventory and call it storage unit
    let r = e.install("storage unit (01)", inventory::new(ctx), ctx);

    e.complete_request(r); // empty request for now

    // I explicitly expose default deposit action for this Inventory
    let r = e.expose(
        "deposit to SU-01",
        action::new(vector[
            // just this, no other params
            // need to figure out how to assign module ID
            // outside of the module / behavior code
            inventory::deposit_requirement("storage unit (01)"),
        ]),
        ctx,
    );

    e.complete_request(r); // empty request for now

    // I test this action by interacting with an assembly.
    // The interaction path forces certain order of certain modules.
    let mut r = e.interact("deposit to SU-01", ctx);

    inventory::deposit(&mut e, &mut r, item::new(0, 0, ctx));

    e.complete_request(r);
    destroy(e);
}
