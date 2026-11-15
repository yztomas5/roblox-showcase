--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local NetworkChannels = require(script.Parent.Config.NetworkChannels)

local Net = {}

local WAIT_SECONDS = 10

local function child(parent: Instance, name: string, className: string): Instance?
	local found = parent:FindFirstChild(name)
	if found and found:IsA(className) then
		return found
	end
	if RunService:IsServer() then
		local made = Instance.new(className)
		made.Name = name
		made.Parent = parent
		return made
	end
	local waited = parent:WaitForChild(name, WAIT_SECONDS)
	return if waited and waited:IsA(className) then waited else nil
end

local function root(): Instance?
	return child(ReplicatedStorage, NetworkChannels.Folder, "Folder")
end

function Net.event(name: string): RemoteEvent?
	local parent = root()
	return if parent then child(parent, name, "RemoteEvent") :: RemoteEvent? else nil
end

function Net.board(): Folder?
	local parent = root()
	return if parent then child(parent, NetworkChannels.Board, "Folder") :: Folder? else nil
end

return Net
