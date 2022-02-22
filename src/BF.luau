-- Brainoof language compiler and executer

--!strict
export type Bytecode = { op | data }

export type data = number
export type op = number

type Program = {
    overflow: number,
    bytecode: Bytecode,
    position: position,
    tape: { cell },
    memory: number,
    pointer: position,
    input: { number },
    argument: position,
    output: { number }
}

type Parser = {
    bytecode: Bytecode,
    position: position,
    loops: { position }
}

type reader = (Parser, op?) -> op
type command = (Program) -> ()

type position = number
type cell = number

type symbol = string

local OP_NONE = 0
local OP_ADDC = 1
local OP_SUBC = 2
local OP_NXTC = 3
local OP_PRVC = 4
local OP_BGNL = 5
local OP_ENDL = 6
local OP_SETO = 7
local OP_GETI = 8

-- For every BF syntax symbol there is associated function which will
-- get executed when the symbol is parsed
local readers: { [symbol]: reader }

-- For every OP code there is associated function which will get executed
-- whenever reads the code
local commands: { [op]: command }

local function create_parser(): Parser
    return {
        bytecode = {},
        position = 0,
        loops = {}
    }
end

-- Pushes value to parser's bytecode
local function parser_push(parser: Parser, value: op | data)
    parser.position += 1
    parser.bytecode[parser.position] = value
end

local function parser_alloc(parser: Parser)
    parser.position += 1
end

-- Reader function is equal to primite BF commands so it is merged into
-- single function to prevent code duplication
local function reader_simple(op: op): reader
    return function(parser, previous_op)
        if op == previous_op then
            -- Increment duplicate count for continuous instructions
            parser.bytecode[parser.position] += 1
        else
            parser_push(parser, op)
            parser_push(parser, 1)
        end

        return op
    end
end

local function reader_BGNL(parser: Parser): op
    parser_push(parser, OP_BGNL)
    -- Reserve empty field because we don't know position of loop end yet
    parser_alloc(parser)

    table.insert(parser.loops, parser.position)

    return OP_BGNL
end

local function reader_ENDL(parser: Parser): op
    local jump = assert(
        table.remove(parser.loops),
        "too many ']'"
    )

    parser_push(parser, OP_ENDL)
    parser_push(parser, jump)

    -- Fill loop end position at loop beginning
    parser.bytecode[jump] = parser.position

    return OP_ENDL
end

local function compile(source: string): Bytecode
    local parser = create_parser()
    -- Previous OP code is saved to merge continuous instructions into one
    local previous_op = OP_NONE

    for position = 1, #source do
        local character = string.sub(source, position, position)
        local reader: reader? = readers[character]

        -- Readers are nil for characters that are not part of BF syntax
        if reader then
            previous_op = reader(parser, previous_op)
        end
    end

    assert(#parser.loops == 0, "unclosed '['")

    return parser.bytecode
end

local function create_program(
    bytecode: Bytecode,
    input: { number }?,
    memory: number | any,
    overflow: number?
): Program
    memory = memory or 30000

    return {
        overflow = overflow or 0b11111111,
        bytecode = bytecode,
        position = 0,
        tape = table.create(memory, 0),
        memory = memory,
        pointer = 1,
        input = input or {},
        argument = 0,
        output = {}
    }
end

-- Returns next value from program bytecode
local function program_next(program: Program): op | data
    program.position += 1

    return program.bytecode[program.position]
end

local function command_ADDC(program: Program)
    local value = program.tape[program.pointer] + program_next(program)
    program.tape[program.pointer] = value % program.overflow
end

local function command_SUBC(program: Program)
    local value = program.tape[program.pointer] - program_next(program)
    program.tape[program.pointer] = value % program.overflow
end

local function command_NXTC(program: Program)
    assert(program.pointer < program.memory, "pointer overflow")
    program.pointer += program_next(program)
end

local function command_PRVC(program: Program)
    assert(program.pointer > 0, "pointer underflow")
    program.pointer -= program_next(program)
end

local function command_BGNL(program: Program)
    local data = program_next(program)

    if program.tape[program.pointer] ~= 0 then
        return
    end

    program.position = data
end

local function command_ENDL(program: Program)
    local data = program_next(program)

    if program.tape[program.pointer] == 0 then
        return
    end

    program.position = data
end

local function command_SETO(program: Program)
    local value = program.tape[program.pointer]

    -- Duplicate value of current cell to then append it to program output
    local values = table.create(program_next(program), value)

    table.move(values, 1, #values, #program.output + 1, program.output)
end

local function command_GETI(program: Program)
    program.argument += program_next(program)
    program.tape[program.pointer] = program.input[program.argument] or 0
end

local function execute(
    bytecode: Bytecode,
    input: { number }?,
    memory: number?,
    overflow: number?
): { number }
    assert(if memory then memory > 0 else true, "memory is too small")

    local program = create_program(bytecode, input, memory, overflow)
    local size = #program.bytecode

    while program.position ~= size do
        local op = program_next(program)
        local command = commands[op]

        command(program)
    end

    return program.output
end

local function to_ascii(output: { number }): string
    local result = string.char(output[1])

    for i = 2, #output do
        result ..= string.char(output[i])
    end

    return result
end

readers = {
    ["+"] = reader_simple(OP_ADDC),
    ["-"] = reader_simple(OP_SUBC),
    [">"] = reader_simple(OP_NXTC),
    ["<"] = reader_simple(OP_PRVC),
    ["["] = reader_BGNL,
    ["]"] = reader_ENDL,
    ["."] = reader_simple(OP_SETO),
    [","] = reader_simple(OP_GETI)
}

commands = {
    [OP_ADDC] = command_ADDC,
    [OP_SUBC] = command_SUBC,
    [OP_NXTC] = command_NXTC,
    [OP_PRVC] = command_PRVC,
    [OP_BGNL] = command_BGNL,
    [OP_ENDL] = command_ENDL,
    [OP_SETO] = command_SETO,
    [OP_GETI] = command_GETI
}

local BF = {}

-- Compiles BF source string into BF bytecode
-- @param    source     String to compile
-- @return              Compiled bytecode
BF.compile = compile

-- Executes BF bytecode and returns program output
-- @param    bytecode     Bytecode to execute
-- @param    input        Program input which is array of numbers
-- @param    memory       Amount of cells in the program (default 30000)
-- @param    overflow     Maximal call value (default 255)
-- @return                Program output
BF.execute = execute

-- Converts array of bytes returned from 'execute' into string
-- @param    output   Array of bytes to convert
-- @return   string   ASCII output
BF.to_ascii = to_ascii

return BF
