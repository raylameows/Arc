local Atlas = {}

function Atlas.create(class: string, properties: {[string]: any})
	local instance: Instance = Instance.new(class)
	local parent: Instance? = nil

	for k,v in (properties or {}) do
		if k == `Parent` then 
			parent = v 
			continue 
		elseif k == `Children` then
			for _,child in (v) do
				child.Parent = instance
			end
			continue
		end
		instance[k] = v
	end

	if parent then instance.Parent = parent end
	return instance
end

return Atlas