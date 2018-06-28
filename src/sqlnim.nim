# sqlnim
# Copyright Ryanc_signiq
# A nim sql implementation
import parseopt, strutils, strformat, marshal, macros
import sqlnim/table, sqlnim/row, sqlnim/shared 

type
    MetaCommandResult = enum
        META_COMMAND_SUCCESS,
        META_COMMAND_UNRECOGNIZED_COMMAND


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
                quit(QUITSUCCESS)
            of "version", "v": 
                writeVersion()
                quit(QUITSUCCESS)
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
        quit(QUITSUCCESS)
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
        username, email: cstring
        args = input.split(' ')

    id = parseInt(args[1])

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

when isMainModule:
    import unittest, os, ospaths, streams, memfiles
    from posix import dup, dup2

    suite "Application Tests":

        setup:
            echo "Starting Test"
            let 
                test_dir = getCurrentDir() / "tests/fixtures/"
                saved_stdout = dup(1)
                saved_stdin = dup(0)
            var
                test_stdout: MemFile

        teardown:
            close(stdin)
            discard dup2(saved_stdin, 0) 
            
        test "Application can insert a row":
            var 
                in_test_filename = test_dir / "insert_testdata"
                out_test_filename = test_dir / "out_testdata"
                redir_stdin, redir_stdout: File
                


            redir_stdin = system.open(in_test_filename, fmRead)
            redir_stdout = system.open(out_test_filename, fmWrite)
            #Duplicate our stdin
            stderr.writeLine($getFileInfo(stdout).id.file)
            discard dup2(getFileHandle(redir_stdin), 0)
            discard dup2(getFileHandle(redir_stdout), 1)
            stderr.writeLine($getFileInfo(stdout).id.file)

            checkpoint("Passing in STDIN")
            
            init()

            close(stdout)
            close(redir_stdout)
            discard dup2(saved_stdout, 1)
            stderr.writeLine($getFileInfo(stdout).id.file)
            checkpoint("Reading results")
            var success_counts = 0
            for line in redir_stdout.lines:
                stderr.writeLine(line)
                if "Executed successfully" in line:
                    success_counts.inc



            redir_stdin.setFilePos(0)
            var total_in_lines = 0
            for line in redir_stdin.lines:
                total_in_lines.inc

            check success_counts == total_in_lines

        test "Application can select a row":
            echo "Test 2"

        test "Application can insert, then select a row":
            echo "Test 3"
