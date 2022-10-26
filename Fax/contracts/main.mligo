#import "storage.mligo" "Storage"
#import "parameters.mligo" "Parameters"
#import "errors.mligo" "Error"

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
        (failwith Error.sender_already_register : return)
    else
        let store = { store with printers = Big_map.add sender printer store.printers } in
        ([], store)

let unregister (store : storage) : return =
    let sender = Tezos.get_sender () in
    // Check if the sender is already registered
    let printer = Big_map.find_opt sender store.printers in
    let op, store = match printer with
    | None -> (failwith Error.sender_not_register : return)
    | Some printer ->
        // Check if the sender has any pending jobs
        if (List.length printer.stack > 0n) then
            (failwith Error.sender_pending_jobs : return)
        else
            // Check if the sender has a positive balance
            let balance = Big_map.find_opt sender store.account_balances in
            let op, store = match balance with
                | Some (balance) ->
                if (balance > 0tez) then
                    // If the sender has a positive balance, we need to transfer the funds to the owner
                    let op = match Tezos.get_contract_opt sender with
                    | None -> (failwith Error.sender_not_contract : operation)
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
    | None -> (failwith Error.printer_not_register : return)
    | Some printer ->
        // Check if the sender sent enough funds to cover the cost
        let amount = Tezos.get_amount () in
        if (amount < printer.cost) then
            (failwith Error.sender_not_enough_funds : return)
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
            | None -> amount
            | Some (balance) -> balance + amount
            in
            let store = { store with account_balances = Big_map.update param.printer (Some balance) store.account_balances } in

            ([], store)
    in

    (op, store)

let get_job (store : storage) : return =
    let sender = Tezos.get_sender () in
    // Check if the sender is registered
    let printer: Storage.Types.printer option = Big_map.find_opt sender store.printers in
    let op, store = match printer with
    | None -> (failwith Error.printer_not_register : return)
    | Some printer ->
        // Check if the printer has any jobs
        let stack: string list = printer.stack in
        let op, store = match stack with
        | [] -> (failwith Error.printer_no_jobs : return)
        | stack_list ->
            // Remove the job from the printer's stack
            let remove_last (list: string list) : string list =
                let rec aux (list: string list) (acc: string list) : string list =
                    match list with
                    | [] -> acc
                    | [x] -> acc
                    | x :: xs -> aux xs (x :: acc)
                    in
                aux list []
            in
            let printer: Storage.Types.printer = { printer with stack = remove_last stack_list } in

            let printers = Big_map.update sender (Some printer) store.printers in
            let store = { store with printers = printers } in
            // Send the balance to the sender
            let balance = Big_map.find_opt sender store.account_balances in
            let op, store = match balance with
            | None -> (failwith Error.balance_no_funds : return)
            | Some (balance) ->
                // If the sender has a positive balance, we need to transfer the funds for the job to the owner
                let cost = printer.cost in
                if (balance < cost) then
                    (failwith Error.balance_not_enough_funds : return)
                else
                    let op = match Tezos.get_contract_opt sender with
                    | None -> (failwith Error.sender_not_contract : operation)
                    | Some contract -> Tezos.transaction () cost contract in

                    // Update the account balances for the printer
                    let balance = balance - cost in
                    let store = { store with account_balances = Big_map.update sender balance store.account_balances } in
                ([op], store)
            in
            (op, store)
        in
        (op, store)
    in

    (op, store)

// MARK: - Main
let main (ep, store : parameter * storage) : return =
    match ep with
    | Register(p) -> register (p, store)
    | Unregister -> unregister store
    | AddJob(p) -> add_job (p, store)
    | GetJob -> get_job store