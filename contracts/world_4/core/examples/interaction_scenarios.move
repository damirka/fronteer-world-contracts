#[allow(unused)]
module 0::interaction_scenarios;

use 101::inventory;
use core::{action, entity, item, requirement as req};
use std::unit_test::destroy;

const FUEL_TYPE_ID: u64 = 0;
const TICKET_TYPE_ID: u64 = 1;

#[test]
fun install_a_module_try_it() {
    let ctx = &mut tx_context::dummy();
    let mut e = entity::new(ctx);

    // I install Inventory and call it storage unit
    let r = e.install("storage unit (01)", inventory::new(ctx), ctx);

    e.complete_request(r); // empty request for now

    // I explicitly expose FUEL deposit action for this Inventory
    let r = e.enable_action(
        "deposit to SU-01",
        action::new(vector[
            // just this, no other params
            // need to figure out how to assign module ID
            // outside of the module / behavior code
            inventory::deposit_requirement(
                "storage unit (01)",
                option::some(FUEL_TYPE_ID), // type_id
                option::none(), // min_quantity
                option::none(), // max_quantity
            ),
        ]),
        ctx,
    );

    e.complete_request(r); // empty request for now

    // I test this action by interacting with an assembly.
    // The interaction path forces certain order of certain modules.
    let mut r = e.interact("deposit to SU-01", ctx);

    // Stash 100 of FUEL in the SU.
    inventory::deposit(&mut e, &mut r, item::new(FUEL_TYPE_ID, 100, ctx));

    e.complete_request(r);

    // ==== Going further! ===

    // I addition to that, I add an exchange action.
    // Since I have a container for fuel
    let r = e.enable_action(
        "exchange tickets for fuel 1:1",
        action::new(vector[
            inventory::deposit_requirement(
                "storage unit (01)",
                option::some(TICKET_TYPE_ID), // type_id
                option::some(1), // min_quantity
                option::some(1), // max_quantity
            ),
            inventory::withdraw_requirement(
                "storage unit (01)",
                option::some(FUEL_TYPE_ID), // type_id
                option::none(), // min_quantity - we're accepting donations :)
                option::some(1), // max_quantity
            ),
            // NOTE: leftover from a conversation, but we can imagine that
            //       someone says "this action can only be performed if you're
            //       standing next to X", extra location gating opportunity for
            //       custom actions.
            // location_service::proximity_requirement(
            //     x"CAFFEE",
            // )
        ]),
        ctx,
    );

    e.complete_request(r); // empty request for now

    // Let's try it out!
    let mut r = e.interact("exchange tickets for fuel 1:1", ctx);

    // Deposit 1 of TICKET
    inventory::deposit(&mut e, &mut r, item::new(TICKET_TYPE_ID, 1, ctx));

    // Withdraw 1 of FUEL
    let fuel = inventory::withdraw(&mut e, &mut r, FUEL_TYPE_ID, 1, ctx);

    e.complete_request(r);

    destroy(fuel); // the one we exchanged
    destroy(e);
}

#[mode(test)]
fun ptb_template() {
    use core::transaction as tx;
    use ptb::ptb;

    let action = action::new(vector[
        inventory::deposit_requirement(
            "storage unit (01)",
            option::some(TICKET_TYPE_ID), // type_id
            option::some(1), // min_quantity
            option::some(1), // max_quantity
        ),
        inventory::withdraw_requirement(
            "storage unit (01)",
            option::some(FUEL_TYPE_ID), // type_id
            option::none(), // min_quantity - we're accepting donations :)
            option::some(1), // max_quantity
        ),
    ]);


}
