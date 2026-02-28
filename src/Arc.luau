local Selection = game:GetService("Selection")

local Atlas = require(`./Util/Atlas`)
local GoodSignal = require(`./Util/GoodSignal`)
local Arc = {}
Arc.Active = false	
Arc.Plugin = nil :: Plugin
Arc.Widget = nil :: DockWidgetPluginGui
Arc.Fired = GoodSignal.new()
Arc.Output = GoodSignal.new()
Arc.Activated = GoodSignal.new()
Arc.Cache = {}
Arc.Private = {}

Arc.Private.Contexts = {}
Arc.Private.Memory = {}

export type Command = {
	run: (data: {[string]: any}) -> any,
	style: string | (word: string) -> string,
}
export type Commands = {
	[string]: Command
}
Arc.Commands = {
	[`arc`] = {
		style = `<b><font color="rgb(150,150,150)">COMMAND</font></b>`,
		subcommands = {
			[`exit`] = {
				style = `<font color="rgb(255,178,178)"><b>COMMAND</b></font>`,
				run = function(data: {[string]: any})
					data.arc.Plugin:Deactivate()
					return
				end,
			},
			[`clear`] = {
				color = Color3.fromRGB(85, 170, 127),
				flags = {
					absolute = {short = `a`}
				},
				run = function(data: {[string]: any})
					for _, item in (Arc.Cache) do
						item:Destroy()
					end
					table.clear(Arc.Cache)
					task.wait()
					return not data.flags.absolute and `Output cleared`
				end,
			},
			[`reload`] = {
				color = Color3.fromRGB(255, 255, 127),
				run = function(data: {[string]: any})
					data.arc.Plugin:Deactivate()
					task.wait()
					data.arc.Active = true
					data.arc.Widget.Enabled = true
					data.arc.Activated:Fire()
					data.arc.Plugin:Activate(true)
					return `Reloaded`
				end,
			},
			[`wait`] = {
				color = Color3.fromRGB(17, 187, 215),
				args = {
					time = {order = 1, type = `number`}
				},
				run = function(data)
					task.wait(tonumber(data.args.time) or 1)
					return `Waited {data.args.time or 1} seconds`
				end
			},
			[`remember`] = {
				color = Color3.fromRGB(116, 82, 127),
				args = {
					key = {order = 1},
					value = {order = 2},
				},
				run = function(data)
					local key = data.args.key
					local value = data.args.value

					local asNumber = tonumber(value)
					if asNumber then
						value = asNumber
					end

					Arc.Private.Memory[key] = value
					return `Remembered #{key} = {value}`
				end
			},
			[`print`] = {
				color = Color3.fromRGB(17, 187, 215),
				args = {arg = {order = 1}},
				run = function(data)
					return `{data.args.arg}`
				end
			},
			[`memory`] = {
				style = `<font color="rgb(255,170,255)">COMMAND</font>`,
				args = {arg = {order = 1}},
				run = function(data)
					local memories = ``
					for k,v in (Arc.Private.Memory) do
						if memories ~= `` then memories ..= `\n` end
						memories ..= `{k}: {v}`
					end

					return memories ~= `` and memories
				end
			}
		},
		run = function()
			return `arc :3`
		end,
	},

	[`studio`] = {
		style = `<font color="rgb(85,170,255)">COMMAND</font>`,
		context = {type = `Instance`},
		subcommands = {
			[`select`] = {
				style = `<font color="rgb(255,178,178)"><b>COMMAND</b></font>`,
				args = {
					path = {order = 1, type = `path`}
				},
				run = function(data)
					local selection = data.args.path and {data.args.path} or Selection:Get()
					if #selection > 0 then
						return {
							response = `Context set to {selection[1]:GetFullName()}`,
							context = selection[1]
						}
					else
						return {
							response = `Studio context cleared`,
							context = false
						}
					end
				end
			},
			[`query`] = {
				style = `<font color="rgb(255,178,178)"><b>COMMAND</b></font>`,
				args = {
					selector = {order = 1}
				},
				flags = {},
				run = function(data: {[string]: any})
					local root = Arc.Private.Contexts.studio or workspace
					local queried = root:QueryDescendants(data.args.selector)
					Selection:Set(queried)

					return `Selected {#queried} instances`
				end,
			},
		},
	},
} :: Commands

