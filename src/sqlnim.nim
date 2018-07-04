# sqlnim
# Copyright Ryanc_signiq
# A nim sql implementation
import parseopt, strutils, strformat, marshal, macros
import sqlnim/table, sqlnim/row, sqlnim/shared 

type
    MetaCommandResult = enum
        META_COMMAND_SUCCESS,
        META_COMMAND_UNRECOGNIZED_COMMAND,
        META_COMMAND_QUIT

    PrepareResult = enum
        PREPARE_SUCCESS = "Success",
        PREPARE_UNRECOGNIZED_STATEMENT = "Unrecognized Command",
        PREPARE_SYNTAX_ERROR = "Syntax Error"


proc writeHelp()
proc writeVersion()
proc doMetaCommand(input: string): MetaCommandResult
proc prepareStatement(input: string, statement: var Statement): PrepareResult
proc execute_statement(statement: Statement, table: Table): ExecuteResult

proc rowCols(): uint =
    const r:Row = Row()
    for field in r.fields:
        result.inc
        
const numRows = rowCols()

proc printPrompt() = 
    stdout.write "db > "
    stdout.flushFile

proc main(parser: var OptParser) = 
    var
        kind: CmdLineKind
        val, key, filename: string
        input_line: string
        statement: Statement = new Statement
        table: Table = new_table()

    for kind, key, val in parser.getopt():
        case kind
        of cmdArgument:
            filename = key
        of cmdLongOption, cmdShortOption:
            case key
            of "help", "h": 
                writeHelp()
                return
            of "version", "v": 
                writeVersion()
                return
        of cmdEnd: assert(false)

    var secondLine = false
    while true:
        printPrompt()
        input_line = stdin.readLine()

        if input_line.startsWith("."):
            case doMetaCommand(input_line)
            of META_COMMAND_SUCCESS:
                continue
            of META_COMMAND_UNRECOGNIZED_COMMAND:
                stderr.writeLine "Unrecognized command: " & input_line
                continue
            of META_COMMAND_QUIT:
                return
        
        case prepareStatement(input_line, statement)
        of PREPARE_SUCCESS:
            stderr.writeLine "\nCommand success"
        of PREPARE_UNRECOGNIZED_STATEMENT:
            stderr.writeLine &"Unrecognized keyword at start of '{input_line}'" 
            continue
        of PREPARE_SYNTAX_ERROR:
            stderr.writeLine &"Syntax error in '{input_line}'"
            continue

        case execute_statement(statement, table)
        of EXECUTE_SUCCESS:
            stdout.writeLine("\nExecuted successfully")
        of EXECUTE_TABLE_FULL:
            stderr.writeLine("\nError: Table Full")

proc writeHelp() =
    echo "Help"

proc writeVersion() =
    echo "0.1"

proc doMetaCommand(input: string): MetaCommandResult =
    if cmpIgnoreCase(input, ".exit") == 0:
        return META_COMMAND_QUIT
    elif cmpIgnoreCase(input, ".help") == 0:
        echo "SQLNim: Available commands are:"
        echo ".exit"
        echo ".help"
        return META_COMMAND_SUCCESS
    else:
        return META_COMMAND_UNRECOGNIZED_COMMAND

proc prepareStatement(input: string, statement: var Statement): PrepareResult =
    ##[
    Prepare a statement to be executed as SQL
    ]##
    var 
        id: int
        username, email: string
        args = input.split(' ')

    try:
        id = parseInt(args[1])
    except ValueError:
        return PREPARE_SYNTAX_ERROR

    if args[0].cmpIgnoreCase("insert") == 0:
        statement.type = STATEMENT_INSERT
        statement.row_to_insert = new_row(id = id, username = args[2], email = args[3])
        #Compare to our row columns, plus one for the command
        if args.len.uint > numRows + 1:
            return PREPARE_SYNTAX_ERROR
        return PREPARE_SUCCESS

    if args[0].cmpIgnoreCase("select") == 0:
        statement.type = STATEMENT_SELECT
        return PREPARE_SUCCESS
    
    return PREPARE_UNRECOGNIZED_STATEMENT

proc execute_statement(statement: Statement, table: Table): ExecuteResult =
    var sel: ExecuteResult
    case statement.type
    of STATEMENT_INSERT:
        sel = execute_insert(statement, table)
    of STATEMENT_SELECT:
        sel = execute_select(statement, table)
    return sel

