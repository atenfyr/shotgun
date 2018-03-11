-- a quick guide to modding shotgun
--[[
    installing mods:
        a mod can be installed by placing it in the shotgun_mods directory that is automatically generated upon first boot.
    
    generic modding:
        mods consist of several bots which override the default list of bots. all bots consist of a single function which is run every turn.
        a mod can have more than one bot, but it must specify the function names for each of the bots in two tables.
        aiList is a list of numbers with the name that each bot should be assigned, and aiFunctions links the bot names to their functions.
        here is an example:
            aiList = {"Test Bot"}
            aiFunctions = {["Test Bot"] = testBotFunction}
        in this case, testBotFunction is a bot function, and it will be listed as Test Bot when selecting a bot to fight.

    adding custom bots:
        bot functions are passed the following arguments:
        currentAmmo, playerAmmo, playersLastMove, botsLastMove, playerIsCursed, botIsCursed, playerHasSuccumbed, isPredicting, playersCurrentMove, seed, localValues
        
        seed is used for bots that require a random element to make sure that the result is the same when predicting; if random elements are used, please use math.randomseed(seed).
        isPredicting is a boolean that represents whether or not the function is being called in order to make a prediction.

        all of these arguments can be used in order to determine a result. the result is passed by returning a move number within the function.
        these are all the move numbers:
        1 - Reload
        2 - Block
        3 - Shoot
        4 - Curse
        5 - Foresee
        6 - Nothing
        7 - Retaliate
        8 - Succumb
        91 - Signal: No Previous Move
        92 - Signal: Bot Lost
        93 - Signal: Bot Won
        99 - Signal: Bot is Unpredictable

        all move numbers from 90 to 99 are signals which can be received or passed by the bot that are not actually moves, but convey information.
        botsLastMove and playersLastMove can be 91 to signal that this is the first turn and there is no previous move.
        92 and 93 can be passed as move numbers to forcefully end the game with a win or loss. in this case, the second parameter returned is the last sentence. in a last sentence specified in this way, the string %botname% will be replaced with the bot's name.
        99 should only be passed as a move number if isPredicting is true; it is used to tell a Prophet that the bot cannot be predicted.

        after returning a move number (and the number is not 92 or 93), you can pass two more arguments. the second argument is a table of values to replace, and the third is a table to save as localValues.
        the second argument has five parameters, in this order: {currentAmmo, playerAmmo, playerIsCursed, botIsCursed, playersCurrentMove}
        if the table is less than five parameters, then the values that are dropped from the end are unmodified. if a value is specified as nil, it will also remain unmodified.
        the third argument can be anything, a table, a string, a number, etc. and it will be passed to the bot function every single move as the last argument: localValues.
        if a fourth argument is passed as a string, then the move will be displayed as whatever the fourth argument is. however, prophets can see through this disguise with their Foresee ability. (if disguised, block and curse sounds are disabled; it's up to you to add those in with playSound.)
        if the fifth argument is set the true, prophets cannot see through a disguised move. (use this for custom abilities)
        if a sixth argument is passed, it will specify the colour that the text will appear as to a prophet. (for example, colours.orange would be valid.)
]]

if not fs.exists('shotgun_mods') then
    fs.makeDir('shotgun_mods')
end

local args = {...}
local screenWidth, screenHeight = term.getSize()

local function setTextColourC(...)
	if term.isColour() then
		return term.setTextColour(unpack({...}))
	end
end

local function setBgColourC(...)
	if term.isColour() then
		return term.setBackgroundColour(unpack({...}))
	end
end

term.setTextColor(colours.white)
term.setBackgroundColour(colours.black)

local speaker = peripheral.find("speaker")
local function playSound(snd, a, b) -- sound, volume, pitch
	if speaker then
		speaker.playSound(snd, a, b)
	elseif commands then
		commands.exec("playsound " .. snd .. " @a[r=20] ~ ~ ~ " .. (a or 1) .. " " .. (b or 1))
	end
end

local function replay(victory, t, a, la, gm, sa, hsum)
	if not victory and gm then
		return
	end
	if a < 0 then
		a = 0
	end
	term.clear()
	term.setCursorPos(1,1)
	if victory and sa == 8 and not hsum then
		victory = false
		la = "You killed your opponent without having Succumbed."
	end
	if victory then
		setTextColourC(colours.lime)
		print("You win!")
		setTextColourC(colours.white)
		playSound("minecraft:entity.generic.explode")
	else
		setTextColourC(colours.red)
		print("You lose!")
		setTextColourC(colours.white)
		if sa == 4 then
			playSound("minecraft:entity.witch.death")
		elseif sa == 99 then
			playSound("minecraft:entity.wither.death")
		elseif sa == 8 then
			playSound("minecraft:block.fire.extinguish")
		else
			playSound("minecraft:entity.generic.death")
		end
	end
	print(la)
	io.write("The game lasted ")
	if t > 20 then
		setTextColourC(colours.red)
	elseif t > 10 then
		setTextColourC(colours.orange)
	elseif t > 5 then
		setTextColourC(colours.green)
	else
		setTextColourC(colours.lime)
	end
	io.write(t .. " turns")
	setTextColourC(colours.white)
	io.write(", and you had ")
	if a > 10 then
		setTextColourC(colours.lime)
	elseif a > 7 then
		setTextColourC(colours.green)
	elseif a > 3 then
		setTextColourC(colours.orange)
	else
		setTextColourC(colours.red)
	end
	if a == 0 then a = "no" end
	io.write(a .. " ammo")
	setTextColourC(colours.white)
	io.write(".\nThanks for playing!\n")
	error()
end

local plays = {
    [1] = "Reload",
    [2] = "Block",
    [3] = "Shoot",
    [4] = "Curse",
    [5] = "Foresee",
    [6] = "Nothing",
    [7] = "Retaliate", 
    [8] = "Succumb",
    [91] = "Signal: No Previous Move",
    [92] = "Automatic Lose",
    [93] = "Automatic Win",
    [99] = "Signal: Bot is Unpredictable"
}

local ainums = {}
local ainames = {}
local ainame = "Dummy"

local programEnvironment = {
    _G = _G,
    os = os,
    colors = colors,
    colours = colours,
    read = read,
    vector = vector,
    assert = assert,
    bit = bit,
    rawset = rawset,
    tonumber = tonumber,
    tostring = tostring,
    coroutine = coroutine,
    type = type,
    next = next,
    math = math,
    pairs = pairs,
    keys = keys,
    printError = printError,
    rawequal = rawequal,
    setfenv = setfenv,
    getfenv = getfenv,
    table = table,
    select = select,
    http = http,
    setmetatable = setmetatable,
    getmetatable = getmetatable,
    string = string,
    textutils = textutils,
    unpack = unpack,
    __inext = __inext,
    specialability = specialability,
    knowledge = knowledge,
    plays = plays,
    xpcall = xpcall,
    parallel = parallel,
    playSound = playSound
}

function concatTablesNumerically(table1, table2)
    table.insert(table2, 1, '\n')
    for i = 1, #table2 do
        table1[#table1+1] = table2[i]
    end
    return table1
end

function concatTablesByOverriding(table1, table2)
    for k, v in pairs(table2) do
        table1[k] = v
    end
    return table1
end

local listOfMods = fs.list('./shotgun_mods')

for k, v in pairs(listOfMods) do
    modFile = './shotgun_mods/' .. v
    local open = fs.open(modFile, 'r')
    local data = open.readAll()
    open.close()

    local fn, err = loadstring(data)
    if err then
        printError('Error in mod "' .. v:gsub('.lua', '') .. '"!\n' .. err)
        error()
    end
    setfenv(fn, programEnvironment)
    pcall(fn)
    
    concatTablesNumerically(ainums, programEnvironment['aiList'])
    concatTablesByOverriding(ainames, programEnvironment['aiFunctions'])
end

if ainums[1] == '\n' then
    table.remove(ainums, 1)
end

if #ainums == 0 then
    setTextColourC(colours.yellow)
    write('No mods have been installed. Would you like to install the default mod? (y/n) ')
    setTextColourC(colours.white)
    if read():sub(1,1):lower() == 'y' then
        local dataHandle = http.get('https://raw.githubusercontent.com/atenfyr/shotgun/master/shotgun_mods/default.lua', {['User-Agent'] = 'Shotgun/0.0.7'}) -- bad joke?
        local open = fs.open('./shotgun_mods/default.lua', 'w')
        open.write(dataHandle.readAll())
        open.close()
        dataHandle.close()
        setTextColourC(colours.lime)
        print('Downloaded successfully.')
        setTextColourC(colours.white)
    end
    error()
end

term.clear()
term.setCursorPos(1,1)

local selected = 1
local hasSelected = false
local sectionH = screenHeight-2

repeat
    term.clear()
    term.setCursorPos(1,1)
    setTextColourC(colours.green)
    print('Choose an AI to fight: ')
    local i = 0
    for name, _ in pairs(ainums) do
        i = i + 1
        if i == selected then
            setTextColourC(colours.yellow)
            io.write('> ')
            setTextColourC(colours.white)
            io.write(ainums[i] .. '\n')
        elseif (i < math.floor((selected/sectionH)+1)*sectionH) and (i >= math.floor(selected/sectionH)*sectionH) then
            if ainums[i] == '\n' then
                print()
            else
                setTextColourC(colours.white)
                print(ainums[i])
            end
        end
    end

    local newText = 'Page '.. math.floor((selected/sectionH)+1) .. ' of ' .. math.floor((#ainums/sectionH)+1)
    term.setCursorPos(screenWidth-#newText, 1)
    setTextColourC(colours.green)
    write(newText)
    setTextColourC(colours.white)

    local _, ek = os.pullEvent("key")
    if (ek == keys.up or ek == keys.w) and selected ~= 1 then
        selected = selected - 1
        if ainums[selected] == '\n' then
            selected = selected - 1
        end
        playSound("minecraft:ui.button.click")
    elseif (ek == keys.down or ek == keys.s) and selected ~= #ainums then
        selected = selected + 1
        if ainums[selected] == '\n' then
            selected = selected + 1
        end
        playSound("minecraft:ui.button.click")
    elseif (ek == keys.up or ek == keys.w) and selected == 1 then
        selected = #ainums
        playSound("minecraft:ui.button.click")
    elseif (ek == keys.down or ek == keys.s) and selected == #ainums then
        selected = 1
        playSound("minecraft:ui.button.click")
    elseif ek == keys.enter then
        ainame = ainums[selected]
        hasSelected = true
        playSound("minecraft:ui.button.click")
    end
    sleep(0.1)
until hasSelected

if not ainames[ainame] then
    term.clear()
    term.setCursorPos(1,1)
    printError('Error: Could not find function for AI "' .. ainame .. '"')
    error()
end

local specialability = 6
local knowledge = 1
local role = "Citizen"
if not debug_mode then
	if not _G["shotgun_hasLearned"] then
		_G["shotgun_hasLearned"] = {}
	end
	local i = 0
	local selected = 1
	local hasSelected = false
	repeat
		term.clear()
		term.setCursorPos(1,1)
		setTextColourC(colours.green)
		print("Select your class:")
		setTextColourC(colours.white)
		if selected == 1 then
			setTextColourC(colours.yellow)
			io.write(">")
			setTextColourC(colours.white)
			print(" Citizen")
			print("Veteran")
			print("Witch")
			print("Prophet")
			print("Empty Shell")
		elseif selected == 2 then
			print("Citizen")
			setTextColourC(colours.yellow)
			io.write(">")
			setTextColourC(colours.white)
			print(" Veteran")
			print("Witch")
			print("Prophet")
			print("Empty Shell")
		elseif selected == 3 then
			print("Citizen")
			print("Veteran")
			setTextColourC(colours.yellow)
			io.write(">")
			setTextColourC(colours.white)
			print(" Witch")
			print("Prophet")
			print("Empty Shell")
		elseif selected == 4 then
			print("Citizen")
			print("Veteran")
			print("Witch")
			setTextColourC(colours.yellow)
			io.write(">")
			setTextColourC(colours.white)
			print(" Prophet")
			print("Empty Shell")
		elseif selected == 5 then
			print("Citizen")
			print("Veteran")
			print("Witch")
			print("Prophet")
			setTextColourC(colours.yellow)
			io.write(">")
			setTextColourC(colours.white)
			print(" Empty Shell")
		end
		local _, ek = os.pullEvent("key")
		if (ek == keys.up or ek == keys.w) and selected ~= 1 then
			selected = selected - 1
			playSound("minecraft:ui.button.click")
		elseif (ek == keys.down or ek == keys.s) and selected ~= 5 then
			selected = selected + 1
			playSound("minecraft:ui.button.click")
		elseif (ek == keys.up or ek == keys.w) and selected == 1 then
			selected = 5
			playSound("minecraft:ui.button.click")
		elseif (ek == keys.down or ek == keys.s) and selected == 5 then
			selected = 1
			playSound("minecraft:ui.button.click")
		elseif ek == keys.enter then
			knowledge = selected
			hasSelected = true
			playSound("minecraft:ui.button.click")
		end
		sleep(0.1)
    until hasSelected
    
	if knowledge == 2 then
		specialability = 7
		role = "Veteran"
	elseif knowledge == 3 then
		specialability = 4
		role = "Witch"
	elseif knowledge == 4 then
		specialability = 5
		role = "Prophet"
	elseif knowledge == 5 then
		specialability = 8
		role = "Empty Shell"
	end
	term.clear()
	term.setCursorPos(1,1)
	if not _G["shotgun_hasLearned"][role] then
		setTextColourC(colours.green)
		print("How to play " .. role .. ":\n")
		setTextColourC(colours.white)
		print("Press W to Shoot. (Costs 1 ammo, will kill other player)")
		print("Press A to Reload. (Gives 1 ammo)")
		print("Press D to Block. (Prevents Shoot from killing you)")
		if knowledge == 2 then
			print("Press S to Retaliate. (Costs 2 ammo, bullets will be reflected, killing your opponent)")
			print("Additionally, you will start the game with 2 ammo.")
		elseif knowledge == 3 then
			print("Press S to Curse. (Costs 1 ammo, your opponent can't shoot next turn.)")
		elseif knowledge == 4 then
			print("Press S to Foresee. (Costs 4 ammo, allows you to see your opponent's next turn)")
		elseif knowledge == 5 then
			print("Press S to Succumb. (You will become unkillable, but you will lose 2 ammo per turn until you run out of ammo and die.)")
			print("You must kill your opponent after you have Succumbed, otherwise you will lose.")
		end
		setTextColourC(colours.orange)
		print("\nPress any key to continue.")
		setTextColourC(colours.white)
		os.pullEvent("key")
		playSound("minecraft:ui.button.click")
		_G["shotgun_hasLearned"][role] = true
	end
	term.clear()
	term.setCursorPos(1,1)
end

local function pullEventTab(n, rn)
	repeat
		local p = {os.pullEvent()}
		if n[p[1]] then
			if p[1] == "timer" then
				if p[2] == rn then
					return unpack(p)
				end
			else
				return unpack(p)
			end
		end
	until false
end


local move
local shielded
local cursed = false
local aicursed = false
local isPredicting = false
local permAmmo = false
local hasSuccumbed = false
local godMode = false
local ammo = 0
local currentAmmo = 0
local tmove = 91
local tmove2 = 91
local mlm = 91
local mlm2 = 91
local turns = 0
local localValues = {}

if specialability == 7 then
	ammo = 2
end

local function render(currentAmmo, playerAmmo, playersLastMove, botsLastMove, isCursed, botIsCursed, playerHasSuccumbed, isPredicting, playersCurrentMove, seed)
	term.clear()
	term.setCursorPos(1,1)
	if not g then
		g = math.random(1,9999999)
	end
    setTextColourC(colours.lightBlue)
    print("Your Ammo: " .. ammo)
    setTextColourC(colours.cyan)
    print(ainame .. "'s Ammo: " .. currentAmmo)
    setTextColourC(colours.white)
    if isPredicting then
        playSound("minecraft:entity.zombie_villager.converted")
        local result, _, _, disguise, cantSeeThrough, customColour = ainames[ainame](currentAmmo, playerAmmo, playersLastMove, botsLastMove, isCursed, botIsCursed, playerHasSuccumbed, true, playersCurrentMove, seed, localValues)
        if plays[result] then
            if (result == 3) or (result == 4) or (result == 7) then
                setTextColourC(colours.red)
            elseif (result == 1) or (result == 6) then
                setTextColourC(colours.lime)
            elseif (result == 2) or (result == 5) then
                setTextColourC(colours.orange)
            end
            if disguise and not cantSeeThrough then
                print("You saw through " .. ainame .. "'s disguise! They are about to play " .. plays[result] .. ".")
            else
                setTextColourC(customColour or colours.orange)
                print(ainame .. " is about to play " .. (disguise or plays[result]) .. ".")
            end
            setTextColourC(colours.white)
        else
            setTextColourC(colours.red)
            print(ainame .. " can also see the future!")
            setTextColourC(colours.white)
        end
    end
end

while true do
    local sed = math.random(1,9999999)
    turns = turns + 1f
    tmove = tmove2
    tmove2 = 0
    mlm = mlm2
    mlm2 = 0
    if permAmmo then
        ammo = 99
    end
    render(currentAmmo, ammo, tmove, mlm, cursed, aicursed, hasSuccumbed, isPredicting, move, sed, localValues)
    
    local move = 6
    local timern = 0
    if isPredicting and (not debug_mode) then
        timern = os.startTimer(2)
    elseif not debug_mode then
        timern = os.startTimer(1)
    end
    isPredicting = false
    
    repeat
        move = 0
        local event, key = pullEventTab({["timer"] = true, ["key"] = true}, timern)
        if event ~= "timer" then
            if key == 17 then
                move = 3
            elseif key == 30 then
                move = 1
            elseif key == 32 then
                move = 2
            elseif key == 31 then
                move = specialability
            end
        end
    until (move ~= 0 and plays[move]) or event == "timer"

    if not plays[move] then
        move = 6
    end
    
    local disguise

    local om, modifyValues, localValuesResp, disguise = ainames[ainame](currentAmmo, ammo, tmove, mlm, cursed, aicursed, hasSuccumbed, false, move, sed, localValues)
    if om == 92 then
        replay(true, turns, ammo, (modifyValues:gsub('%%botname%%', ainame) or "???"), godMode, specialability, hasSuccumbed)
    elseif om == 93 then
        replay(false, turns, ammo, (modifyValues:gsub('%%botname%%', ainame) or "???"), godMode, specialability, hasSuccumbed)
    end
    
    if modifyValues then
        for k, v in pairs(modifyValues) do
            if v then
                if k == 1 then
                    currentAmmo = v
                elseif k == 2 then
                    ammo = v
                elseif k == 3 then
                    cursed = v
                elseif k == 4 then
                    aicursed = v
                elseif k == 5 then
                    move = v
                end
            end
        end
    end
    
    if localValuesResp then
        localValues = localValuesResp
    end

    local last_sentence = ""
    if move == 3 and ammo <= 0 then
        last_sentence = "You played " .. plays[move] .. ", but you had no ammo. "
        move = 6
    elseif (move == 3 or move == 5) and (cursed == true) then
        last_sentence = "You played " .. plays[move] .. ", but you were cursed. "
        playSound("minecraft:entity.witch.ambient")
        playedASound = true
        move = 6
    elseif (move == 5 and ammo < 4) or (move == 4 and ammo <= 0) or (move == 7 and ammo < 2) then
        last_sentence = "You played " .. plays[move] .. ", but you didn't have enough ammo. "
        move = 6
    else
        last_sentence = "You played " .. plays[move] .. ". "
    end
    if move == 8 then
        if ammo < 3 then
            last_sentence = "You played " .. plays[move] .. ", but you didn't have enough ammo. "
        else
            playSound("minecraft:entity.wither.spawn")
            hasSuccumbed = true
            godMode = true
            specialability = 6
        end
    end
    
    tmove2 = move
    
    if om == 3 and currentAmmo <= 0 then
        last_sentence = last_sentence .. ainame .. " played " .. (disguise or plays[om]) .. ", but they had no ammo."
        om = 6
    elseif (om == 3 or om == 5) and (aicursed == true) then
        last_sentence = last_sentence .. ainame .. " played " .. (disguise or plays[om]) .. ", but they were cursed."
        playSound("minecraft:entity.witch.ambient")
        playedASound = true
        om = 6
    elseif (om == 5 and currentAmmo < 4) or (om == 4 and currentAmmo <= 0) or (om == 7 and currentAmmo < 2) then
        last_sentence = last_sentence .. ainame .. " played " .. (disguise or plays[om]) .. ", but they didn't have enough ammo."
        om = 6
    else
        last_sentence = last_sentence .. ainame .. " played " .. (disguise or plays[om]) .. "."
    end
    mlm2 = om
    print(last_sentence)

    if hasSuccumbed then
        ammo = ammo - 2
        if ammo <= 0 then
            replay(false, turns, 0, "You ran out of ammo and died.", false, 99)
        end
    end
    
    aicursed = false
    cursed = false
    if move == 5 then 
        isPredicting = true
        ammo = ammo - 4
    end
    if om == 5 then
        currentAmmo = currentAmmo - 4
    end 
    
    if move == 3 then
        ammo = ammo - 1
        if om == 1 or om == 4 or om == 5 or om == 6 then
            replay(true, turns, ammo, last_sentence, godMode, specialability, hasSuccumbed)
        elseif om == 2 and not disguise then
            playSound("minecraft:entity.zombie.attack_iron_door")
        end
    elseif move == 1 then
        if om == 3 then
            replay(false, turns, ammo, last_sentence, godMode, specialability, hasSuccumbed)
        else
            ammo = ammo + 1
        end
    elseif move == 4 or move == 5 or move == 6 then
        if move == 4 then
            ammo = ammo - 1
        end
        if om == 3 then
            replay(false, turns, ammo, last_sentence, godMode, specialability, hasSuccumbed)
        end
    elseif move == 7 then
        ammo = ammo - 2
        if om == 3 then
            replay(true, turns, ammo, last_sentence, godMode, specialability, hasSuccumbed)
        end
    end
    
    if om == 3 then
        currentAmmo = currentAmmo - 1
        if move == 1 or move == 4 or move == 5 or move == 6 then
            replay(false, turns, ammo, last_sentence, godMode, specialability, hasSuccumbed)
        elseif move == 2 and not disguise then
            playSound("minecraft:entity.zombie.attack_iron_door")
        end
    elseif om == 1 then
        if move == 3 then
            replay(true, turns, ammo, last_sentence, godMode, specialability, hasSuccumbed)
        else
            currentAmmo = currentAmmo + 1
        end
    elseif om == 4 or om == 5 or om == 6 then
        if om == 4 and turns ~= 1 then
            currentAmmo = currentAmmo - 1
        end
        if move == 3 then
            replay(true, turns, ammo, last_sentence, godMode, specialability, hasSuccumbed)
        end
    elseif om == 7 then
        currentAmmo = currentAmmo - 2
        if move == 3 then
            replay(false, turns, ammo, last_sentence, godMode, specialability, hasSuccumbed)
        end
    end
    if om == 4 then
        if not disguise then
            playSound("minecraft:entity.witch.ambient")
        end
        cursed = true
    end
    if move == 4 and not disguise then
        if not disguise then
            playSound("minecraft:entity.witch.ambient")
        end
        aicursed = true 
    end
    print()
    playSound("minecraft:ui.button.click")
    sleep(1)
end