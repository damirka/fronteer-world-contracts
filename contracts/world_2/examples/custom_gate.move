/// Uses world components to implement a custom gate functionality.
module world::custom_gate;

use std::unit_test;
use sui::test_scenario as ts;
use world::{assembly::Assembly, gate, inventory_service, item, location_service, system_service};
use format::format::dbg;

const ITEM_TYPE_ID: u64 = 1;
const ITEM_QUANTITY: u32 = 1;

#[test]
fun custom_gate_scenario() {
    let mut test = ts::begin(@0);

    // Alice:
    // - create a gate assembly
    // - confirm creation with the system service
    // - configure the gate to require a certain item
    test.tx!(@0xa11ce, |test| {
        let (mut assembly, owner_cap, mut request) = gate::new(vector[0, 1, 2, 4], test.ctx());

        // For visibility!
        // std::debug::print(&request);

        // Confirm the request with the system service.
        system_service::confirm_for_testing(&mut request);
        request.complete();

        // std::debug::print(&system_service::ptb_template_for_testing());

        // Configure the gate to require a certain item.
        let item_requirement = inventory_service::requirement(ITEM_TYPE_ID, ITEM_QUANTITY);
        gate::add_requirement(&mut assembly, &owner_cap, item_requirement);
        transfer::public_transfer(owner_cap, test.ctx().sender());

        // Share the assembly (the only allowed storage action).
        assembly.share();
    });

    // Bob:
    // - interact with the gate assembly owned by Alice
    // - show the item to confirm possession
    // - confirm proximity through location service
    test.tx!(@0xb0b, |test| test.with_shared!<Assembly>(|assembly, test| {
        let item = item::new(ITEM_TYPE_ID, ITEM_QUANTITY, test.ctx());
        let mut request = gate::jump(assembly);

        // For visibility!
        std::debug::print(&request);

        location_service::verify_proximity(&mut request, vector[0, 1, 2, 4]);
        inventory_service::verify_possession(&mut request, &item);

        std::debug::print(&location_service::ptb_template_for_testing());
        std::debug::print(&inventory_service::ptb_template_for_testing(assembly));

        request.complete();

        // No need to store a test item.
        unit_test::destroy(item);
    }));

    test.end();
}
