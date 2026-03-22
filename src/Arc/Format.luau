local Format = {}

function Format.apply(text, arc)
	local tokens = arc.Tokenizer.tokenize(text)
	local result = ``
	local current = arc.Commands
	local topLevel = arc.State.CurrentTopLevel or `arc`

	for i, token in tokens do
		local styledToken = token

		if token:match('^".-"$') then
			styledToken = `<font color="rgb(85,255,127)">{token}</font>`
		elseif token:match(`^%b[]$`) then
			styledToken = `<font color="rgb(85,170,255)">{token}</font>`
		elseif token:match(`^%b()$`) then
			styledToken = token:gsub("#([%w_]+)", `<font color="rgb(200,150,255)">#%1</font>`)
			styledToken = `<font color="rgb(255,170,0)">{styledToken}</font>`
		elseif token:match("^#([%w_]+)$") then
			styledToken = `<font color="rgb(200,150,255)">{token}</font>`
		elseif token == `true` or token == `false` then
			styledToken = `<font color="rgb(255,120,200)"><b>{token}</b></font>`
		else
			local word = token:match(`^([%w_]+)`)
			if word and current[word] then
				local command = current[word]
				if command.color and not command.style then
					command.style = `<font color="rgb({math.round(command.color.R*255)},{math.round(command.color.G*255)},{math.round(command.color.B*255)})">COMMAND</font>`
				end
				if command.style then
					if typeof(command.style) == `string` then
						styledToken = token:gsub(word, command.style:gsub(`COMMAND`, word), 1)
					else
						styledToken = token:gsub(
							word,
							command.style(word, {arc = arc, top = topLevel}),
							1
						)
					end
				end
				if command.subcommands then
					current = command.subcommands
				else
					current = {}
				end
			end
		end

		result ..= styledToken
		if i < #tokens then
			result ..= ` `
		end
	end

	return result
end

function Format.pipeline(text, arc)
	local parts = string.split(text, "|")
	for i, part in parts do
		parts[i] = Format.apply(part:match("^%s*(.-)%s*$"), arc)
	end
	return table.concat(parts, " | ")
end

return Format