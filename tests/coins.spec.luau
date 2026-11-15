local Coins = require("../src/Shared/Coins")

return function(t)
	t.it("the same seed always lays the coins in the same spots", function()
		local first = Coins.layout(7, 20, 100, 8, 40)
		local second = Coins.layout(7, 20, 100, 8, 40)
		t.expect(#first).toBe(20)
		for index, spot in first do
			t.expect(spot.x).toBe(second[index].x)
			t.expect(spot.z).toBe(second[index].z)
		end
	end)

	t.it("coins keep their spacing and stay inside the area", function()
		local spots = Coins.layout(42, 24, 120, 9, 40)
		for index, spot in spots do
			t.expect(math.abs(spot.x) <= 60 and math.abs(spot.z) <= 60).toBeTruthy()
			for other = index + 1, #spots do
				local gap = math.sqrt((spot.x - spots[other].x) ^ 2 + (spot.z - spots[other].z) ^ 2)
				t.expect(gap >= 9).toBeTruthy()
			end
		end
	end)

	t.it("a full area gives up instead of looping forever", function()
		t.expect(#Coins.layout(3, 500, 10, 9, 40) < 500).toBeTruthy()
	end)

	t.it("reach forgives the distance a player can cover while the request travels", function()
		t.expect(Coins.reachable(6, 6, 32, 0)).toBe(true)
		t.expect(Coins.reachable(15, 6, 32, 0.3)).toBe(true)
		t.expect(Coins.reachable(16, 6, 32, 0.3)).toBe(false)
	end)

	t.it("the token bucket allows a burst and then refills at its rate", function()
		local bucket = Coins.bucket(2, 3, 0)
		t.expect(Coins.take(bucket, 0)).toBe(true)
		t.expect(Coins.take(bucket, 0)).toBe(true)
		t.expect(Coins.take(bucket, 0)).toBe(true)
		t.expect(Coins.take(bucket, 0)).toBe(false)
		t.expect(Coins.take(bucket, 0.5)).toBe(true)
		t.expect(Coins.take(bucket, 0.5)).toBe(false)
	end)
end
