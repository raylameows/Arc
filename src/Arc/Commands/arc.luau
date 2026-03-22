return {
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
				for _, item in (data.state.Cache) do
					item:Destroy()
				end
				table.clear(data.state.Cache)
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

				data.state.Memory[key] = value
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
				for k,v in (data.state.Memory) do
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
}