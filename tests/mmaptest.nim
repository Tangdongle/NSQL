import posix, os, unittest

suite "Redirection Tests":

    test "Test stdout redirection":
        var 
            old_stdout = dup(1)
            f, d: File
            test_text = "Test Text"
            test_outfile = "tests/fixtures/stdout_test"


        checkpoint("Opening file as stdout")
        f = open(test_outfile, fmWrite)
        discard dup2(f.getFileHandle, 1)
        f.close

        #assert stdout.reopen(test_outfile, fmWrite)
        #let stdio_dup_res = dup2(getFileHandle(f), 1)

        stdout.write(test_text)

        stdout.flushFile

        discard dup2(old_stdout, stdout.getFileHandle) 
        checkpoint("Wrote Test Text")

        f = open(test_outfile)
        var results = f.readAll()
        f.close()

        echo results
        for c in results:
            echo c
        check(results.len == test_text.len)
        check(results == test_text)