function Arc.getValueType(value, expectedType)
	if not expectedType then
		return value
	end

	if expectedType == `boolean` then
		if typeof(value) == `boolean` then
			return value
		end
		if typeof(value) == `string` then
			local lower = string.lower(value :: string)
			if lower == `true` then return true end
			if lower == `false` then return false end
		end
		error(`Invalid boolean value "{value}"`)
	end

	if expectedType == `number` then
		local n = tonumber(value)
		if not n then
			error(`Invalid number "{value}"`)
		end
		return n
	end

	return value
end

function Arc.evaluateExpressions(tokens)
	for i, token in (tokens) do
		local tokenStr = tostring(token)

		if not tokenStr:match(`^#`) then
			local success, result = pcall(function()
				local expr = tokenStr:gsub(`#([%w_]+)`, function(key)
					local val = Arc.Private.Memory[key]
					if val == nil then error(`Unknown memory {key}`) end
					return tostring(val)
				end)

				if expr:match(`^[0-9%+%-%*/%^%(%)%. ]+$`) then
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

function Arc.resolveMemory(tokens)
	for i, token in (tokens) do
		local memoryKey = token:match(`^#([%w_]+)$`)
		if memoryKey then
			local value = Arc.Private.Memory[memoryKey]
			if value == nil then
				return nil, `Unknown memory #{memoryKey}`
			end
			tokens[i] = value
		end
	end
	return tokens
end

function Arc.applyRichTextPipeline(text)
	local parts = string.split(text, `|`)
	for i, part in (parts) do
		parts[i] = Arc.applyRichText(part:match(`^%s*(.-)%s*$`))
	end
	return table.concat(parts, ` | `)
end

function Arc.resolvePath(rawPath: string, context: Instance?)
	local current = nil
	local remaining = rawPath
	if remaining:match(`^@context`) then
		if not context or typeof(context) ~= `Instance` then
			return nil, `No valid context set`
		end
	end

	while true do
		local keyword, param = remaining:match(`^(@[%w_]+)%s*%((%d+)%)`)
		if not keyword then
			keyword = remaining:match(`^(@[%w_]+)`)
		end
		param = tonumber(param) or 1
		if not keyword then break end

		if keyword == `@context` then
			if not context then return nil, `No context set` end
			current = context
		elseif keyword == `@workspace` then
			current = workspace
		elseif keyword == `@game` then
			current = game
		elseif keyword == `@self` then
			if not current then return nil, `@self has no base` end
		elseif keyword == `@selection` then
			local sel = Selection:Get()
			if #sel == 0 then return nil, `No selection` end
			if param < 1 or param > #sel then
				return nil, `Selection index {param} out of range`
			end
			current = sel[param]
		else
			return nil, `Unknown keyword {keyword}`
		end

		local paramLen = 0
		if remaining:sub(#keyword+1, #keyword+1) == `(` then
			local _, e = remaining:find(`^%([%d]+%)`)
			paramLen = e or 0
		end
		remaining = remaining:sub(#keyword + paramLen + 1)
	end

	while remaining:sub(1,1) == `^` do
		local upCount = tonumber(remaining:match(`^%^([%d]+)`)) or 1
		for _ = 1, upCount do
			if not current or not current.Parent then return nil, `Cannot go above root` end
			current = current.Parent
		end
		local _, e = remaining:find(`^%^%d+`)
		remaining = remaining:sub(e+1)
	end

	if remaining:sub(1,1) == `.` then
		remaining = remaining:sub(2)
	end

	if remaining ~= `` then
		local segments = string.split(remaining, `.`)
		for _, segment in segments do
			if segment ~= `` then
				if not current then
					return nil, `No base for traversal`
				end

				current = current:FindFirstChild(segment)
				if not current then
					return nil, `Missing child "{segment}"`
				end
			end
		end
	end

	return current
end

function Arc.buildNamedArgs(command, positionals)
	if not command.args then
		return positionals
	end

	local named = {}

	for argName, info in command.args do
		if info.order then
			local raw = positionals[tonumber(info.order)]

			if raw ~= nil and info.type then
				local success, parsed = pcall(function()
					return Arc.getValueType(raw, info.type)
				end)

				if success then
					named[argName] = parsed
				else
					error(parsed)
				end
			else
				named[argName] = raw
			end
		end
	end

	return named
end

function Arc.highlightStrings(text: string)
	local result = ``
	local inQuotes = false

	for i = 1, #text do
		local char = text:sub(i, i)

		if char == '`' then
			if not inQuotes then
				result ..= `<font color="rgb(85,255,127)">"`
				inQuotes = true
			else
				result ..= `"</font>`
				inQuotes = false
			end
		else
			result ..= char
		end
	end

	return result
end

function Arc.tokenize(input: string)
	local tokens = {}
	local current = ``
	local inQuotes = false
	local inBrackets = false
	local parenDepth = 0

	for i = 1, #input do
		local char = input:sub(i, i)
		if char == '"' and parenDepth == 0 and not inBrackets then
			inQuotes = not inQuotes
			current ..= char

		elseif char == `[` and not inQuotes and parenDepth == 0 then
			inBrackets = true
			current ..= char
		elseif char == `]` and inBrackets and parenDepth == 0 then
			inBrackets = false
			current ..= char

		elseif char == `(` and not inQuotes and not inBrackets then
			parenDepth += 1
			current ..= char
		elseif char == `)` and not inQuotes and not inBrackets then
			parenDepth -= 1
			current ..= char

		elseif char == ` ` and not inQuotes and not inBrackets and parenDepth == 0 then
			if #current > 0 then
				table.insert(tokens, current)
				current = ``
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

function Arc.parseArguments(command, tokens)
	local positionals = {}
	local flags = {}
	local i = 1

	local function resolveFlag(name)
		if not command.flags then return nil end
		for longName, info in command.flags do
			if longName == name or info.short == name then
				return longName, info
			end
		end
	end

	local function cleanToken(token)
		if typeof(token) ~= `string` then
			return token
		end

		local s = token:gsub('^"(.-)"$', '%1')
		s = s:gsub('^%[(.-)%]$', '%1')
		return s
	end

	while i <= #tokens do
		local token = tokens[i]

		local tokenStr = tostring(token)
		local isLong = tokenStr:sub(1,2) == `--`
		local isShort = tokenStr:sub(1,1) == `-` and not isLong

		if isLong or isShort then
			local name = tokenStr:sub(isLong and 3 or 2)
			local resolved, info = resolveFlag(name)

			if not resolved then
				return nil, nil, `Unknown flag {tokenStr}`
			end

			local nextToken = tokens[i + 1]
			local value
			if info.type == `boolean` then
				if nextToken and not nextToken:match(`^%-`) then
					local cleaned = cleanToken(nextToken)

					local success, parsed = pcall(function()
						return Arc.getValueType(cleaned, `boolean`)
					end)

					if success then
						value = parsed
						i += 1
					else
						value = true
					end
				else
					value = true
				end
			else
				if not nextToken or nextToken:match(`^%-`) then
					return nil, nil, `Flag {tokenStr} requires a value`
				end

				i += 1
				value = cleanToken(nextToken)
			end

			flags[resolved] = value
		else
			table.insert(positionals, cleanToken(token))
		end

		i += 1
	end

	return positionals, flags
end

function Arc.applyRichText(text: string)
	local tokens = Arc.tokenize(text)
	local result = ``
	local current = Arc.Commands
	local topLevel = Arc.Private.CurrentTopLevel or `arc`

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
							command.style(word, { arc = Arc, top = topLevel }),
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

function Arc.resolveCommand(rootCommands, tokens)
	local current = rootCommands
	local lastCommand = nil

	while #tokens > 0 do
		local nextToken = tokens[1]
		local nextCommand = current[nextToken]

		if not nextCommand then
			break
		end

		table.remove(tokens, 1)
		lastCommand = nextCommand

		if nextCommand.subcommands then
			current = nextCommand.subcommands
		else
			break
		end
	end

	return lastCommand, tokens
end

function Arc.updateContentPrefix(writer, visual, dummyMeasure, contextLabel)
	local tokens = Arc.tokenize(writer.Text)
	local commandName = tokens[1]
	local context = Arc.Private.Contexts[commandName]

	if context then
		local contextText = `[{context:GetFullName()}] `
		contextLabel.Text = contextText
		dummyMeasure.Text = contextText

		local textWidth = dummyMeasure.TextBounds.X
		contextLabel.Size = UDim2.new(0, textWidth, 0, 25)

		writer.Position = UDim2.new(0, textWidth, 0, 0)
		writer.Size = UDim2.new(1, -textWidth, 0, 25)

		visual.Position = writer.Position
		visual.Size = writer.Size
	else
		contextLabel.Text = ``
		contextLabel.Size = UDim2.new(0, 0, 0, 25)

		writer.Position = UDim2.new(0, 0, 0, 0)
		writer.Size = UDim2.new(1, 0, 0, 25)

		visual.Position = writer.Position
		visual.Size = writer.Size
	end
end

function Arc.widget(widget: DockWidgetPluginGui)
	Arc.Widget = widget
	widget.Title = `Arc`
	widget.Name = `Arc Terminal`

	local textSettings = {
		Size = UDim2.new(1, 0, 0, 25),
		Font = Enum.Font.Code,
		BackgroundTransparency = 0.9,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextYAlignment = Enum.TextYAlignment.Center,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextSize = 17,
		Parent = widget
	}

	local output = Atlas.create(`ScrollingFrame`, {
		Size = UDim2.new(1, 0, 1, -25),
		Position = UDim2.new(0, 0, 0, 25),
		BackgroundTransparency = 1,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		TopImage 	= `rbxassetid://130227998672455`,
		MidImage 	= `rbxassetid://130227998672455`,
		BottomImage = `rbxassetid://130227998672455`,
		ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255),
		ScrollBarThickness = 3,
		ScrollBarImageTransparency = 0.95,
		BorderSizePixel = 0,
		Parent = widget,
		Children = {
			Atlas.create(`UIListLayout`, {
				SortOrder = Enum.SortOrder.LayoutOrder,	
			}),
		}
	})

	Arc.Output:Connect(function(text: string)
		local split = string.split(text, `\n`)
		if #split >= 2 then
			split[1], split[2] = split[2], split[1]
		end

		if #Arc.Cache ~= 0 then
			table.insert(split, 1, ``)
		end

		for i,line in (split) do
			table.insert(Arc.Cache, Atlas.create(`TextLabel`, {
				Size = UDim2.new(1, 0, 0, 20),
				Font = Enum.Font.Code,
				BackgroundTransparency = 1,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextYAlignment = Enum.TextYAlignment.Center,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextSize = 17,
				Text = `{i == #split and `>` or ``}{i == #split and Arc.applyRichText(line) or line}`,
				RichText = i == #split and true or false,
				LayoutOrder = -#Arc.Cache,
				Parent = output
			}))
		end
	end)

	local contextLabel: TextLabel = Atlas.create(`TextLabel`, {
		Size = UDim2.new(0, 0, 0, 25),
		Font = Enum.Font.Code,
		BackgroundTransparency = 0.9,
		TextColor3 = Color3.fromRGB(180, 180, 180),
		TextYAlignment = Enum.TextYAlignment.Center,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextSize = 17,
		RichText = true,
		Parent = widget
	})
	local writer: TextBox = Atlas.create(`TextBox`, textSettings)
	local visual: TextLabel = Atlas.create(`TextLabel`, textSettings)
	visual.RichText = true
	writer.TextTransparency = 1
	writer.BackgroundTransparency = 1

	local dummyMeasure = Atlas.create(`TextLabel`, {
		Font = Enum.Font.Code,
		TextSize = 17,
		Text = ``,
		Visible = false,
		Parent = widget
	})

	writer:GetPropertyChangedSignal(`Text`):Connect(function()
		visual.Text = Arc.applyRichTextPipeline(writer.Text)
		Arc.updateContentPrefix(writer, visual, dummyMeasure, contextLabel)
	end)
	writer.Text = `arc`
	writer.FocusLost:Connect(function(enterPressed)
		if not enterPressed then return end

		local inputText = writer.Text
		Arc.Private.LastInput = inputText
		Arc.Fired:Fire(inputText)

		task.wait()
		writer:CaptureFocus()
	end)
	Arc.Activated:Connect(function()
		writer:CaptureFocus()
	end)

	return Arc.Widget
end

function Arc.connect()
	Arc.Fired:Connect(function(input: string)
		local pipeline = string.split(input, `|`)

		task.spawn(function()
			local lastTopLevel = Arc.Private.CurrentTopLevel or `arc`

			for _, cmdText in (pipeline) do
				cmdText = cmdText:match(`^%s*(.-)%s*$`)
				if cmdText == `` then continue end
				local origTokens = Arc.tokenize(cmdText)

				local resolved, memErr = Arc.resolveMemory(origTokens)
				if not resolved then
					Arc.Output:Fire(`{cmdText}\n{memErr}`)
					return
				end
				origTokens = Arc.evaluateExpressions(resolved)

				if #origTokens == 0 then continue end

				local topCommandName = origTokens[1]
				local tokensCopy = {}
				for i,v in (origTokens) do tokensCopy[i] = v end
				local command, remaining = Arc.resolveCommand(Arc.Commands, tokensCopy)

				if not command or not command.run then
					Arc.Output:Fire(`{cmdText}\nUnknown or incomplete command.`)
					return
				end

				local positionals, flags, argErr = Arc.parseArguments(command, remaining)
				if argErr then
					Arc.Output:Fire(`{cmdText}\n{argErr}`)
					return
				end

				local args = Arc.buildNamedArgs(command, positionals)
				for argName, info in (command.args or {}) do
					if info.order and not args[argName] and not info.optional then
						Arc.Output:Fire(`{cmdText}\nMissing argument: {argName}`)
						return
					end
				end

				local commandName = topCommandName
				local context = Arc.Private.Contexts[commandName]
				for argName, argValue in (args) do
					local info = command.args and command.args[argName]
					if info and info.type == 'path' and typeof(argValue) == 'string' then
						local baseContext = context or workspace
						local resolved, err = Arc.resolvePath(argValue, baseContext)
						if not resolved then
							Arc.Output:Fire(`{cmdText}\nPath error: {err}`)
						else
							args[argName] = resolved
						end
					end
				end

				local success, result = pcall(function()
					return command.run({
						arc = Arc,
						args = args,
						flags = flags,
						input = cmdText
					})
				end)

				if not success then
					Arc.Output:Fire(`{cmdText}\n{result}`)
					continue
				end

				if type(result) == 'table' and result.context ~= nil then
					Arc.Private.Contexts[commandName] = result.context
				end

				local outputText
				if type(result) == 'table' then
					outputText = result.response
				elseif result then
					outputText = result
				end

				if outputText then
					Arc.Private.CurrentTopLevel = commandName
					Arc.Output:Fire(`{cmdText}\n{outputText}`)
				end

				Arc.Private.CurrentTopLevel = lastTopLevel
			end
		end)
	end)
end

function Arc._init()
	Arc.connect()
	shared.Arc = Arc
end

return Arc