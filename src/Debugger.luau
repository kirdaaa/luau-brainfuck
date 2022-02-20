--!strict
local Compiler = require("src/Compiler")

local unique: { number } = { Compiler.OP_LBGN, Compiler.OP_LEND }

local readable: { [number]: string } = {
	[Compiler.OP_CADD] = "CELL_ADD",
	[Compiler.OP_CSUB] = "CELL_SUB",
	[Compiler.OP_CNXT] = "CELL_NEXT",
	[Compiler.OP_CPRV] = "CELL_PREV",
	[Compiler.OP_LBGN] = "LOOP_BEGIN",
	[Compiler.OP_LEND] = "LOOP_END",
	[Compiler.OP_IOWR] = "IO_WRITE",
	[Compiler.OP_IORD] = "IO_READ"
}

-- Converts BF bytecode into human readable string
-- @param   bytecode   Bytecode to convert
-- @param   string     Human readable bytecode
local function formatReadable(bytecode: Compiler.Bytecode): string
	local lines = {}
	local raw = false

	for index, data in pairs(bytecode) do
		local line: string

		if raw then
			line = string.format("%- 10d DATA(%d)", index, data)
			raw = false
		else
			line = string.format("%- 10d %s", index, readable[data] or "?")
		end

		if table.find(unique, data) then
			raw = true
		end

		table.insert(lines, line)
	end

	return table.concat(lines, "\n")
end

local Debugger = {}

Debugger.formatReadable = formatReadable

return Debugger
