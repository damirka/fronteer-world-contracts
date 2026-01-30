#[mode(test)]
extend module sui::test_scenario;

public macro fun tx($scenario: &mut Scenario, $sender: address, $f: |&mut Scenario| -> _) {
    let test = $scenario;
    let sender = $sender;
    test.next_tx(sender);
    $f(test);
    test.next_tx(sender);
}
