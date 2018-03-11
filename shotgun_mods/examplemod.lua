--[[
    Example Mod
    Written by Atenfyr
    Licensed under the MIT License
]]

modName = 'Example Mod'

function ai_emptyshell(currentAmmo, playerAmmo, playersLastMove, botsLastMove, playerIsCursed, botIsCursed, playerHasSuccumbed, isPredicting, playersCurrentMove, seed, localValues)
    local botHasSuccumbed = localValues['succumbed']
    if botHasSuccumbed then -- the AI after the bot has succumbed
        currentAmmo = currentAmmo - 2
        if currentAmmo <= 0 then
            return 92, '%botname% ran out of ammo.' -- force a lose if there is no more ammo
        end
        return 6, {currentAmmo} -- play nothing and set the ammo
    else
        if currentAmmo >= 6 then
            playSound('minecraft:entity.wither.spawn') -- play the wither spawn sound
            return 8, {currentAmmo - 2}, {['succumbed'] = true} -- play Succumb, subtract 2 ammo, mark it as having succumbed already
        end
    end
    return 1 -- reload if a move has not been decided yet
end

function ai_loser()
    return 92, '%botname% was frightened of you and ran away.'
end

function ai_winner()
    return 93, '%botname% blasted you with blinding light, vaporising you instantly.'
end

function ai_mindcontrol(currentAmmo, playerAmmo, playersLastMove, botsLastMove, playerIsCursed, botIsCursed, playerHasSuccumbed, isPredicting, playersCurrentMove, seed, localValues)
    math.randomseed(seed); math.random();
    local choices = {1, 2, 5, 6, 7}
    local newMove = choices[math.random(1, #choices)];

    if playerAmmo <= 10 then
        newMove = 1
    end

    if playerAmmo >= 12 then
        if isPredicting then
            return 99
        end
        return 6, {}, {}, 'Check Facebook'
    else
        playSound('minecraft:entity.endermen.teleport')
        return 6, {nil, nil, nil, nil, newMove}, {}, 'Mind Control', true, colours.magenta -- disguise as playing Mind Control
    end
end

function ai_concealed(currentAmmo, playerAmmo, playersLastMove, botsLastMove, playerIsCursed, botIsCursed, playerHasSuccumbed, isPredicting, playersCurrentMove, seed, localValues)
    math.randomseed(seed); math.random();
    local choices = {1, 2, 3}
    if currentAmmo <= 0 or botIsCursed then
        choices = {1, 2}
    end

    local botsCurrentMove = choices[math.random(1, #choices)]

    -- play sounds manually
    if (playersCurrentMove == 3 and botsCurrentMove == 2) or (botsCurrentMove == 3 and playersCurrentMove == 2) then
        playSound("minecraft:entity.zombie.attack_iron_door")
    elseif (playersCurrentMove) == 4 or (botsCurrentMove == 4) then
        playSound("minecraft:entity.witch.ambient")
    end

    return botsCurrentMove, {}, {}, '???' -- hide what they are actually playing (but prophet can still see through)
end

aiList = {"Ninja", "Wizard", "Empty Shell", "Kitten", "Odium"}
aiFunctions = {["Empty Shell"] = ai_emptyshell, ["Wizard"] = ai_mindcontrol, ["Ninja"] = ai_concealed, ["Odium"] = ai_winner, ["Kitten"] = ai_loser}