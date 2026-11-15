--!strict
local Boot = {}

export type Module = {
	Priority: number?,
	Dependencies: { string }?,
	Init: ((self: any) -> ())?,
	Start: ((self: any) -> ())?,
}

local DEFAULT_PRIORITY = 100

function Boot.order(modules: { [string]: Module }): { string }
	local names = {}
	for name in modules do
		table.insert(names, name)
	end
	table.sort(names, function(a, b)
		local left, right = modules[a].Priority or DEFAULT_PRIORITY, modules[b].Priority or DEFAULT_PRIORITY
		return if left == right then a < b else left < right
	end)
	local ordered, state = {}, {}
	local function visit(name: string, path: { string })
		if state[name] == "done" then
			return
		end
		if state[name] == "open" then
			error("dependency cycle: " .. table.concat(path, " -> ") .. " -> " .. name)
		end
		local module = modules[name]
		if not module then
			error("missing dependency: " .. name)
		end
		state[name] = "open"
		table.insert(path, name)
		local dependencies: { string } = module.Dependencies or {}
		for _, dependency in dependencies do
			visit(dependency, path)
		end
		table.remove(path)
		state[name] = "done"
		table.insert(ordered, name)
	end
	for _, name in names do
		visit(name, {})
	end
	return ordered
end

local function load(folder: Instance): { [string]: Module }
	local modules = {}
	for _, child in folder:GetChildren() do
		if child:IsA("ModuleScript") then
			local ok, result = pcall(require, child)
			if ok then
				modules[child.Name] = result
			else
				warn(`[Boot] {child.Name} failed to load: {result}`)
			end
		end
	end
	return modules
end

local function guarded(name: string, phase: string, run: () -> (), budget: number)
	local finished = false
	task.spawn(function()
		local ok: boolean, problem: any = pcall(run)
		if not ok then
			warn(`[Boot] {name}:{phase} failed: {problem}`)
		end
		finished = true
	end)
	local waited = 0
	while not finished and waited < budget do
		waited += task.wait()
	end
	if not finished then
		warn(`[Boot] {name}:{phase} is still running after {budget}s, the boot goes on without it`)
	end
end

function Boot.run(folder: Instance, budget: number)
	local modules = load(folder)
	local ordered = Boot.order(modules)
	for _, name in ordered do
		local module = modules[name]
		local init = module.Init
		if init then
			guarded(name, "Init", function()
				init(module)
			end, budget)
		end
	end
	for _, name in ordered do
		local module = modules[name]
		local start = module.Start
		if start then
			task.spawn(function()
				local ok: boolean, problem: any = pcall(start, module)
				if not ok then
					warn(`[Boot] {name}:Start failed: {problem}`)
				end
			end)
		end
	end
end

return Boot
