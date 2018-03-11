--[[
    Default Set of Bots for Shotgun
    Written by Atenfyr
    Licensed under the MIT License
]]

modName = 'Default Bots'

local function ai_flawless(currentAmmo, playerAmmo, playersLastMove, botsLastMove, playerIsCursed, botIsCursed, playerHasSuccumbed, isPredicting, playersCurrentMove, seed)
	if isPredicting then 
		return 99
	end
	if botIsCursed then
		return 2
	end
	if currentAmmo >= 1 then
		if playersCurrentMove == 1 or playersCurrentMove == 6 or playersCurrentMove == 4 or playersCurrentMove == 5 then
			return 3
		end
	end
	if playersCurrentMove == 3 then
		return 2
	end
	return 1
end

local function ai_aggressive(currentAmmo, playerAmmo, playersLastMove, botsLastMove, playerIsCursed, botIsCursed, playerHasSuccumbed, isPredicting, playersCurrentMove, seed)
	if currentAmmo < 1 then
		return 1
	end
	return 3
end

local function ai_simple(currentAmmo, playerAmmo, playersLastMove, botsLastMove, playerIsCursed, botIsCursed, playerHasSuccumbed)
    if playerHasSuccumbed or botIsCursed then
        return 2
    elseif currentAmmo >= 1 then
		if playerAmmo <= 0 or playerIsCursed then
			return 3
		else
			return 1
		end
	else
		if playerAmmo >= 1 and not playerIsCursed then
			return 2
		else
			return 1
		end
	end
	return 1
end

local function ai_random(currentAmmo, playerAmmo, playersLastMove, botsLastMove, playerIsCursed, botIsCursed, playerHasSuccumbed, isPredicting, playersCurrentMove, seed)
	math.randomseed(seed); math.random()
	local choices = {1, 2, 3}
	if currentAmmo < 1 or botIsCursed then
		choices = {1, 2}
	end
	
	local mv = choices[math.random(1,#choices)]
	return mv
end

local function ai_copycat(currentAmmo, playerAmmo, playersLastMove, botsLastMove, playerIsCursed, botIsCursed, playerHasSuccumbed, isPredicting, playersCurrentMove, seed)
	local mv = playersLastMove
    if mv == 91 then mv = 1 end
    if mv == 8 then mv = 2 end
	if currentAmmo < 1 and mv == 3 then
		return ai_random(currentAmmo, playerAmmo, playersLastMove)
	end
	
	return mv
end

local function ai_doppelganger(currentAmmo, playerAmmo, playersLastMove, botsLastMove, playerIsCursed, botIsCursed, playerHasSuccumbed, isPredicting, playersCurrentMove, seed)
	if isPredicting then 
		return 99
	end
	if playersCurrentMove == 8 then
		return 2
	end
	return playersCurrentMove
end

local function ai_amnesiac(currentAmmo, playerAmmo, playersLastMove, botsLastMove, playerIsCursed, botIsCursed, playerHasSuccumbed, isPredicting, playersCurrentMove, seed)
	local list = {ai_simple, ai_copycat, ai_random, ai_aggressive, ai_doppelganger}
	math.randomseed(seed); math.random()
	local f = list[math.random(1, #list)]
	return f(currentAmmo, playerAmmo, playersLastMove, botsLastMove, playerIsCursed, botIsCursed, playerHasSuccumbed, isPredicting, playersCurrentMove, seed)
end

aiList = {[1] = "Flawless", [2] = "Simpleton", [3] = "Copycat", [4] = "Crazy", [5] = "Aggressive", [6] = "Amnesiac", [7] = "Doppelganger", [8] = "Dummy"}
aiFunctions = {["Amnesiac"] = ai_amnesiac, ["Doppelganger"] = ai_doppelganger, ["Simpleton"] = ai_simple, ["Copycat"] = ai_copycat, ["Crazy"] = ai_random, ["Aggressive"] = ai_aggressive, ["Flawless"] = ai_flawless, ["Dummy"] = function() return 6 end}