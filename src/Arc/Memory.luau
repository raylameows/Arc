local Memory = {}

function Memory.resolve(tokens, state)
	for i, token in tokens do
		local key = token:match("^#([%w_]+)$")
		if key then
			local value = state.Memory[key]
			if value == nil then
				return nil, `Unknown memory #{key}`
			end
			tokens[i] = value
		end
	end
	return tokens
end

return Memory