#import "storage.mligo" "Storage"
#import "parameters.mligo" "Parameters"

type storage = Storage.Types.t
type parameter = Parameters.Types.t
type return = operation list * storage

// MARK: - Entrypoints
let register (param, store : Parameters.Types.register * storage) : return =
    let cost = param.cost in
    let printer : Storage.Types.printer = {
        stack = [];
        cost = cost;
    } in
    let sender = Tezos.get_sender () in
    // Check if the sender is already registered
    if (Big_map.mem sender store.printers) then
        (failwith "SENDER_ALREADY_REGISTERED" : return)
    else
        let store = { store with printers = Big_map.add sender printer store.printers } in
        ([], store)

let unregister (store : storage) : return =
    let sender = Tezos.get_sender () in
    // Check if the sender is already registered
    let printer = Big_map.find_opt sender store.printers in
    let op, store = match printer with
    | None -> (failwith "SENDER_NOT_REGISTERED" : return)
    | Some printer ->
        // Check if the sender has any pending jobs
        if (List.length printer.stack > 0n) then
            (failwith "SENDER_HAS_PENDING_JOBS" : return)
        else
            // Check if the sender has a positive balance
            let balance = Big_map.find_opt sender store.account_balances in
            let op, store = match balance with
                | Some (balance) ->
                if (balance > 0tez) then
                    // If the sender has a positive balance, we need to transfer the funds to the owner
                    let op = match Tezos.get_contract_opt sender with
                    | None -> (failwith "SENDER_NOT_CONTRACT" : operation)
                    | Some contract -> Tezos.transaction () balance contract in

                    // Remove the sender from the account balances
                    let store = { store with account_balances = Big_map.remove sender store.account_balances } in
                    ([op], store)
                else
                    ([], store)
                | None -> ([], store)
            in
            let store = { store with printers = Big_map.remove sender store.printers } in
            (op, store)
    in

    (op, store)


let add_job (param, store : Parameters.Types.print * storage) : return =
    // Check if the printer is registered
    let printer: Storage.Types.printer option = Big_map.find_opt param.printer store.printers in
    let op, store = match printer with
    | None -> (failwith "PRINTER_NOT_REGISTERED" : return)
    | Some printer ->
        // Check if the sender sent enough funds to cover the cost
        let amount = Tezos.get_amount () in
        if (amount < printer.cost) then
            (failwith "NOT_ENOUGH_FUNDS" : return)
        else
            // Add the job to the printer's stack
            let stack: string list = printer.stack in
            let message: string = param.message in
            let printer: Storage.Types.printer = { printer with stack = message :: stack } in
            let printers = Big_map.update param.printer (Some printer) store.printers in
            let store = { store with printers = printers } in
            // Update the account balances for the printer
            let balance = Big_map.find_opt param.printer store.account_balances in
            let balance = match balance with
            | None -> 0tez
            | Some (balance) -> balance + amount
            in
            let store = { store with account_balances = Big_map.update param.printer (Some balance) store.account_balances } in

            ([], store)
    in

    (op, store)

// MARK: - Main
let main (ep, store : parameter * storage) : return =
    match ep with
    | Register(p) -> register (p, store)
    | Unregister -> unregister store
    | AddJob(p) -> add_job (p, store)
    | JobDone -> (failwith "NOT_IMPLEMENTED" : return)