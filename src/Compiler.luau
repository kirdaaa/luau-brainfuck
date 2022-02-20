--!strict
export type Bytecode = { op }

export type op = number

-- Holds data about source string during compilation
-- @field   source      Source string that is compiled
-- @field   length      Length of the source string
-- @field   position    Position of currently scanned character
-- @field   character   Currently scanned character
-- @field   loops       Array of BF loop begin positions
-- @field   pointer     Current position in the bytecode
-- @field   bytecode    BF Bytecode of the source string
type Reader = {
	source: string,
	length: number,
	position: number,
	character: string,
	loops: { number },
	pointer: number,
	bytecode: Bytecode
}

local OP_NONE = 0
local OP_CADD = 1
local OP_CSUB = 2
local OP_CNXT = 3
local OP_CPRV = 4
local OP_LBGN = 5
local OP_LEND = 6
local OP_IOWR = 7
local OP_IORD = 8

-- Callbacks executed for BF commands when scanning source string
local callbacks: { [string]: (Reader) -> () }

-- @param    source   Source string to be scanned
-- @return   Reader   Created reader
local function createReader(source: string): Reader
	return {
		source = source,
		length = #source,
		position = 0,
		character = "",
		loops = {},
		pointer = 0,
		bytecode = {}
	}
end

-- Reserves one field in reader's bytecode table
-- Used for loops when the data is unknown yet when the command is pushed
-- @param    reader   Reader in which to reserve the field
local function readerReserve(reader: Reader)
	reader.pointer += 1
end

-- Pushes command to reader bytecode
-- @param   reader   Reader to push command to
-- @param   op       OP code of command to be pushed
-- @param   data     Optional command data
local function readerPush(reader: Reader, value: number)
	readerReserve(reader)
	table.insert(reader.bytecode, reader.pointer, value)
end

local function SCAN_CADD(reader: Reader)
	readerPush(reader, OP_CADD)
end

local function SCAN_CSUB(reader: Reader)
	readerPush(reader, OP_CSUB)
end

local function SCAN_CNXT(reader: Reader)
	readerPush(reader, OP_CNXT)
end

local function SCAN_CPRV(reader: Reader)
	readerPush(reader, OP_CPRV)
end

local function SCAN_LBGN(reader: Reader)
	readerPush(reader, OP_LBGN)
	readerReserve(reader)

	table.insert(reader.loops, reader.pointer - 1)
end

local function SCAN_LEND(reader: Reader)
	local jump = assert(
		table.remove(reader.loops),
		"found ']' without matching '['"
	)

	readerPush(reader, OP_LEND)
	readerPush(reader, jump)

	reader.bytecode[jump + 1] = reader.pointer + 1
end

local function SCAN_IOWR(reader: Reader)
	readerPush(reader, OP_IOWR)
end

local function SCAN_IORD(reader: Reader)
	readerPush(reader, OP_IORD)
end

-- Advances to next reader character to scan
-- Returns false if there are no more characters to be scanned
-- @param    reader    Reader to advance
-- @return   boolean   Are there any more characters to be scanned
local function readerAdvance(reader: Reader): boolean
	if reader.position == reader.length then
		return false
	end

	local position = reader.position + 1

	reader.position = position
	reader.character = string.sub(reader.source, position, position)

	return true
end

-- Converts reader's currently scanned character to bytecode if possible
-- @param   reader   Reader which should be processed
local function readerProcess(reader: Reader)
	local callback = callbacks[reader.character]

	if not callback then
		return
	end

	callback(reader)
end

-- Compiles string to BF bytecode
-- @param    source     Source string to compile
-- @return   Bytecode   Compiled bytecode
local function compile(source: string): Bytecode
	local reader = createReader(source)

	while readerAdvance(reader) do
		readerProcess(reader)
	end

	assert(#reader.loops == 0, "unclosed '['")

	return reader.bytecode
end

callbacks = {
	["+"] = SCAN_CADD,
	["-"] = SCAN_CSUB,
	[">"] = SCAN_CNXT,
	["<"] = SCAN_CPRV,
	["["] = SCAN_LBGN,
	["]"] = SCAN_LEND,
	["."] = SCAN_IOWR,
	[","] = SCAN_IORD
}

local Compiler = {}

Compiler.OP_NONE = OP_NONE
Compiler.OP_CADD = OP_CADD
Compiler.OP_CSUB = OP_CSUB
Compiler.OP_CNXT = OP_CNXT
Compiler.OP_CPRV = OP_CPRV
Compiler.OP_LBGN = OP_LBGN
Compiler.OP_LEND = OP_LEND
Compiler.OP_IOWR = OP_IOWR
Compiler.OP_IORD = OP_IORD

Compiler.compile = compile

return Compiler
