--!strict
local Players = game:GetService("Players")

local DataService = {
	Priority = 1,
}

export type Profile = { coins: number }

local _profiles: { [Player]: Profile } = {}

function DataService.has(player: Player): boolean
	return _profiles[player] ~= nil
end

function DataService.update(player: Player, change: (Profile) -> boolean): boolean
	local profile = _profiles[player]
	if not profile then
		return false
	end
	local draft = table.clone(profile)
	if not change(draft) then
		return false
	end
	_profiles[player] = draft
	player:SetAttribute("Coins", draft.coins)
	return true
end

local function open(player: Player)
	_profiles[player] = { coins = 0 }
	player:SetAttribute("Coins", 0)
end

function DataService:Init()
	Players.PlayerAdded:Connect(open)
	for _, player in Players:GetPlayers() do
		open(player)
	end
	Players.PlayerRemoving:Connect(function(player: Player)
		_profiles[player] = nil
	end)
end

return DataService
