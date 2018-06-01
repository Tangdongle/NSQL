proc `+`*(p: pointer, ui: SomeUnsignedInt): pointer =
    cast[pointer](cast[uint64](p) + cast[uint64](ui))

proc `$`*(p: pointer): string =
    return $cast[ByteAddress](p)

const 
    PAGE_SIZE*:uint32  = 4096
    TABLE_MAX_PAGES*:uint32  = 100
    COLUMN_USERNAME_SIZE*: uint32 = 32
    COLUMN_EMAIL_SIZE*: uint32 = 255

type
    Row* = object 
        id*: uint64
        username*: string
        email*: string

    Statement* = ref object of RootObj
        `type`*: StatementType
        row_to_insert*: Row

    StatementType* = enum
        STATEMENT_INSERT = "INSERT",
        STATEMENT_SELECT = "SELECT"

let 
    ID_SIZE*: uint64 = sizeof(Row.id).uint64
    USERNAME_SIZE*: uint64 = sizeof(Row.username).uint64
    EMAIL_SIZE*: uint64 = sizeof(Row.email).uint64
    ID_OFFSET*: uint64 = 0
    USERNAME_OFFSET*: uint64 = ID_OFFSET + ID_SIZE
    EMAIL_OFFSET*: uint64 = USERNAME_OFFSET + USERNAME_SIZE
    ROW_SIZE*: uint64 = ID_SIZE + USERNAME_SIZE + EMAIL_SIZE
    ROWS_PER_PAGE*:uint32  = PAGE_SIZE div sizeof(Row).uint32
    TABLE_MAX_ROWS*:uint32 = ROWS_PER_PAGE * TABLE_MAX_PAGES

proc `$`(x: Row): string = 
    result = "Row: "
    for name, value in x.fieldPairs:
        result.add("\n\t" & name & " is " & $value)

proc `=`(x: var Row, y: Row) = 
    x.id = y.id
    x.username = y.username
    x.email = y.email

proc `$`(x: Statement): string =
    return $x.type & ": " & $x.row_to_insert
