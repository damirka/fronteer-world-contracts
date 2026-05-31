#[allow(unused)]
module core::entity;

use core::{action::Action, mod::{Self, Module}, request::{Self, Request}};
use std::{string::String, type_name};
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
    location_hash: vector<u8>,
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
        location_hash: vector[], // TODO: add location_hash input
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
    version: u64,
    _: internal::Permit<T>,
    ctx: &mut TxContext,
): Request {
    assert!(e.version == VERSION /* TODO: Code */);

    let mod = mod::new(name, inner, version, ctx);

    e.lock();
    e.add(ModuleKey(name), mod);

    request::new(
        option::some(e.id.to_inner()),
        vector[], // TODO: ACL
    )
}

/// TODO: as an idea, we could require `T` to have `drop`. Or not... either way
/// we want to come up with a way to guarantee deletion of `T` to prevent reinstallation.
///
/// One way to achieve that is to require `T` to have `key + store` and then have
/// a requirement to provide `UID` by value, hence proving that the module object
/// was unpacked. Requirement resolver would "prove deletion". Can expand on this
/// pattern in conversations.
///
/// Some form of ID-ing modules can be unavoidable...
public fun uninstall<T: store>(
    e: &mut Entity,
    /* TODO: OwnerCap */
    name: String,
    _: internal::Permit<T>,
    ctx: &mut TxContext,
): (Module<T>, Request) /* Should it be (T, Request) ? */  {
    assert!(e.version == VERSION /* TODO: Code */);

    abort
}

// Note to self: we can take T for upgradeability; something that `@potatoes/identify` can do.
public fun enable_action<A: store + drop>(
    e: &mut Entity,
    /* TODO: OwnerCap */
    name: String,
    action: A,
    ctx: &mut TxContext,
): Request {
    assert!(e.version == VERSION /* TODO: Code */);
    assert!(type_name::with_defining_ids<Action>() == type_name::with_defining_ids<A>());

    e.lock();

    // eye now, how did we get here
    let action: Action = { e.add(true, action); e.remove(true) };
    let actions = e.borrow_mut<_, VecMap<_, _>>(ActionsKey());
    actions.insert(name, action);

    request::new(
        option::some(e.id.to_inner()),
        vector[], // TODO: ACL
    )
}

/// Disable and remove action `A` from `Entity`.
public fun disable_action<A: store + drop>(
    e: &mut Entity,
    /* TODO: OwnerCap */
    name: String,
    ctx: &mut TxContext,
): Request /* TODO: should it be a Request here? Safer and more future proof to keep */  {
    assert!(e.version == VERSION /* TODO: Code */);

    e.lock();

    let (_, action) = e.borrow_mut<_, VecMap<_, Action>>(ActionsKey()).remove(&name);
    let _ = action; // drop action, being intentionally explicit for you, my dear reviewer!

    request::new(
        option::some(e.id.to_inner()),
        vector[], // TODO: ???
    )
}

/// Interact with an `Entity` through a registered action.
public fun interact(e: &mut Entity, action: String, ctx: &mut TxContext): Request {
    assert!(e.version == VERSION /* TODO: Code */);

    e.lock();

    let actions = e.borrow<_, VecMap<_, Action>>(ActionsKey());
    assert!(actions.contains(&action));
    let action = actions.get(&action);

    // TODO: here add system requirements and then enqueue action requirements

    action.to_request(option::some(e.id.to_inner()))
}

// TODO: expose Module<T>.version field so modules can control their versions

/// NOTE: untyped check for existence of a Module without specifying `T`
public fun has_module(e: &Entity, name: String): bool {
    e.exists(ModuleKey(name))
}

public fun has_module_with_type<T: store>(e: &Entity, name: String): bool {
    e.exists_with_type<_, T>(ModuleKey(name))
}

/// Mutable access to the module is only allowed during interaction.
/// Requires:
/// - Request links to `entity_id`
/// - Request's next requirement's name == module name
public fun module_mut<T: store>(
    e: &mut Entity,
    req: &Request,
    _: internal::Permit<T>,
): &mut Module<T> {
    assert!(e.version == VERSION /* TODO: Code */);
    assert!(e.is_locked() /* TODO: Code */);
    assert!(req.entity_id().is_some_and!(|id| id == e.id.to_inner()) /* TODO: Code */);

    let name = req.next().module_name().destroy_or!(abort /* TODO: Code */);
    &mut e[ModuleKey(name)]
}

/// TODO: currently request can only be completed on Entity, and this is part of
/// the design. However, it is possible to change the implementation so that Request
/// that doesn't contain `entity_id()` could be completed without an entity.
///
/// TODO: Now that I think about it, it shouldn't be `entity_id` :)
public fun complete_request(e: &mut Entity, req: Request) {
    req.entity_id().do!(|id| assert!(id == e.id.to_inner() /* TODO: Code */));
    req.complete();
    e.unlock();
}

/// Allows for configuration before sharing.
public fun share(e: Entity) {
    transfer::share_object(e);
}

// === Bag Implementation ===

fun lock(e: &mut Entity) {
    e.add(InFlight(), true)
}

fun unlock(e: &mut Entity) {
    let _: bool = e.remove(InFlight());
}

fun is_locked(e: &Entity): bool {
    e.exists(InFlight())
}

fun exists<K: copy + drop + store>(e: &Entity, key: K): bool {
    df::exists(&e.id, key)
}

fun exists_with_type<K: copy + drop + store, V: store>(e: &Entity, key: K): bool {
    df::exists_with_type<_, V>(&e.id, key)
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
