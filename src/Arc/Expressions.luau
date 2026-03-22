local Expressions = {}

function Expressions.evaluate(tokens, state)
	for i, token in tokens do
		local str = tostring(token)

		if not str:match("^#") then
			local success, result = pcall(function()
				local expr = str:gsub("#([%w_]+)", function(key)
					local val = state.Memory[key]
					if val == nil then error(`Unknown memory {key}`) end
					return tostring(val)
				end)

				if expr:match("^[0-9%+%-%*/%^%(%)%. ]+$") then
					return loadstring(`return {expr}`)()
				end
			end)

			if success and result ~= nil then
				tokens[i] = result
			end
		end
	end

	return tokens
end

return Expressions