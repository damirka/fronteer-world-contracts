module world::structure;

use std::string::String;
use sui::bag::{Self, Bag};
use sui::dynamic_field as df;
use sui::vec_map::VecMap;

use ptb::ptb;
use world::action::Action;
use world::module_::{Self, Module};
use world::requirement::Requirement;

public struct Structure has key {
    id: UID,
    modules: Bag,
    actions: VecMap<String, Action>,
}

public struct Request {
    structure: ID,
    requires: vector<Requirement>,
}

public struct Frame {
    pending: vector<Requirement>,
}

public struct InFlight() has copy, drop, store;

public fun install<M: store>(structure: &mut Structure, name: String, inner: M) {
    // TODO: requests for installation.
    let module_ = module_::new(
        object::id(structure),
        name,
        inner,
    );

    structure.modules.add(name, module_);
}

public fun expose(structure: &mut Structure, name: String, action: Action) {
    structure.actions.insert(name, action);
}

public fun interact(
    structure: &mut Structure,
    name: String,
): Request {
    df::add(&mut structure.id, InFlight(), true);

    let mut request = Request {
        structure: object::id(structure),
        requires: vector[],
    };

    let mut frame = Frame { pending: vector[] };
    structure.actions.get(&name).requirements().do_ref!(|r| {
        frame.require(*r);
    });

    request.enqueue(frame);
    request
}

// === Request API ===

public fun satisfy_on_module<M, T>(
    request: &mut Request,
    module_: &Module<M>,
    _: internal::Permit<T>,
): (Requirement, Frame) {
    let next = request.requires.pop_back();
    assert!(request.structure == module_.structure());
    assert!(next.module_name().is_some_and!(|n| n == module_.name()));
    assert!(next.is<T>());

    (next, Frame { pending: vector[] })
}

public fun satisfy_on_structure<T>(
    request: &mut Request,
    structure: &Structure,
): (Requirement, Frame) {
    let next = request.requires.pop_back();
    assert!(request.structure == object::id(structure));
    assert!(next.module_name().is_none());
    assert!(next.is<T>());

    (next, Frame { pending: vector[] })
}

public fun require(frame: &mut Frame, requirement: Requirement) {
    frame.pending.push_back(requirement);
}

public fun enqueue(request: &mut Request, frame: Frame) {
    let Frame { pending } = frame;
    pending.destroy!(|r| request.requires.push_back(r));
}

public fun complete(request: Request, structure: &mut Structure) {
    let Request { structure: id, requires } = request;
    assert!(requires.length() == 0);
    assert!(id == object::id(structure));
    let _: bool = df::remove(&mut structure.id, InFlight());
}
