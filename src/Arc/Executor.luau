local Executor = {}

local function buildNamedArgs(command, positionals)
	if not command.args then
		return positionals
	end

	local named = {}

	for argName, info in command.args do
		if info.order then
			named[argName] = positionals[info.order]
		end
	end

	return named
end

function Executor.run(input, services)
	local Tokenizer = services.Tokenizer
	local Parser = services.Parser
	local Memory = services.Memory
	local Expressions = services.Expressions

	local state = services.State
	local Commands = services.Commands
	local Output = services.Output

	local pipeline = string.split(input, "|")

	for _, cmdText in pipeline do
		cmdText = cmdText:match("^%s*(.-)%s*$")
		if cmdText == "" then continue end

		local tokens = Tokenizer.tokenize(cmdText)

		local resolved, err = Memory.resolve(tokens, state)
		if not resolved then
			Output:Fire(cmdText.."\n"..err)
			return
		end

		tokens = Expressions.evaluate(resolved, state)

		local command, remaining = Parser.resolveCommand(Commands, tokens)

		if not command or not command.run then
			Output:Fire(cmdText.."\nUnknown command")
			return
		end

		local positionals, flags = Parser.parseArguments(command, remaining)
		local args = buildNamedArgs(command, positionals)

		local success, result = pcall(function()
			return command.run({
				args = args,
				flags = flags,
				state = state,
				services = services,
				Arc = services,
			})
		end)

		if not success then
			Output:Fire(cmdText.."\n"..result)
			continue
		end

		if result then
			Output:Fire(cmdText.."\n"..tostring(result))
		end
	end
end

return Executor