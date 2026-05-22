module core::request;

use core::requirement::Requirement;

public struct Request {
    structure_id: Option<ID>,
    requires: vector<Requirement>,
}

public struct Frame {
    pending: vector<Requirement>,
}

public(package) fun new(structure_id: Option<ID>, requires: vector<Requirement>): Request {
    Request {
        structure_id,
        requires,
    }
}

// NOTE: not very sold on returning a frame here, but maybe it's okay?
// NOTE: Ashok, I think we should have optional `satisfy_frame` and just `satisfy`,
//.      otherwise we just keep spawning empty Frames (same in your impl too)
public fun satisfy<T>(request: &mut Request, _: internal::Permit<T>): (Requirement, Frame) {
    let next = request.requires.pop_back();
    // TODO: assert on structure ID?
    // TODO: assert on module?
    // NOTE: I think those are addressed in Inventory.

    assert!(next.is<T>());
    (next, Frame { pending: vector[] })
}

/// Add a requirement to a `Frame`.
public fun require(frame: &mut Frame, requirement: Requirement) {
    frame.pending.push_back(requirement);
}

// NOTE: should we link Frame to Request, is it possible to mess with it?
/// Add pending `Frame` to the `Request`.
public fun enqueue(request: &mut Request, frame: Frame) {
    let Frame { pending } = frame;
    pending.destroy!(|r| request.requires.push_back(r));
}

public(package) fun complete(request: Request) {
    let Request { requires, .. } = request;
    assert!(requires.length() == 0);
}

public fun requires(r: &Request): &vector<Requirement> {
    &r.requires
}

public fun structure_id(r: &Request): Option<ID> {
    r.structure_id
}

// Wish we could return Option<&Requirement> here, but we cannot.
public fun next(r: &Request): &Requirement {
    let len = r.requires.length();
    assert!(len > 0 /* TODO: Code */);
    &r.requires[len - 1]
}

#[test_only]
public fun destroy(r: Request) {
    let Request { .. } = r;
}
