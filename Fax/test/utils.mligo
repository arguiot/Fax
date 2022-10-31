type lookup = (int, string) map
let int_to_string (i:int) : string =
    let lookup: lookup = 
        Map.literal[(0, "0"); (1, "1"); (2, "2"); (3, "3"); (4, "4"); (5, "5"); (6, "6"); (7, "7"); (8, "8"); (9, "9")]
    in

    let digitToStr (key: int): string =
    match Map.find_opt key lookup with
        Some str -> str
        | None -> (failwith "Not found": string)
    in
    let rec intToStr ((x, str): int * string) : string =
        if (x < 10) then 
            digitToStr(x) ^ str 
        else
        intToStr((
            x / 10, 
            digitToStr(int(x mod 10)) ^ str
        ))
    in
    intToStr((i, ""))