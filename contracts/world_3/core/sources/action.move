module world::action;

use world::structure::Frame;
use world::requirement::Requirement;

// TODO: Registering behaviours to Actions
// TODO: Registering custom requirements to Actions

public struct Action has store {
    requirements: vector<Requirement>,
}

public fun requirements(action: &Action): &vector<Requirement> {
    &action.requirements
}
