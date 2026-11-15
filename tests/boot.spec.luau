local Boot = require("../src/Shared/Boot")

return function(t)
	t.it("modules start by priority, then by name", function()
		local order = Boot.order({ B = { Priority = 2 }, A = { Priority = 2 }, C = { Priority = 1 } })
		t.expect(table.concat(order, ",")).toBe("C,A,B")
	end)

	t.it("a dependency always starts before the module that needs it", function()
		local order = Boot.order({
			Coins = { Priority = 1, Dependencies = { "Data" } },
			Data = { Priority = 5 },
		})
		t.expect(table.concat(order, ",")).toBe("Data,Coins")
	end)

	t.it("a dependency cycle is reported instead of hanging the boot", function()
		local ok, problem = pcall(Boot.order, { A = { Dependencies = { "B" } }, B = { Dependencies = { "A" } } })
		t.expect(ok).toBe(false)
		t.expect(string.find(tostring(problem), "cycle") ~= nil).toBeTruthy()
	end)

	t.it("a missing dependency is reported by name", function()
		local ok, problem = pcall(Boot.order, { A = { Dependencies = { "Ghost" } } })
		t.expect(ok).toBe(false)
		t.expect(string.find(tostring(problem), "Ghost") ~= nil).toBeTruthy()
	end)
end
