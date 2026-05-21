#[allow(unused)]
module core::request;

use core::requirement::{Self, Requirement};

public struct Request {
    structure_id: Option<ID>,
    steps: vector<Requirement>,
}

public(package) fun new(structure_id: Option<ID>, steps: vector<Requirement>): Request {
    Request {
        structure_id,
        steps,
    }
}

public fun satisfy<T>(request: &mut Request, _: internal::Permit<T>): Requirement {
    let next = request.steps.pop_back();
    // TODO: assert on structure ID

    // request.structure_id.is_some_and!(|id| )
    // assert!( == module_.structure());

    assert!(next.is<T>());
    next
}

public(package) fun complete(request: Request) {
    let Request { steps, .. } = request;
    assert!(steps.length() == 0);
}

public fun steps(r: &Request): &vector<Requirement> {
    &r.steps
}

public fun structure_id(r: &Request): Option<ID> { r.structure_id }

public fun next(r: &Request): &Requirement {
    let len = r.steps.length();
    assert!(len > 0 /* TODO: Code */);
    &r.steps[len - 1]
}

#[test_only]
public fun destroy(r: Request) { let Request { .. } = r; }
