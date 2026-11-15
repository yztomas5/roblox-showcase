local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Boot = require(ReplicatedStorage.Shared.Boot)

local INIT_BUDGET = 5

Boot.run(script.Controllers, INIT_BUDGET)
