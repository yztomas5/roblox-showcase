--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CoinConfig = require(ReplicatedStorage.Shared.Config.CoinConfig)
local Coins = require(ReplicatedStorage.Shared.Coins)
local Net = require(ReplicatedStorage.Shared.Net)
local NetworkChannels = require(ReplicatedStorage.Shared.Config.NetworkChannels)

local DataService = require(script.Parent.DataService)

local CoinService = {
	Priority = 2,
	Dependencies = { "DataService" },
}

local EVENTS = NetworkChannels.Events

local _spots: { Coins.Spot } = {}
local _taken: { [number]: boolean? } = {}
local _buckets: { [Player]: Coins.Bucket } = {}
local _ack: RemoteEvent? = nil
local _board: Folder? = nil

local function positionOf(index: number): Vector3
	local spot = _spots[index]
	return Vector3.new(spot.x, CoinConfig.Height, spot.z)
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function bucketOf(player: Player): Coins.Bucket
	local bucket = _buckets[player]
	if not bucket then
		bucket = Coins.bucket(CoinConfig.Rate, CoinConfig.Burst, os.clock())
		_buckets[player] = bucket
	end
	return bucket
end

local function publish(index: number, taken: boolean)
	_taken[index] = if taken then true else nil
	local board = _board
	if board then
		board:SetAttribute(CoinConfig.AttributePrefix .. index, if taken then true else nil)
	end
end

local function respawn(index: number)
	task.delay(CoinConfig.Respawn, function()
		publish(index, false)
	end)
end

local function collect(player: Player, index: number): boolean
	if not (DataService.has(player) and _spots[index] and not _taken[index]) then
		return false
	end
	if not Coins.take(bucketOf(player), os.clock()) then
		return false
	end
	local root = rootOf(player)
	if not root then
		return false
	end
	local distance = (root.Position - positionOf(index)).Magnitude
	if not Coins.reachable(distance, CoinConfig.Reach, CoinConfig.MaxSpeed, CoinConfig.MaxLag) then
		return false
	end
	local paid = DataService.update(player, function(profile)
		profile.coins += CoinConfig.Value
		return true
	end)
	if not paid then
		return false
	end
	publish(index, true)
	respawn(index)
	return true
end

local function onCollect(player: Player, seq: unknown, index: unknown)
	if type(seq) ~= "number" or type(index) ~= "number" then
		return
	end
	local ok, accepted = pcall(collect, player, index)
	local ack = _ack
	if ack then
		ack:FireClient(player, seq, ok and accepted)
	end
end

function CoinService:Init()
	_spots = Coins.layout(CoinConfig.Seed, CoinConfig.Count, CoinConfig.Area, CoinConfig.Spacing, CoinConfig.Attempts)
	_ack = Net.event(EVENTS.Ack)
	_board = Net.board()
	local request = Net.event(EVENTS.Collect)
	if request then
		request.OnServerEvent:Connect(onCollect)
	end
end

function CoinService:Start()
	Players.PlayerRemoving:Connect(function(player: Player)
		_buckets[player] = nil
	end)
end

return CoinService
