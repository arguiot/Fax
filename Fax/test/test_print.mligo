#import "../contracts/main.mligo" "Fax"

// Tests
let test =
    let alice: address = Test.nth_bootstrap_account 0 in
    let bob: address = Test.nth_bootstrap_account 1 in

    let init_storage : Fax.Storage.Types.t = {
        printers= Big_map.empty;

        account_balances= Big_map.empty;
        max_printer_size= 100n;
    } in

    // Originate the contract
    let (addr, _, _) = Test.originate Fax.main init_storage 0tez in
    let s_init = Test.get_storage addr in
    let () = Test.log(s_init) in

    let x : Fax.parameter contract = Test.to_contract addr in

    let () = Test.set_source alice in
    // Register a printer
    let register_args: Fax.Parameters.Types.register = {
        cost= 100_000mutez;
    } in
    let _ = Test.transfer_to_contract_exn x (Register(register_args)) 10mutez in

    let s = Test.get_storage addr in
    let response : bool = match Big_map.find_opt alice s.printers with
        | Some _ -> true
        | None -> false
    in

    let () = assert (response) in

    // Tests
    let test_add_job =
        let () = Test.log("Test 1: Send a job to the printer") in
        let () = Test.set_source bob in
        let add_job_args: Fax.Parameters.Types.print = {
            printer= alice;
            message= "Hello World";
        } in
        let result = Test.transfer_to_contract x (AddJob(add_job_args)) 100_000mutez in

        let success = match result with
            | Success _ -> true
            | _ -> false
        in

        let () = assert (success) in

        let s = Test.get_storage addr in
        
        let () = Test.log(s) in

        let () = Test.log("Test 1: Send a job to the printer - SUCCESS") in
        ()

    in
    
    ()
