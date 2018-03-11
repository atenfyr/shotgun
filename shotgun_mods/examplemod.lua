function main(currentAmmo, playerAmmo, playersLastMove, botsLastMove, playerIsCursed, botIsCursed, playerHasSuccumbed, isPredicting, playersCurrentMove, seed, localValues)
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
            return 8, {currentAmmo - 2}, {['succumbed'] = true} -- play Succumb, subtract 2 ammo, mark it as having succumbed
        end
    end
    return 1 -- reload if a move has not been decided yet
end

aiList = {[1] = "Empty Shell"}
aiFunctions = {["Empty Shell"] = main}