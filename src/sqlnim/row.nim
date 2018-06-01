import shared

proc serialize_row*(destination, source: pointer, size: int) = 
    copyMem(destination, source, size)

proc deserialize_row*(destination, source: pointer, size: int) = 
    copyMem(destination, source, size)

proc init_row*(): Row =
    result.username = newString(USERNAME_SIZE)
    result.email = newString(EMAIL_SIZE)

proc new_row*(id: uint64, username, email: string): Row =
    result.id = id
    result.username = newString(USERNAME_SIZE)
    result.username = username
    result.email = newString(EMAIL_SIZE)
    result.email = email
