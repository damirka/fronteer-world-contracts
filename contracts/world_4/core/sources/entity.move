#[allow(unused)]
module core::entity;

use core::{action::Action, mod::{Self, Module}, request::{Self, Request}};
use std::string::String;
use sui::{dynamic_field as df, vec_map::{Self, VecMap}};

const VERSION: u64 = 1;
const STRUCTURE_TYPE_ID: u16 = 0;

public struct ModuleKey(String) has copy, drop, store;
public struct ActionsKey() has copy, drop, store;
public struct InFlight() has copy, drop, store;

public struct Entity has key {
    id: UID,
    count: u64,
    version: u64,
    type_id: u16,
    // df: ActionsKey() => VecMap<String, Action>,
    // df: ModuleKey(String) => Module<T>,
}

/* how do we version this function? pure ACL? */
public fun new(ctx: &mut TxContext /* TODO: ACL */): /* TODO: ACL */ Entity {
    let mut e = Entity {
        id: object::new(ctx),
        count: 0,
        version: VERSION,
        type_id: STRUCTURE_TYPE_ID,
    };

    e.add(ActionsKey(), vec_map::empty<String, Action>());
    e
}

/// Whether or not `T` is allowed to be installed is decided by the AdminACL
/// requirement. Hence, while the API is public, it's impossible to call this
/// function without resolving its spawned requirements.
///
/// System approval makes sure that `T` is one of the approved modules.
public fun install<T: store>(
    e: &mut Entity,
    /* TODO: OwnerCap */
    name: String,
    inner: T,
    ctx: &mut TxContext,
): Request {
    assert!(e.version == VERSION /* TODO: Code */);

    let mod = mod::new(name, inner, ctx);

    e.add(InFlight(), true);
    e.add(ModuleKey(name), mod);

    request::new(
        option::some(e.id.to_inner()),
        vector[], // TODO: ACL
    )
}

// Note to self: we can take T for upgradeability; something that `@potatoes/identify` can do.
public fun expose<A: store + drop>(
    e: &mut Entity,
    /* TODO: OwnerCap */
    name: String,
    action: A,
    ctx: &mut TxContext,
): Request {
    assert!(e.version == VERSION /* TODO: Code */);

    e.add(InFlight(), true);

    // eye now, how did we get here
    let action: Action = { e.add(true, action); e.remove(true) };
    let actions = e.borrow_mut<_, VecMap<_, _>>(ActionsKey());
    actions.insert(name, action);

    request::new(
        option::some(e.id.to_inner()),
        vector[], // TODO: ACL
    )
}

/// Interact with an `Entity` through a registered action.
public fun interact(e: &mut Entity, action: String, ctx: &mut TxContext): Request {
    assert!(e.version == VERSION /* TODO: Code */);

    e.add(InFlight(), true);

    let actions = e.borrow<_, VecMap<_, Action>>(ActionsKey());
    assert!(actions.contains(&action));
    let action = actions.get(&action);

    action.to_request(option::some(e.id.to_inner()))
}

/// Mutable access to the module is only allowed during interaction.
/// Requires:
/// - Request links to `structure_id`
/// - Request's next requirement's name == module name
public fun module_mut<T: store>(
    e: &mut Entity,
    req: &Request,
    _: internal::Permit<T>,
): &mut Module<T> {
    assert!(e.version == VERSION /* TODO: Code */);
    assert!(e.exists(InFlight()) /* TODO: Code */);
    assert!(req.structure_id().is_some_and!(|id| id == e.id.to_inner()) /* TODO: Code */);

    let name = req.next().module_name().destroy_or!(abort /* TODO: Code */);
    &mut e[ModuleKey(name)]
}

public fun complete_request(e: &mut Entity, req: Request) {
    e.remove<_, bool>(InFlight()); // no longer in flight
    req
        .structure_id()
        .is_some_and!(|id| { assert!(id == e.id.to_inner() /* TODO: Code */); false });
    req.complete()
}

/// Allows for configuration before sharing.
public fun share(e: Entity) {
    transfer::share_object(e);
}

// === Bag Implementation ===

fun exists<K: copy + drop + store>(e: &Entity, key: K): bool {
    df::exists(&e.id, key)
}

fun add<K: copy + drop + store, T: store>(e: &mut Entity, key: K, value: T) {
    assert!(!df::exists(&e.id, key) /* TODO: Code */);
    e.count = e.count + 1;
    df::add(&mut e.id, key, value)
}

fun remove<K: copy + drop + store, T: store>(e: &mut Entity, key: K): T {
    assert!(df::exists_with_type<_, T>(&e.id, key) /* TODO: Code */);
    e.count = e.count - 1;
    df::remove(&mut e.id, key)
}

#[syntax(index)]
fun borrow<K: copy + drop + store, T: store>(e: &Entity, key: K): &T {
    assert!(df::exists_with_type<_, T>(&e.id, key) /* TODO: Code */);
    df::borrow(&e.id, key)
}

#[syntax(index)]
fun borrow_mut<K: copy + drop + store, T: store>(e: &mut Entity, key: K): &mut T {
    assert!(df::exists_with_type<_, T>(&e.id, key) /* TODO: Code */);
    df::borrow_mut(&mut e.id, key)
}
