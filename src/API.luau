local CoreGui = game:GetService("CoreGui")

local API = {}
API.__index = API

-- Initiates the API
function API.init()
	shared.ArcAPI = API

	local loaded = Instance.new(`BoolValue`)
	loaded.Value = true
	loaded.Name = `LoadedArcAPI`
	loaded.Parent = CoreGui

	return
end

-- Checks if the API has loaded
function API.check()
	local loaded = CoreGui:WaitForChild(`LoadedArcAPI`, 10)
	if not loaded then return end

	return true
end

-- Creates a new Arc command instance, does not register it in the commands list instantly
function API.new(key: string)
	local self = setmetatable({}, API)
	self.Key = key
	self.Command = {}

	return self
end

-- Sets the command's `field` to `value`
function API:Set(field: string, value: any)
	self.Command[field] = value

	return self
end

-- Fills all the fields of the command with the data's keys and values
function API:Fill(data: {})
	for k,v in (data) do
		self.Command[k] = v
	end

	return self
end

-- Registers the command to Arc's command list and removes it from cache
function API:Register()
	if not shared.Arc then warn(`shared.Arc is missing`) return end

	shared.Arc.Commands[self.Key] = self.Command
	table.clear(self)
	self = nil

	return nil
end

return API