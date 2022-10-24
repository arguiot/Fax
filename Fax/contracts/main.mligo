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

// MARK: - Main
let main (ep, store : parameter * storage) : return =
    match ep with
    | Register(p) -> register (p, store)
    | Unregister -> unregister store
    | Print(_p) -> (failwith "Not implemented" : return)