local Parser = {}

function Parser.resolveCommand(commands, tokens)
	local current = commands
	local last

	while #tokens > 0 do
		local cmd = current[tokens[1]]
		if not cmd then break end

		table.remove(tokens, 1)
		last = cmd

		current = cmd.subcommands or {}
	end

	return last, tokens
end

function Parser.parseArguments(command, tokens)
	local positionals = {}
	local flags = {}

	local function clean(token)
		if typeof(token) ~= "string" then return token end
		token = token:gsub('^"(.-)"$', '%1')
		token = token:gsub('^%[(.-)%]$', '%1')
		return token
	end

	local i = 1
	while i <= #tokens do
		local token = tokens[i]
		if tostring(token):sub(1,1) == "-" then
			flags[token] = true
		else
			table.insert(positionals, clean(token))
		end
		i += 1
	end

	return positionals, flags
end

return Parser