module world::liveness_service;

use format::format::format;
use ptb::ptb;
use std::type_name;
use world::{
    assembly::Assembly,
    network_node::NetworkNode,
    request::ApplicationRequest,
    requirement::{Self, Requirement}
};

/// The requirement of connection to the
public struct NodeIsOnline has store {}

/// Construct a requirement for a certain item type and its minimum quantity.
public fun requirement(): Requirement {
    requirement::new<NodeIsOnline>(vector[])
}

public fun verify_liveness(request: &mut ApplicationRequest, node: &NetworkNode) {
    assert!(node.is_online());
    assert!(request.assembly_id().is_some_and!(|id| node.connected_assemblies().contains(id)));

    request.complete_requirement<NodeIsOnline>(internal::permit());
}

#[allow(unused_function)]
fun ptb_template(assembly: &Assembly): ptb::Command {
    let package_id = *type_name::with_defining_ids<NodeIsOnline>().as_string();
    let _ = assembly.requirement_with_type<NodeIsOnline>().destroy_or!(abort);

    ptb::move_call(
        package_id.to_string(),
        "network_node",
        "verify_liveness",
        vector[
            ptb::ext_input("request"),
            ptb::ext_input(
                format("node({})", vector[object::id(assembly).to_address().to_string()]),
            ),
        ],
        vector[],
    )
}

#[test_only]
public fun ptb_template_for_testing(assembly: &Assembly): ptb::Command {
    ptb_template(assembly)
}
