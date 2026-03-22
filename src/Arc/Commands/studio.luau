local Selection = game:GetService("Selection")

return {
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
				local root = data.state.Contexts.studio or workspace
				local queried = root:QueryDescendants(data.args.selector)
				Selection:Set(queried)

				return `Selected {#queried} instances`
			end,
		},
	},
}