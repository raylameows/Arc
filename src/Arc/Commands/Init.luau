local Commands = {}

for _, command in (script.Parent:GetChildren()) do
	if command == script then continue end
	Commands[command.Name] = require(command)
end

return Commands