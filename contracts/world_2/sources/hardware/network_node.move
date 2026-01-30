module world::network_node;

public struct NetworkNode has key {
    id: UID,
    is_online: bool,
    connected_assemblies: vector<ID>,
}

#[allow(unused_function)]
fun new(ctx: &mut TxContext) {
    transfer::share_object(NetworkNode {
        id: object::new(ctx),
        is_online: false,
        connected_assemblies: vector[],
    })
}

public fun connected_assemblies(node: &NetworkNode): vector<ID> {
    node.connected_assemblies
}

public fun is_online(node: &NetworkNode): bool {
    node.is_online
}
