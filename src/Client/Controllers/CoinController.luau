--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local CoinConfig = require(ReplicatedStorage.Shared.Config.CoinConfig)
local Coins = require(ReplicatedStorage.Shared.Coins)
local Janitor = require(ReplicatedStorage.Shared.Janitor)
local Net = require(ReplicatedStorage.Shared.Net)
local NetworkChannels = require(ReplicatedStorage.Shared.Config.NetworkChannels)

local CoinController = {
	Priority = 1,
}

type Coin = { part: BasePart, base: CFrame, served: boolean, pending: number?, sentAt: number, retryAt: number }

local localPlayer = Players.LocalPlayer
local EVENTS = NetworkChannels.Events

local _janitor = Janitor.new()
local _coins: { Coin } = {}
local _waiting: { [number]: number } = {}
local _seq = 0
local _request: RemoteEvent? = nil

local function shown(coin: Coin): boolean
	return coin.served and coin.pending == nil
end

local function paint(coin: Coin)
	coin.part.Transparency = if shown(coin) then 0 else 1
end

local function build(folder: Folder)
	local spots =
		Coins.layout(CoinConfig.Seed, CoinConfig.Count, CoinConfig.Area, CoinConfig.Spacing, CoinConfig.Attempts)
	for index, spot in spots do
		local part = Instance.new("Part")
		part.Name = "Coin" .. index
		part.Shape = Enum.PartType.Cylinder
		part.Size = CoinConfig.Size
		part.Color = CoinConfig.Color
		part.Material = Enum.Material.Neon
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Parent = folder
		_coins[index] = {
			part = part,
			base = CFrame.new(spot.x, CoinConfig.Height, spot.z),
			served = true,
			sentAt = 0,
			retryAt = 0,
		}
	end
end

local function predict(index: number)
	local request = _request
	local coin = _coins[index]
	if not (request and coin and shown(coin)) or os.clock() < coin.retryAt then
		return
	end
	_seq += 1
	coin.pending = _seq
	coin.sentAt = os.clock()
	_waiting[_seq] = index
	paint(coin)
	request:FireServer(_seq, index)
end

local function settle(seq: number, accepted: boolean)
	local index = _waiting[seq]
	_waiting[seq] = nil
	local coin = index and _coins[index]
	if not coin or coin.pending ~= seq then
		return
	end
	coin.pending = nil
	if accepted then
		coin.served = false
	else
		coin.retryAt = os.clock() + CoinConfig.Pending
	end
	paint(coin)
end

local function watch(board: Folder)
	local function read(index: number)
		local coin = _coins[index]
		if coin then
			coin.served = board:GetAttribute(CoinConfig.AttributePrefix .. index) ~= true
			paint(coin)
		end
	end
	for index in _coins do
		read(index)
	end
	_janitor:add(board.AttributeChanged:Connect(function(name: string)
		local index = tonumber((string.match(name, "^" .. CoinConfig.AttributePrefix .. "(%d+)$")))
		if index then
			read(index)
		end
	end))
end

local function step()
	local character = localPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local spin = CFrame.Angles(0, os.clock() * CoinConfig.Spin, 0)
	local parts, frames = {}, {}
	local now = os.clock()
	for index, coin in _coins do
		if coin.pending and now - coin.sentAt > CoinConfig.Pending then
			coin.pending = nil
			coin.retryAt = now + CoinConfig.Pending
			paint(coin)
		end
		local frame = coin.base * spin * CFrame.Angles(0, 0, math.pi / 2)
		table.insert(parts, coin.part)
		table.insert(frames, frame)
		if root and root:IsA("BasePart") and shown(coin) then
			if (root.Position - coin.base.Position).Magnitude <= CoinConfig.Reach then
				predict(index)
			end
		end
	end
	workspace:BulkMoveTo(parts, frames, Enum.BulkMoveMode.FireCFrameChanged)
end

function CoinController:Start()
	_request = Net.event(EVENTS.Collect)
	local folder = Instance.new("Folder")
	folder.Name = "Coins"
	folder.Parent = workspace
	_janitor:add(folder)
	build(folder)
	local ack = Net.event(EVENTS.Ack)
	if ack then
		_janitor:add(ack.OnClientEvent:Connect(settle))
	end
	local board = Net.board()
	if board then
		watch(board)
	end
	_janitor:add(RunService.RenderStepped:Connect(step))
end

return CoinController
