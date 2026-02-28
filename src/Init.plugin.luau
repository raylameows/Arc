local Arc = require(`./Arc`)
Arc.Plugin = plugin
Arc.widget(plugin:CreateDockWidgetPluginGuiAsync(`ArcTerminal`, DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float,
	false,
	false,
	600,
	50, 
	100,
	20
)))

local API = require(`./API`)

Arc._init()
API._init()

local Toolbar = plugin:CreateToolbar(`Arc Terminal`)
local Button = Toolbar:CreateButton(`Arc`, `Opens the Arc Terminal`, `rbxassetid://17799860953`)

local deb = false
Button.Click:Connect(function()
	if deb then return end

	if not Arc.Active then
		Arc.Active = true
		Arc.Widget.Enabled = true
		Arc.Activated:Fire()
		plugin:Activate(true)
	elseif Arc.Active then
		Arc.Active = false
		Arc.Widget.Enabled = false
		plugin:Deactivate()
	end
end)

local function Disable()
	Arc.Active = false
	Arc.Widget.Enabled = false
end

local function Unload()
	Disable()
end

plugin.Unloading:Connect(Unload)
plugin.Deactivation:Connect(Disable)