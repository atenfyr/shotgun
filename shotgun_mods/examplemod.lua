--[[
    Example Mod
    Written by Atenfyr
    Licensed under the MIT License
]]

modName = 'Example Mod'

local function ai_emptyshell(currentAmmo, playerAmmo, playersLastMove, botsLastMove, playerIsCursed, botIsCursed, playerHasSuccumbed, isPredicting, playersCurrentMove, seed, localValues)
    math.randomseed(seed); math.random();
    
    local botHasSuccumbed = localValues['succumbed']
    if botHasSuccumbed then -- the AI after the bot has succumbed
        if currentAmmo <= 0 then
            return 92, '%botname% ran out of ammo.' -- force a lose if there is no more ammo
        end
        if playerAmmo <= 0 then
            return 93, '%botname% sucked the life out of you.' -- force a win if you are leeched to death
        end

        return 3, {nil, playerAmmo-1}, localValues, 'Shoot & Leech', true, colours.red -- disguise shoot as 'shoot and leech' and take away ammo from player (we want to lose one ammo, so let the shoot take it away)
    else
        if currentAmmo >= 8 then
            playSound('minecraft:entity.wither.spawn') -- play the wither spawn sound
            return 8, {currentAmmo - 2}, {['succumbed'] = true} -- play Succumb, subtract 2 ammo, mark it as having succumbed already
        end

        -- try to preserve self and accumulate ammo
        if currentAmmo >= 1 then
            if playerAmmo > 0 and not playerIsCursed then
                if math.random(1,4) == 1 then
                    return 2
                elseif math.random(1,4) == 1 then
                    return 4
                end
            end
        else
            if playerAmmo >= 1 and not playerIsCursed then
                if math.random(1,3) == 1 then
                    return 2
                end
            end
        end
    end
    return 1 -- reload if a move has not been decided yet
end

--[[
    mechanics:
        odium kills you if you run out of ammo or make yourself vulnerable. 
        you can shoot him when he tries to recharge (5 ammo or less).
        he tries to make you vulnerable before then so he can incinerate you.
        however, he gives you some ammo to start because he plays fair.
]]
local function ai_odium(currentAmmo, playerAmmo, playersLastMove, botsLastMove, playerIsCursed, botIsCursed, playerHasSuccumbed, isPredicting, playersCurrentMove, seed, localValue)
    if (localValue == 'curse' or playerAmmo <= 0 or currentAmmo <= 5) and isPredicting then -- about to play vaporising light or magical light prevents seeing
        return 91
    end
    
    if playersLastMove == 91 then -- first move of the game
        return 2, {20, 15}, 'opening', 'Blinding Light', true, colours.yellow -- opening move
    end

    local turn
    if localValue == 'disorienting' then -- switch reload and block
        if playersCurrentMove == 1 then
            turn = 2
        elseif playersCurrentMove == 2 then
            turn = 1
        end
    elseif (localValue == 'noblock' and playersCurrentMove == 2) or (localValue == 'curse' and playersCurrentMove == 3) then
        turn = 6
    end
    playersCurrentMove = turn or playersCurrentMove

    if playerAmmo <= 0 or playersCurrentMove == 6 or playersCurrentMove == 1 then
        playSound('minecraft:block.fire.extinguish')
        return 93, 'You were incinerated by Odium\'s Vaporising Light.'
    end

    if playersCurrentMove == 3 and playerAmmo > 0 then
        playSound('minecraft:block.glass.break', 1, 0)
    end

    if currentAmmo <= 4 then
        return 6, {15}, 'blinding', 'Blinding Light', true, colours.yellow -- recharges ammo
    elseif currentAmmo == 5 then
        return 7, {currentAmmo-1}, 'protecting', 'Protective Light', true, colours.orange -- same as retaliate. confuses the player because it isn't for the next turn, it's for the current one (plus, you may get crippling right before and always die here)
    end

    math.randomseed(seed); math.random()
    local move = math.random(1, 7)
    if move == 1 or move == 2 then
        return 2, {currentAmmo-1, nil, nil, nil, turn}, 'disorienting', 'Disorienting Light', true, colours.red -- next turn, A and D are switched (move 1 turns to 2, 2 turns to 1)
    elseif move == 3 or move == 4 then
        return 2, {currentAmmo-1, playerAmmo-1, nil, nil, turn}, 'leeching', 'Bleeding Light', true, colours.orange -- takes 1 ammo away from the player
    elseif move == 5 then
        return 2, {currentAmmo-1, nil, nil, nil, turn}, 'noblock', 'Crippling Light', true, colours.red -- prevents blocking next turn
    elseif move == 6 or move == 7 then
        return 2, {currentAmmo-1, nil, nil, nil, turn}, 'curse', 'Magical Light', true, colours.red -- curses player (turns shoot into nothing, vaporising the player) and prevents foreseeing for next turn
    end
end

local function ai_mindcontrol(currentAmmo, playerAmmo, playersLastMove, botsLastMove, playerIsCursed, botIsCursed, playerHasSuccumbed, isPredicting, playersCurrentMove, seed, localValues)
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

local function ai_concealed(currentAmmo, playerAmmo, playersLastMove, botsLastMove, playerIsCursed, botIsCursed, playerHasSuccumbed, isPredicting, playersCurrentMove, seed, localValues)
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

aiList = {"Odium", "Ninja", "Magical Shell", "Wizard"}
aiFunctions = {["Magical Shell"] = ai_emptyshell, ["Wizard"] = ai_mindcontrol, ["Ninja"] = ai_concealed, ["Odium"] = ai_odium}