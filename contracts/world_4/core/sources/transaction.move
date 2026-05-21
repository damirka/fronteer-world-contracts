module core::transaction;

use ptb::ptb;

public struct PTB()

public fun request(): ptb::Argument {
    ptb::ext_input<PTB>("world:request")
}

public fun module_(): ptb::Argument {
    ptb::ext_input<PTB>("world:module")
}

public fun structure(): ptb::Argument {
    ptb::ext_input<PTB>("world:structure")
}
