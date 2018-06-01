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

        copyMem(addr s1, addr s2, sizeof(s1))
        echo $s1
        #Works!




