#!/usr/local/bin/lua

local socket = require("socket")

local function interpret(code, tape)
	local tapeTable = {}
	local codeTable = {}

	for bit in tape:gmatch(".") do
		table.insert(tapeTable, bit)
	end
	
	-- parse the code and keep track of brackets
	local layer = 1
	for char in code:gmatch(".") do
		table.insert(codeTable, {
			cmd = char,
			layer = layer,
		})
		if char == "[" then
			layer = layer + 1
		elseif char == "]" then
			layer = layer - 1
		end
	end

	local pointer = 1
	local instruction = 1

	local commands = {
		[">"] = function() -- move pointer right
			pointer = pointer + 1
			instruction = instruction + 1
		end,
		["<"] = function() --  move pointer left
	    		pointer = pointer - 1
			instruction = instruction + 1
		end,
		["*"] = function() -- flip current bit
			tapeTable[pointer] = tapeTable[pointer] == "1" and "0" or "1"
			instruction = instruction + 1
		end,
		["["] = function() -- goto matching ] if current cell is 0
			if tapeTable[pointer] ~= "0" then 
				instruction = instruction + 1
				return 
			end
			local currentLayer = codeTable[instruction].layer
			repeat
				instruction = instruction + 1
			until instruction > #codeTable or codeTable[instruction].layer == currentLayer
		end,
		["]"] = function() -- goto matching [ if current cell is non-zero
			if tapeTable[pointer] == "0" then 
				instruction = instruction + 1
				return 
			end
			local currentLayer = codeTable[instruction].layer
			repeat
				instruction = instruction - 1
			until codeTable[instruction].layer == currentLayer - 1
		end,
	}

	local commandDesc = {
		[">"] = "move right",
		["<"] = "move left",
		["*"] = "flip bit",
		["["] = "jump fwd if zero",
		["]"] = "jump back if non-zero",
	}
	
	print("\n\n")
	local cmdCount = 0
	while 0 < pointer and pointer <= #tapeTable and instruction <= #codeTable do
		io.write("\27[2A")
		io.write("\27[G")
		io.write("\27[K") -- erase line
		io.write(table.concat(tapeTable) .. "   " .. code, "\n")
		io.write("\27[K") -- erase line
		io.write((" "):rep(pointer-1) .. "^" .. (" "):rep(#tapeTable-pointer+3) .. (" "):rep(instruction-1) .. "^")
		io.write("\n")
		io.flush()
		
		if cmdCount > 2^12 then
			print("MAX COMMAND COUNT EXCEEDED -- HALTING")
			break
		end

		local cmd = codeTable[instruction].cmd
		if commands[cmd] then 
			commands[cmd]() 
			cmdCount = cmdCount + 1
		else
			instruction = instruction + 1
		end
		socket.sleep(0.05)
	end
	print("")
	print("---STEPS TAKEN: ".. cmdCount .."---")
	print("---CODE DISASSEMBLY---")
	print("#", "BRACKET", "CMD", "DESCRIPTION")
	for i, v in ipairs(codeTable) do
		print(i, v.layer, v.cmd, commandDesc[v.cmd])
	end
	return table.concat(tapeTable)
end

local tape, code = ...
if tape == "" or code == "" then
	print("No code or tape entered.")
	return
end
print("Smallfuck interpreter:")
print("Code: "..code)
print("Tape: "..tape)
print("")
print("\nINPUT:  ".. tape .."\nRESULT: "..interpret(code, tape))
