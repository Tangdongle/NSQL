import shared
from row import serialize_row, deserialize_row, init_row

type
    Table* = ref object of RootObj
        pages: array[TABLE_MAX_PAGES, pointer]
        num_rows: int

    ExecuteResult* = enum
        EXECUTE_SUCCESS = "Execution Successful"
        EXECUTE_TABLE_FULL = "Failed! Table is full"

proc new_table*(): Table =
    new result
    result.num_rows = 0

proc row_slot(table: Table, row_num: int): pointer =
    ##[
    Allocates memory for a single row slot
    ]##
    let 
        page_num = row_num div ROWS_PER_PAGE
        row_offset: uint64 = uint64(row_num mod ROWS_PER_PAGE)
        byte_offset: uint64 = uint64(row_offset * ROW_SIZE.uint64)
    var page: pointer = table.pages[page_num]
    echo "Page Num: " & $page_num & " FROM " & $row_num & " div " & $ROWS_PER_PAGE

    if isNil(page):
        table.pages[page_num] = alloc0(PAGE_SIZE)
        page = table.pages[page_num]
    page + byte_offset

proc execute_insert*(statement: Statement, table: Table): ExecuteResult =
    if table.num_rows >= TABLE_MAX_ROWS:
        return EXECUTE_TABLE_FULL

    var rowSlot = row_slot(table, table.num_rows)
    serialize_row(rowSlot, statement.row_to_insert.addr)
    table.num_rows.inc

    EXECUTE_SUCCESS


proc execute_select*(statement: Statement, table: Table): ExecuteResult =
    echo "In select"
    var 
        row:Row = init_row()
        rowSlot:pointer

    for i in 0 ..< table.num_rows:
        rowSlot = row_slot(table, i)
        deserialize_row(row.addr, rowSlot)
        echo $row

    echo "Leaving select"
    EXECUTE_SUCCESS

when isMainModule:
    var table = new_table()
    let pages = table.pages

