import shared

proc serialize_row*(source: pointer, destination: var pointer, size: int) = 
    copyMem(destination, source, ROW_SIZE)

proc deserialize_row*(source: pointer, destination: var pointer, size: int) = 
    copyMem(destination, source, ROW_SIZE)
    echo $destination

proc init_row*(): Row =
    result.username = newString(USERNAME_SIZE)
    result.email = newString(EMAIL_SIZE)

proc new_row*(id: uint64, username, email: string): Row =
    result.id = id
    result.username = newString(USERNAME_SIZE)
    result.username = username
    result.email = newString(EMAIL_SIZE)
    result.email = email
