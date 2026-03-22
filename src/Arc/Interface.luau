local Interface = {}

function Interface.updatePrefix(writer, visual, dummyMeasure, contextLabel, arc)
	local tokens = arc.Tokenizer.tokenize(writer.Text)
	local commandName = tokens[1]
	local context = arc.State.Contexts[commandName]

	if context then
		local text = `[{context:GetFullName()}] `
		contextLabel.Text = text
		dummyMeasure.Text = text

		local width = dummyMeasure.TextBounds.X
		contextLabel.Size = UDim2.new(0, width, 0, 25)

		writer.Position = UDim2.new(0, width, 0, 0)
		writer.Size = UDim2.new(1, -width, 0, 25)

		visual.Position = writer.Position
		visual.Size = writer.Size
	else
		contextLabel.Text = ""
		contextLabel.Size = UDim2.new(0, 0, 0, 25)

		writer.Position = UDim2.new(0, 0, 0, 0)
		writer.Size = UDim2.new(1, 0, 0, 25)

		visual.Position = writer.Position
		visual.Size = writer.Size
	end
end

return Interface