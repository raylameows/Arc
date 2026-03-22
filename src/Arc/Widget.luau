local Atlas = require(script.Parent.Parent.Util.Atlas)

local Widget = {}

function Widget.create(arc, widget: DockWidgetPluginGui)
	arc.Widget = widget

	widget.Title = "Arc"
	widget.Name = "Arc Terminal"

	local state = arc.State
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

	local output = Atlas.create("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, -25),
		Position = UDim2.new(0, 0, 0, 25),
		BackgroundTransparency = 1,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		TopImage 	= "rbxassetid://130227998672455",
		MidImage 	= "rbxassetid://130227998672455",
		BottomImage = "rbxassetid://130227998672455",
		ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255),
		ScrollBarThickness = 3,
		ScrollBarImageTransparency = 0.95,
		BorderSizePixel = 0,
		Parent = widget,
		Children = {
			Atlas.create("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,	
			}),
		}
	})

	arc.Output.Event:Connect(function(text: string)
		local split = string.split(text, "\n")

		if #split >= 2 then
			split[1], split[2] = split[2], split[1]
		end

		if #state.Cache ~= 0 then
			table.insert(split, 1, "")
		end

		for i, line in split do
			table.insert(state.Cache, Atlas.create("TextLabel", {
				Size = UDim2.new(1, 0, 0, 20),
				Font = Enum.Font.Code,
				BackgroundTransparency = 1,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextYAlignment = Enum.TextYAlignment.Center,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextSize = 17,
				Text = `{i == #split and ">" or ""}{i == #split and arc.Format.apply(line, arc) or line}`,
				RichText = i == #split and true or false,
				LayoutOrder = -#state.Cache,
				Parent = output
			}))
		end
	end)

	local contextLabel: TextLabel = Atlas.create("TextLabel", {
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

	local writer: TextBox = Atlas.create("TextBox", textSettings)
	local visual: TextLabel = Atlas.create("TextLabel", textSettings)

	visual.RichText = true
	writer.TextTransparency = 1
	writer.BackgroundTransparency = 1

	local dummyMeasure = Atlas.create("TextLabel", {
		Font = Enum.Font.Code,
		TextSize = 17,
		Text = "",
		Visible = false,
		Parent = widget
	})

	writer:GetPropertyChangedSignal("Text"):Connect(function()
		visual.Text = arc.Format.pipeline(writer.Text, arc)
		arc.Interface.updatePrefix(writer, visual, dummyMeasure, contextLabel, arc)
	end)

	writer.Text = "arc"
	writer.FocusLost:Connect(function(enterPressed)
		if not enterPressed then return end

		local inputText = writer.Text
		state.LastInput = inputText

		arc.run(inputText)

		task.wait()
		writer:CaptureFocus()
	end)

	if arc.Activated then
		arc.Activated.Event:Connect(function()
			writer:CaptureFocus()
		end)
	end

	return widget
end

return Widget