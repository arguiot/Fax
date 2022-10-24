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
        users : address set;
        printers : (address, printer) map;
        // MARK: - Balance
        account_balances : (address, tez) map;
        // MARK: - Settings
        max_printer_size : nat;
    }
end