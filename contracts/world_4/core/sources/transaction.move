module core::transaction;

use ptb::ptb;
use std::string::String;

public struct PTB()

public fun request(): ptb::Argument {
    ptb::ext_input<PTB>("world:request")
}

public fun entity(): ptb::Argument {
    ptb::ext_input<PTB>("world:entity")
}

public fun structure(): ptb::Argument {
    ptb::ext_input<PTB>("world:structure")
}

/// Constructs a special `item:<type_id|*>;<quantity|*>` input.
/// TODO: maybe there's a space for min/max quantity expressed in syntax.
/// TODO: eg `item:100|*-100`
public fun item(type_id: Option<u64>, quantity: Option<u64>): ptb::Argument {
    let mut input: String = "item:";
    if (type_id.is_some()) input.append(type_id.destroy_some().to_string()) else input.append("*");
    input.append(";");
    if (quantity.is_some()) input.append(quantity.destroy_some().to_string())
    else input.append("*");
    ptb::ext_input<PTB>(input)
}

/// TODO: we're not sold on the name and the meaning
///       eg it can be both Character and another entity?
///       as in when turret is shooting at a "target"
public fun location_target(): ptb::Argument {
    ptb::ext_input<PTB>("location:target")
}

public fun proof(): ptb::Argument {
    ptb::ext_input<PTB>("location:proof")
}

public fun owner_cap(id: ID): ptb::Argument {
    let mut input: String = "owner:";
    input.append(id.to_address().to_string());
    ptb::ext_input<PTB>(input)
}
