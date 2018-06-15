import shared

proc serialize_row*(destination: pointer, source: ptr Row) = 
    copyMem(destination, source, sizeof(cast[Row](source)))

proc deserialize_row*(destination: ptr Row, source: pointer) = 
    copyMem(destination, source, sizeof(cast[Row](destination)))

proc init_row*(): Row =
    result.username = newString(USERNAME_SIZE)
    result.email = newString(EMAIL_SIZE)

proc new_row*(id: int, username, email: string): Row =
    result.id = id
    result.username = newString(USERNAME_SIZE)
    result.username = username
    result.email = newString(EMAIL_SIZE)
    result.email = email
