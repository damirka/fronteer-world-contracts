module world::character;

use sui::transfer::Receiving;

const ECharacterIdMismatch: u64 = 0;
const EItemIdMismatch: u64 = 1;

public struct Character has key { id: UID }

public struct CharacterOwnerCap has key { id: UID, character_id: ID }

public struct Borrow { character_id: ID, item_id: ID }

public fun create(ctx: &mut TxContext): CharacterOwnerCap {
    let character_id = object::new(ctx);
    let character_owner_cap = CharacterOwnerCap {
        id: object::new(ctx),
        character_id: character_id.to_inner(),
    };

    transfer::share_object(Character { id: character_id });
    character_owner_cap
}

public fun borrow_item<T: key + store>(
    character: &mut Character,
    cap: &CharacterOwnerCap,
    item: Receiving<T>,
): (T, Borrow) {
    assert!(character.id.to_inner() == cap.character_id, ECharacterIdMismatch);
    let item = transfer::public_receive(&mut character.id, item);
    let item_id = object::id(&item);
    (item, Borrow { character_id: character.id.to_inner(), item_id })
}

// NOTE: no character required, we transfer to the ID stored in Borrow
public fun put_back_item<T: key + store>(item: T, borrow: Borrow) {
    let Borrow { character_id, item_id } = borrow;
    assert!(item_id == object::id(&item), EItemIdMismatch);
    transfer::public_transfer(item, character_id.to_address());
}
