--!strict

local Compiler = require("Compiler")

-- Holds data about currently executed program
-- @field   tape   BF value cells
type State = {
	tape: { number }
}

-- @param    memory   Amount of value cells; defaults to 30000
-- @return   State    Created state
local function createState(memory: number?): State
	return {
		tape = table.create(memory or 30000)
	}
end

-- Executes BF bytecode
-- @param   bytecode   Bytecode to execute
local function execute(bytecode: Compiler.Bytecode)
end

local Machine = {}

Machine.execute = execute

return Machine
