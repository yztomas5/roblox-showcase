--!strict
local Coins = {}

export type Spot = { x: number, z: number }
export type Bucket = { tokens: number, stamp: number, rate: number, burst: number }

local MODULUS = 4294967296

local function step(state: number): number
	state = bit32.bxor(state, bit32.lshift(state, 13))
	state = bit32.bxor(state, bit32.rshift(state, 17))
	return bit32.bxor(state, bit32.lshift(state, 5))
end

function Coins.layout(seed: number, count: number, size: number, spacing: number, attempts: number): { Spot }
	local spots: { Spot } = {}
	local state = math.max(seed % MODULUS, 1)
	local tries = 0
	while #spots < count and tries < count * attempts do
		tries += 1
		state = step(state)
		local x = (state / MODULUS - 0.5) * size
		state = step(state)
		local z = (state / MODULUS - 0.5) * size
		local clear = true
		for _, spot in spots do
			if (spot.x - x) ^ 2 + (spot.z - z) ^ 2 < spacing * spacing then
				clear = false
				break
			end
		end
		if clear then
			table.insert(spots, { x = x, z = z })
		end
	end
	return spots
end

function Coins.reachable(distance: number, reach: number, speed: number, lag: number): boolean
	return distance <= reach + speed * lag
end

function Coins.bucket(rate: number, burst: number, now: number): Bucket
	return { tokens = burst, stamp = now, rate = rate, burst = burst }
end

function Coins.take(bucket: Bucket, now: number): boolean
	bucket.tokens = math.min(bucket.burst, bucket.tokens + (now - bucket.stamp) * bucket.rate)
	bucket.stamp = now
	if bucket.tokens < 1 then
		return false
	end
	bucket.tokens -= 1
	return true
end

return Coins
