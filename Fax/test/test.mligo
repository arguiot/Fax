#import "../contracts/main.mligo" "Fax"

let test =
    let alice: address = Test.nth_bootstrap_account 0 in

    let init_storage : Fax.Storage.Types.t = {
        users= Set.empty;
        printers= Map.empty;

        account_balances= Map.empty;
        max_printer_size= 100n;
    } in

    // Originate the contract
    let (addr, _, _) = Test.originate Fax.main init_storage 0tez in
    let s_init = Test.get_storage addr in
    let () = Test.log(s_init) in

    ()
