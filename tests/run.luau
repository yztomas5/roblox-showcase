local fs = require("@lune/fs")
local process = require("@lune/process")

local SUFFIX = ".spec.luau"

local passed, failed = 0, 0

local function expect(value: any)
	return {
		toBe = function(wanted: any)
			if value ~= wanted then
				error(`expected {tostring(wanted)}, got {tostring(value)}`, 2)
			end
		end,
		toBeTruthy = function()
			if not value then
				error(`expected a truthy value, got {tostring(value)}`, 2)
			end
		end,
	}
end

local function it(name: string, run: () -> ())
	local ok, problem = pcall(run)
	if ok then
		passed += 1
	else
		failed += 1
		print(`  FAIL {name}\n    {problem}`)
	end
end

for _, file in fs.readDir("tests") do
	if string.sub(file, -#SUFFIX) == SUFFIX then
		print(file)
		local spec = require(`./{string.sub(file, 1, -6)}`) :: any
		spec({ it = it, expect = expect })
	end
end

print(`tests: {passed} passed, {failed} failed`)
process.exit(if failed == 0 then 0 else 1)
