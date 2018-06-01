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
    exec "for i in tests/*.nim; do nim c -r $i; done"
