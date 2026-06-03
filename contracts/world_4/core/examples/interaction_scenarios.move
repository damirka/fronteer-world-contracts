#[allow(unused)]
module 0::interaction_scenarios;

use 101::inventory;
use core::{
    action,
    entity,
    item,
    location_service,
    owner_service::{Self, verify_owner_cap_template},
    requirement as req
};
use std::unit_test::destroy;

const FUEL_TYPE_ID: u64 = 0;
const TICKET_TYPE_ID: u64 = 1;

#[test]
fun install_a_module_try_it() {
    let ctx = &mut tx_context::dummy();
    let mut e = entity::new(ctx); // TODO: Admin ACL

    // === PTB: Install Tx ===

    // I install Inventory and call it storage unit
    // BEFORE: let r = e.install("SU-01", inventory::new(ctx), ctx);
    let mut r = inventory::install(&mut e, "SU-01", ctx);

    owner_service::verify_owner_cap(&mut r /* TODO: OwnerCap */);

    e.complete_request(r); // empty request for now

    // === PTB: Enable Action ===

    // I explicitly expose FUEL deposit action for this Inventory
    let mut r = e.enable_action(
        "deposit to SU-01",
        action::new(vector[
            // just this, no other params
            // need to figure out how to assign module ID
            // outside of the module / behavior code
            inventory::deposit_requirement(
                "SU-01",
                option::some(FUEL_TYPE_ID), // type_id
                option::none(), // min_quantity
                option::none(), // max_quantity
            ),
        ]),
        ctx,
    );

    owner_service::verify_owner_cap(&mut r /* TODO: OwnerCap */);

    e.complete_request(r); // empty request for now

    // === PTB: Interact with SU-01 ===

    // I test this action by interacting with an assembly.
    // The interaction path forces certain order of certain modules.
    let mut r = e.interact("deposit to SU-01", ctx);

    // Interact always comes with proximity requirement.
    location_service::verify_proximity_proof(&mut r, "location_hash", "proof");

    // Stash 100 of FUEL in the SU.
    inventory::deposit(&mut e, &mut r, item::new(FUEL_TYPE_ID, 100, ctx));

    e.complete_request(r);

    // ==== PTB: Enable complex combination Action ===

    // I addition to that, I add an exchange action.
    // Since I have a container for fuel
    let mut r = e.enable_action(
        "exchange tickets for fuel 1:1",
        action::new(vector[
            inventory::deposit_requirement(
                "SU-01",
                option::some(TICKET_TYPE_ID), // type_id
                option::some(1), // min_quantity
                option::some(1), // max_quantity
            ),
            inventory::withdraw_requirement(
                "SU-01",
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

    owner_service::verify_owner_cap(&mut r /* TODO: OwnerCap */);

    e.complete_request(r); // empty request for now

    // === PTB: test combined action ===

    // Let's try it out!
    let mut r = e.interact("exchange tickets for fuel 1:1", ctx);

    // always proximity first!
    location_service::verify_proximity_proof(&mut r, "location_hash", "proof");

    // Deposit 1 of TICKET
    inventory::deposit(&mut e, &mut r, item::new(TICKET_TYPE_ID, 1, ctx));

    // Withdraw 1 of FUEL
    let fuel = inventory::withdraw(&mut e, &mut r, FUEL_TYPE_ID, 1, ctx);

    e.complete_request(r);

    // === Cleanup ===

    destroy(fuel); // the one we exchanged
    destroy(e);
}

#[mode(test)]
use ptb::ptb;

#[mode(test)]
fun ptb_template(): ptb::Transaction {
    use core::transaction as tx;

    let action = action::new(vector[
        owner_service::requirement(@0.to_id()), // only owner of this entity can
        inventory::deposit_requirement(
            "SU-01",
            option::some(TICKET_TYPE_ID), // type_id
            option::some(1), // min_quantity
            option::some(1), // max_quantity
        ),
        inventory::withdraw_requirement(
            "SU-01",
            option::some(FUEL_TYPE_ID), // type_id
            option::none(), // min_quantity - we're accepting donations :)
            option::some(1), // max_quantity
        ),
    ]);

    // PTB Construction, the most interesting part!

    let mut tx = ptb::new();

    location_service::verify_requirement_template(
        &action.requirements()[3], // reverse order
        &mut tx,
        vector[],
    );

    owner_service::verify_owner_cap_template(
        &action.requirements()[2],
        &mut tx,
        vector[],
    );

    inventory::deposit_template(
        &action.requirements()[1], // reverse order
        &mut tx,
        vector[tx::item(option::some(TICKET_TYPE_ID), option::some(1))],
    );

    // mind that `item` is instantiated as a `vector<Argument>`, not a single Argument
    let mut item = inventory::withdraw_template(
        &action.requirements()[0],
        &mut tx,
        vector[tx::item_type_id(FUEL_TYPE_ID), tx::item_quantity(1)],
    );

    tx.command(ptb::transfer_objects(vector[item.pop_back()], ptb::pure(@0)));

    tx
}
