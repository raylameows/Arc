local Arc = {}

Arc.State = require(`./State`)
Arc.Widget = require(`./Widget`)

Arc.Tokenizer = require(`./Tokenizer`)
Arc.Parser = require(`./Parser`)

Arc.Memory = require(`./Memory`)
Arc.Expressions = require(`./Expressions`)
Arc.Path = require(`./Path`)

Arc.Commands = require(`./Commands/Init`)
Arc.Executor = require(`./Executor`)

Arc.Format = require(`./Format`)
Arc.Interface = require(`./Interface`)

Arc.Output = Instance.new("BindableEvent")
Arc.Activated = Instance.new("BindableEvent")

function Arc.init()
	shared.Arc = Arc
end

function Arc.run(input)
	Arc.Executor.run(input, Arc)
end

function Arc.mount(widgetGui)
	return Arc.Widget.create(Arc, widgetGui)
end

return Arc