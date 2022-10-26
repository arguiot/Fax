#import "../contracts/main.mligo" "Fax"
#import "../contracts/utils.mligo" "Utils"

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
    let _ = Test.transfer_to_contract_exn x (Register(register_args)) 0mutez in

    let s = Test.get_storage addr in
    let response : bool = match Big_map.find_opt alice s.printers with
        | Some _ -> true
        | None -> false
    in

    let () = assert (response) in

    // Tests
    let test_add_job (n: nat) =
        let () = Test.log("Test " ^ Utils.int_to_string (int(n)) ^ ": Send a job to the printer") in
        let () = Test.set_source bob in
        let add_job_args: Fax.Parameters.Types.print = {
            printer= alice;
            message= "Hello World " ^ Utils.int_to_string (int(n));
        } in
        let result = Test.transfer_to_contract x (AddJob(add_job_args)) 100_000mutez in

        let success = match result with
            | Success g -> 
            let () = Test.log("Success: " ^ Utils.int_to_string (int(g))) in
            true
            | _ -> false
        in

        let () = assert (success) in

        let s = Test.get_storage addr in
        
        let () = Test.log(s) in

        // Check the contract balance
        let ctr = Test.to_contract addr in
        let address = Tezos.address ctr in
        let contract_balance = Test.get_balance address in
        let () = Test.log(contract_balance) in
        let () = assert (contract_balance = 100_000mutez * n) in

        let () = Test.log("Test " ^ Utils.int_to_string (int(n)) ^ ": Send a job to the printer - SUCCESS") in
        ()
    in
    // Test 1
    let test1 = test_add_job(1n) in
    // Test 2
    let test2 = test_add_job(2n) in

    // Get the job
    let test_get_job (n: nat) =
        let () = Test.log("Test " ^ Utils.int_to_string (int(n)) ^ ": Get the job") in
        let () = Test.set_source alice in

        // First, check how many jobs are in the queue
        let s = Test.get_storage addr in
        let jobs = match Big_map.find_opt alice s.printers with
            | Some printer -> printer.stack
            | None -> []
        in
        let jobs_count = List.length jobs in

        let result = Test.transfer_to_contract x GetJob 0mutez in

        let success = match result with
            | Success _ -> true
            | _ -> false
        in

        let () = assert (success) in
        // Check that the job was removed from the queue
        let s = Test.get_storage addr in
        let jobs = match Big_map.find_opt alice s.printers with
            | Some printer -> printer.stack
            | None -> []
        in
        let jobs_count_after = List.length jobs in

        let () = assert ((int jobs_count_after) = jobs_count - 1n) in
        
        let () = Test.log(s) in

        let () = Test.log("Test " ^ Utils.int_to_string (int(n)) ^ ": Get the job - SUCCESS") in
        ()
    in
    // Test 3
    let test3 = test_get_job(3n) in

    ()
