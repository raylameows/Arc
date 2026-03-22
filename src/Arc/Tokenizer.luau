local Tokenizer = {}

function Tokenizer.tokenize(input: string)
	local tokens = {}
	local current = ""
	local inQuotes = false
	local inBrackets = false
	local parenDepth = 0

	for i = 1, #input do
		local char = input:sub(i, i)

		if char == '"' and parenDepth == 0 and not inBrackets then
			inQuotes = not inQuotes
			current ..= char

		elseif char == "[" and not inQuotes and parenDepth == 0 then
			inBrackets = true
			current ..= char
		elseif char == "]" and inBrackets and parenDepth == 0 then
			inBrackets = false
			current ..= char

		elseif char == "(" and not inQuotes and not inBrackets then
			parenDepth += 1
			current ..= char
		elseif char == ")" and not inQuotes and not inBrackets then
			parenDepth -= 1
			current ..= char

		elseif char == " " and not inQuotes and not inBrackets and parenDepth == 0 then
			if #current > 0 then
				table.insert(tokens, current)
				current = ""
			end
		else
			current ..= char
		end
	end

	if #current > 0 then
		table.insert(tokens, current)
	end

	return tokens
end

return Tokenizer