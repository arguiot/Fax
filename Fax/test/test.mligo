#import "../contracts/main.mligo" "Fax"

let test =
    let alice: address = Test.nth_bootstrap_account 0 in

    let init_storage : Fax.Storage.Types.t = {
        printers= Big_map.empty;

        account_balances= Big_map.empty;
        max_printer_size= 100n;
    } in

    // Originate the contract
    let (addr, _, _) = Test.originate Fax.main init_storage 0tez in
    let s_init = Test.get_storage addr in
    let () = Test.log(s_init) in

    // MARK: - Test 1: Register a printer
    let test_register =
        let () = Test.log("Test 1: Register a printer") in

        let x : Fax.parameter contract = Test.to_contract addr in

        let () = Test.set_source alice in

        let register_args: Fax.Parameters.Types.register = {
            cost= 100_000mutez;
        } in
        let _ = Test.transfer_to_contract_exn x (Register(register_args)) 10mutez in

        let s = Test.get_storage addr in
        let response : bool = match Big_map.find_opt alice s.printers with
            | Some _ -> true
            | None -> false
        in
        let () = Test.log(s) in
        let () = assert (response) in

        ()
    in

    // MARK: - Test 2: Register an already registered printer
    let test_register_already_registered =
        let () = Test.log("Test 2: Register an already registered printer") in

        let x : Fax.parameter contract = Test.to_contract addr in

        let () = Test.set_source alice in

        let register_args: Fax.Parameters.Types.register = {
            cost= 100_000mutez;
        } in
        let result = Test.transfer_to_contract x (Register(register_args)) 10mutez in

        let success = match result with
            | Success _ -> true
            | Fail _ -> false
        in

        let () = assert (not success) in
        let () = Test.log("Test 2: Register an already registered printer - SUCCESS") in

        ()
    in

    ()