proc init() =
    var parser = initOptParser()
    main(parser)
    quit(QUITSUCCESS)

when isMainModule:
    import unittest, os, ospaths, streams
    from posix import dup, dup2, onSignal, SIGHUP

    proc run(): int =
        ## Test friendly version of init
        var parser = initOptParser()
        main(parser)
        return QUITSUCCESS

    suite "Application Tests":

        test "Application can insert a row":
            let 
                test_dir = getCurrentDir() / "tests/fixtures/"

            var
                saved_stdout = dup(1)
                saved_stdin = dup(0)
                saved_stderr = dup(2)
                in_test_filename = test_dir / "insert_testdata"
                out_test_filename = test_dir / "out_testdata"
                redir_stdin, redir_stdout, null_stderr: File

            stdin.flushFile
            stdout.flushFile
            stderr.flushFile
                
            redir_stdin = open(in_test_filename, fmRead)
            redir_stdout = open(out_test_filename, fmWrite)
            null_stderr = open("/dev/null", fmWrite)

            #Duplicate our stdin
            discard dup2(redir_stdin.getFileHandle, 0)
            discard dup2(redir_stdout.getFileHandle, 1)
            discard dup2(null_stderr.getFileHandle, 2)
            redir_stdout.close
            redir_stdin.close
            null_stderr.close

            checkpoint("Passing in STDIN")
            
            var result = run()
            check(result == QUITSUCCESS)
            stdout.flushFile

            discard dup2(saved_stdout, stdout.getFileHandle)
            discard dup2(saved_stdin, stdin.getFileHandle)
            discard dup2(saved_stderr, stderr.getFileHandle)

            redir_stdout = open(out_test_filename)

            checkpoint("Reading results")
            var success_counts = 0
            for line in redir_stdout.lines:
                if "Executed successfully" in line:
                    success_counts.inc
            redir_stdout.close

            redir_stdin = open(in_test_filename)
            var total_in_lines = 0
            for line in redir_stdin.lines:
                if line != ".exit":
                    total_in_lines.inc
            redir_stdin.close

            check(success_counts == total_in_lines)

        test "Test Meta Commands":
            var 
                exit = ".exit"
                help = ".help"
                fake = ".fake"
                meta_result: MetaCommandResult

            checkpoint("Testing .help")
            meta_result = doMetaCommand(help)
            check(meta_result == META_COMMAND_SUCCESS)

            checkpoint("Testing .exit")
            meta_result = doMetaCommand(exit)
            check(meta_result == META_COMMAND_QUIT)

            checkpoint("Testing .fake")
            meta_result = doMetaCommand(fake)
            check(meta_result == META_COMMAND_UNRECOGNIZED_COMMAND)

        test "Test PrepareStatement":
            var 
                p_result: PrepareResult
                statement: Statement = new Statement
                insert_statement = "insert 1 a a@a.a"
                select_statement = "select 1"
                invalid_statement = "select a a v d"
                unrecognized_statement = "anothercommand 1"


            checkpoint("Testing insert statement")
            p_result = prepareStatement(insert_statement, statement)
            check(p_result == PREPARE_SUCCESS)
            check(statement.type == STATEMENT_INSERT)

            checkpoint("Testing select statement")
            p_result = prepareStatement(select_statement, statement)
            check(p_result == PREPARE_SUCCESS)
            check(statement.type == STATEMENT_SELECT)

            checkpoint("Testing invalid statement")
            p_result = prepareStatement(invalid_statement, statement)
            check(p_result == PREPARE_SYNTAX_ERROR)
            check(statement.type == STATEMENT_SELECT)

            checkpoint("Testing unrecognized statement")
            p_result = prepareStatement(unrecognized_statement, statement)
            check(p_result == PREPARE_UNRECOGNIZED_STATEMENT)
            check(statement.type == STATEMENT_SELECT)

        test "Test ExecuteResult":
            var
                table = new_table()
                insert_statement, select_statement: Statement = new Statement
                e_result: ExecuteResult
                username = "Test"
                email = "Test@test.com"

            checkpoint("Testing INSERT statement")
            insert_statement.type = STATEMENT_INSERT
            insert_statement.row_to_insert = new_row(id = 1, username = username, email = email)

            e_result = execute_statement(insert_statement, table)
            check(e_result == EXECUTE_SUCCESS)

            select_statement.type = STATEMENT_SELECT

            e_result = execute_statement(select_statement, table)
            check(e_result == EXECUTE_SUCCESS)

