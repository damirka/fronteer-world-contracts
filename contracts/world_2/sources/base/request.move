/// Base component of the Request + Requirement system.
/// Defines the `ApplicationRequest` type and the associated functions.
///
/// ApplicationRequest implements the 'Request' pattern (also called 'Punch-card'):
/// - request is issued with a set of requirements (punch-slots)
/// - requirements are removed and verified in services and components
/// - once all requirements are satisfied, the request can be completed
module world::request;

use std::string::String;
use world::requirement::Requirement;

/// Default version of the request.
const VERSION: u64 = 1;

#[error(code = 1)]
const EInvalidVersion: vector<u8> = b"Unable to complete request: invalid version";

/// A request spawned by different components of the world.
public struct ApplicationRequest {
    action: String,
    version: u64,
    requires: vector<Requirement>,
}

/// Add extra requirement to the request.
public fun add_requirement(request: &mut ApplicationRequest, requirement: Requirement) {
    request.requires.push_back(requirement);
}

/// Complete a requirement and remove it from the request.
public fun complete_requirement<T>(
    request: &mut ApplicationRequest,
    _: internal::Permit<T>,
): Requirement {
    let index = request.requires.find_index!(|requirement| requirement.is<T>()).destroy_or!(abort);
    request.requires.swap_remove(index)
}

/// Complete the request by
public fun complete(request: ApplicationRequest) {
    let ApplicationRequest { action: _, version, requires } = request;
    assert!(requires.length() == 0);
    assert!(version == VERSION, EInvalidVersion);
}

/// Join two identical requests together since path to verification is likely to
/// be the same. This allows performing multiple identical requests in a single
/// transaction
///
/// TODO: there may be unwanted side effects of this action, so should be held off
///   until further investigation
public fun join(base: &mut ApplicationRequest, other: ApplicationRequest) {
    let ApplicationRequest { action, version, requires } = other;

    assert!(base.action == action);
    assert!(base.version == version);
    assert!(base.requires == requires);
}

public fun version(request: &ApplicationRequest): u64 {
    request.version
}

// === Builder API ===

/// A builder for `ApplicationRequest`.
public struct ApplicationRequestBuilder {
    action: String,
    version: u64,
    requires: vector<Requirement>,
}

/// Initialize a new `ApplicationRequestBuilder` with the given action.
public fun new(action: String): ApplicationRequestBuilder {
    ApplicationRequestBuilder { action, requires: vector[], version: VERSION }
}

/// Add a requirement to the request.
public fun with_requirement(
    mut builder: ApplicationRequestBuilder,
    requirement: Requirement,
): ApplicationRequestBuilder {
    builder.requires.push_back(requirement);
    builder
}

/// Set the version of the request. If not set, the default version will be used.
public fun with_version(
    mut builder: ApplicationRequestBuilder,
    version: u64,
): ApplicationRequestBuilder {
    builder.version = version;
    builder
}

/// Build the `ApplicationRequest` from the builder.
public fun build(builder: ApplicationRequestBuilder): ApplicationRequest {
    let ApplicationRequestBuilder { action, requires, version } = builder;

    ApplicationRequest {
        action,
        version,
        requires,
    }
}
