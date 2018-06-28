import memfiles

when isMainModule:
    var f: MemFile
    var s = "/home/ryan/dev/nim/sqlnim/tests/fixtures/out_testdata"

    f = memfiles.open(s, fmReadWrite, mappedSize = 4096)
