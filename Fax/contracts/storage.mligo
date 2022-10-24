// Records types
module Types = struct
    type status = Queued | Printed
    type message = {
        content: string;
        status: status;
    }
    type printer = {
        stack : message list;
        cost : tez;
    }
    type t = {
        // MARK: - Printers
        printers : (address, printer) big_map;
        // MARK: - Balance
        account_balances : (address, tez) big_map;
        // MARK: - Settings
        max_printer_size : nat;
    }
end