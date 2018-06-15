import src/sqlnim/shared
import unittest, typetraits
include src/sqlnim/table
from src/sqlnim/row import new_row, serialize_row, deserialize_row
#from src/sqlnim/table import Table, new_table

suite "Table Tests":

    setup:
        GC_disable()
        var table = new_table()

    test "table pages size test":
        let pages = table.pages
        echo $pages.len
        echo $TABLE_MAX_PAGES
        assert pages.len == TABLE_MAX_PAGES

    test "table page malloc test":
        let first_page: pointer = table.pages[0]
        check(isNil(first_page))


        var allocedSlot: pointer = row_slot(table, 0)

        check(not isNil(allocedSlot))

        var 
            filling_string = newString(PAGE_SIZE)
            empty_string = newString(PAGE_SIZE)

        for i in 0 ..< 127:
            filling_string.add('a')

        moveMem(addr empty_string, addr filling_string,  sizeof(filling_string))
        check(equalMem(addr empty_string, addr filling_string,  sizeof(filling_string)))
        echo empty_string
        echo filling_string

    test "table page row malloc test":
        var row = new_row(1, "AAAAAA", "BBBB@BB")
        var row2 = init_row()

        var empty_first_page: pointer = table.pages[0]
        check(isNil(empty_first_page))
        table.pages[0] = alloc0(PAGE_SIZE)
        var first_page = cast[ptr Row](table.pages[0])

        check(not isNil(table.pages[0]))

        moveMem(table.pages[0], row.addr, sizeof(row))

        check(equalMem(first_page, table.pages[0], sizeof(row)))
        check(equalMem(first_page, row.addr, sizeof(row)))
        check(equalMem(table.pages[0], row.addr, sizeof(row)))

        var row_ref:ref Row = cast[ref Row](first_page)
        echo row_ref.username
        check(row_ref.username == row.username)

        var row_ptr:ptr Row = first_page
        echo row_ptr.username
        check(row_ptr.username == row.username)

        echo sizeof(cast[Row](first_page))
        moveMem(row2.addr, first_page, sizeof(cast[Row](first_page)))

        check(row2.username == row.username)

        row2 = new_row(2, "BBB", "CC@C")

        serialize_row(first_page, row2.addr)

        check(first_page.username == row2.username)
        echo first_page.username

        var row3 = init_row()
        deserialize_row(row3.addr, first_page)

        check(first_page.username == row3.username)
        echo row3.username

        dealloc(first_page)
        echo first_page.username
        

    test "Row slot test":
        var row = new_row(1, "SlotvTest", "Slotty@sdlot")

        var empty_row = row_slot(table, 0)

        serialize_row(empty_row, row.addr)
        check(equalMem(empty_row, row.addr, sizeof(row)))
        echo cast[ptr Row](empty_row).username

        var empty_row_2 = init_row()

        deserialize_row(empty_row_2.addr, empty_row)
        echo empty_row_2.username
        check(empty_row_2.username == row.username)
        echo $empty_row_2

        var another_empty_row = row_slot(table, 101)









        

