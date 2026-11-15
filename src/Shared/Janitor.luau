--!strict
local Janitor = {}
Janitor.__index = Janitor

export type Janitor = typeof(setmetatable({} :: { tasks: { any } }, Janitor))

function Janitor.new(): Janitor
	return setmetatable({ tasks = {} }, Janitor)
end

function Janitor.add<T>(self: Janitor, task: T): T
	table.insert(self.tasks, task)
	return task
end

function Janitor.clean(self: Janitor)
	local tasks = self.tasks
	self.tasks = {}
	for index = #tasks, 1, -1 do
		local item = tasks[index]
		local kind = typeof(item)
		if kind == "function" then
			item()
		elseif kind == "RBXScriptConnection" then
			item:Disconnect()
		elseif kind == "Instance" then
			item:Destroy()
		elseif type(item) == "table" and item.clean then
			item:clean()
		end
	end
end

return Janitor
