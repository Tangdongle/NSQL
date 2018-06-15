import src/sqlnim/shared
import unittest
import strutils
from src/sqlnim/row import new_row, init_row

suite "Row Tests":

    setup:
        var r = new_row(1, "aaa", "bbb")
        var r2 = init_row()

    #teardown:
        
    test "rowcopy test":
        var pt_Row = addr r
        var pt2_Row = addr r2
        #Copy one to the other
        copyMem(pt2_Row, pt_Row, sizeof(r))
        echo $pt2_Row.username

    test "char to string test":
        var 
            id: uint64
            inp = @["1", "user", "email"]
        
        #allocate memory for a cstring, the size of the string being copied
        var s1:cstring = cast[cstring] (alloc0((inp[1].len + 1) * sizeof(char)))


        s1 = inp[1]
        echo $s1
        #Works!
        var s2 = inp[1].cstring

        copyMem(addr s1, addr s2, s1.len * sizeof(char))
        echo $s1
        #Works!

    test "Copy strings to row attributes":
        var 
            dest_test_username_string = newString(USERNAME_SIZE)
            src_test_username_string = "TEST"

        copyMem(r2.username.addr, src_test_username_string.addr, sizeof(src_test_username_string))

        echo "string -> row"
        check(r2.username == src_test_username_string)
        check(equalMem(r2.username.addr, src_test_username_string.addr, sizeof(src_test_username_string)))
        echo r2.username & " | " & src_test_username_string

        echo "row -> string"
        copyMem(dest_test_username_string.addr, r.username.addr, sizeof(r.username))

        check(r.username == dest_test_username_string)
        check(equalMem(r.username.addr, dest_test_username_string.addr, sizeof(r.username)))
        echo r.username & " | " & dest_test_username_string
        



