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

    while true:
        printPrompt()
        input_line = stdin.readLine()
        #input_line = "insert 1 a a"

        if input_line.startsWith("."):
            case doMetaCommand(input_line)
            of META_COMMAND_SUCCESS:
                continue
            of META_COMMAND_UNRECOGNIZED_COMMAND:
                stderr.writeLine "Unrecognized command: " & input_line
                continue
        
        case prepareStatement(input_line, statement)
        of PREPARE_SUCCESS:
            stderr.writeLine "Command success"
        of PREPARE_UNRECOGNIZED_STATEMENT:
            stderr.writeLine &"Unrecognized keyword at start of '{input_line}'" 
            continue
        of PREPARE_SYNTAX_ERROR:
            stderr.writeLine &"Syntax error in '{input_line}'"
            continue

        case execute_statement(statement, table)
        of EXECUTE_SUCCESS:
            stdout.writeLine("Executed successfully")
            stdout.flushFile
        of EXECUTE_TABLE_FULL:
            stderr.writeLine("Error: Table Full")
            stderr.flushFile

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
        id: uint64
        username, email: cstring
        args = input.split(' ')

    id = parseUInt(args[1]).uint64

    if args[0].cmpIgnoreCase("insert") == 0:
        statement.type = STATEMENT_INSERT
        statement.row_to_insert = new_row(id = id, username = args[2], email = args[3])
        #Compare to our row columns, plus one for the command
        echo $statement.row_to_insert
        if args.len.uint > numRows + 1:
            return PREPARE_SYNTAX_ERROR
        return PREPARE_SUCCESS

    if args[0].cmpIgnoreCase("select") == 0:
        statement.type = STATEMENT_SELECT
        return PREPARE_SUCCESS
    
    return PREPARE_UNRECOGNIZED_STATEMENT

proc execute_statement(statement: Statement, table: Table): ExecuteResult =
    case statement.type
    of STATEMENT_INSERT:
        execute_insert(statement, table)
    of STATEMENT_SELECT:
        execute_select(statement, table)

when isMainModule:
    var parser = initOptParser()
    main(parser)
