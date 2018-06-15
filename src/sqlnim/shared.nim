proc `+`*(p: pointer, ui: SomeUnsignedInt): pointer =
    cast[pointer](cast[uint64](p) + cast[uint64](ui))

#proc `$`*(p: pointer): string =
#    return $cast[ByteAddress](p)

const 
    PAGE_SIZE*: int = 4096
    TABLE_MAX_PAGES*: int  = 100
    COLUMN_USERNAME_SIZE*: int = 32
    COLUMN_EMAIL_SIZE*: int = 255

type
    Row* = object 
        id*: int
        username*: string
        email*: string

    Statement* = ref object of RootObj
        `type`*: StatementType
        row_to_insert*: Row

    StatementType* = enum
        STATEMENT_INSERT = "INSERT",
        STATEMENT_SELECT = "SELECT"

let 
    ID_SIZE*: int = sizeof(int).int
    USERNAME_SIZE*: int = 32
    EMAIL_SIZE*: int = 256
    ID_OFFSET*: int = 0
    USERNAME_OFFSET*: int = ID_OFFSET + ID_SIZE
    EMAIL_OFFSET*: int = USERNAME_OFFSET + USERNAME_SIZE
    ROW_SIZE*: int = ID_SIZE + USERNAME_SIZE + EMAIL_SIZE
    ROWS_PER_PAGE*: int  = PAGE_SIZE div ROW_SIZE
    TABLE_MAX_ROWS*: int = ROWS_PER_PAGE * TABLE_MAX_PAGES

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

proc `[]`(x: array[uint32, pointer], index: SomeInteger): pointer = 
    x[index.uint32]
