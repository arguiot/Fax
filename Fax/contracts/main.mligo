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
    let store = { store with printers = Map.add sender printer store.printers } in
    ([], store)

// MARK: - Main
let main (ep, store : parameter * storage) : return =
    match ep with
    | Register(p) -> register (p, store)
    | Print(_p) -> (failwith "Not implemented" : return)