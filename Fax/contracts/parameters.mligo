module Types = struct
    type register = {
        cost: tez; // Cost per print operation
    }
    type print = {
        message: string;
        printer: address;
    }
    type t = 
    Register of register |
    Unregister |
    AddJob of print |
    GetJob
end