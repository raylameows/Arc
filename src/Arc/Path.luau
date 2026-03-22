local Selection = game:GetService("Selection")

local Path = {}

function Path.resolve(rawPath: string, context: Instance?)
	local current = nil
	local remaining = rawPath

	if remaining:match("^@context") then
		if not context then
			return nil, "No valid context set"
		end
	end

	while true do
		local keyword, param = remaining:match("^(@[%w_]+)%s*%((%d+)%)")
		if not keyword then
			keyword = remaining:match("^(@[%w_]+)")
		end

		param = tonumber(param) or 1
		if not keyword then break end

		if keyword == "@context" then
			current = context
		elseif keyword == "@workspace" then
			current = workspace
		elseif keyword == "@game" then
			current = game
		elseif keyword == "@selection" then
			local sel = Selection:Get()
			if #sel == 0 then return nil, "No selection" end
			current = sel[param]
		end

		local _, e = remaining:find("^@[%w_]+%s*%(%d+%)?")
		remaining = remaining:sub((e or #keyword) + 1)
	end

	if remaining:sub(1,1) == "." then
		remaining = remaining:sub(2)
	end

	for _, segment in string.split(remaining, ".") do
		if segment ~= "" then
			current = current and current:FindFirstChild(segment)
			if not current then
				return nil, `Missing child "{segment}"`
			end
		end
	end

	return current
end

return Path