# Package

version       = "0.1.0"
author        = "Ryanc_signiq"
description   = "A nim sql implementation"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 0.18.0"

task make, "Build the app":
    exec "mkdir -p bin"
    exec "nim c --out:bin/sqlnim src/sqlnim.nim"

task run, "Run the app":
    exec "mkdir -p bin"
    exec "nim c -r --out:bin/sqlnim src/sqlnim.nim"

task test, "Test the app":
    exec "mkdir -p tests/bin"
    exec "for i in tests/*.nim; do nim c -r test --out:tests/bin/$i $i; done"

task test_main, "Test the main app":
    exec "mkdir -p bin"
    exec "nim c -r --out:bin/sqlnim src/sqlnim"

task test_row, "Test the row model":
    exec "mkdir -p tests/bin"
    exec "nim c -r test --out:tests/bin/row_tests tests/row_tests.nim"

task test_table, "Test the table model":
    exec "mkdir -p tests/bin"
    exec "nim c -r test --out:tests/bin/table_tests tests/table_tests.nim"

task debug, "Debug the app":
    exec "mkdir -p bin"
    exec "nim c --lineDir:on --debuginfo -r --out:bin/sqlnim src/sqlnim.nim"

task tables, "Run table tests":
    exec "mkdir -p bin/tests"
    exec "nim c -r --out:bin/tests/tabletest src/sqlnim/table.nim"

task trace_mmap, "Trace mmap":
    exec "mkdir -p bin/tests"
    exec "nim c --out:bin/tests/mmaptest tests/mmaptest.nim"
    exec "strace -o strace.log bin/tests/mmaptest"


task trace_main, "Trace Main":
    exec "mkdir -p bin"
    exec "nim c --out:bin/sqlnim src/sqlnim.nim"
    exec "strace -o strace.log bin/sqlnim"
