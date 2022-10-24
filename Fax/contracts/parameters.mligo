module Types = struct
    type register = {
        cost: tez; // Cost per print operation
    }
    type print = string
    type t = Register of register | Print of print
end