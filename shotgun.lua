--[[
    Shotgun
    Written by Atenfyr
    Licensed under the MIT License
]]

-- send a DM to me on Discord if you want me to add your mod repository as a source or add a mod to the default repository: Atenfyr#9927
local sources = {'https://raw.githubusercontent.com/atenfyr/shotgun_mods/master/shotgun_repository'}

local config = {}

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

if not fs.exists('./shotgun_mods') then
    fs.makeDir('./shotgun_mods')
end

if not fs.exists('./shotgun_mods/config') then
    local h = fs.open('./shotgun_mods/config', 'w')
    h.write('{}')
    h.close()
end

local h = fs.open('./shotgun_mods/config', 'r')
config = textutils.unserialise(h.readAll())
h.close()

local args = {...}
local screenWidth, screenHeight = term.getSize()
local headers = {['User-Agent'] = 'Shotgun/0.0.7'} -- 0.0.7 isn't an actual version, it's just a pun based off of how in some regions the game's called "007"

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
		commands.exec("playsound " .. snd .. " master @a[r=20] ~ ~ ~ " .. (a or 1) .. " " .. (b or 1))
	end
end

local function replay(victory, t, a, la, gm, sa, hsum, forceWin)
	if not victory and gm and not forceWin then
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
	write("The game lasted ")
	if t > 20 then
		setTextColourC(colours.red)
	elseif t > 10 then
		setTextColourC(colours.orange)
	elseif t > 5 then
		setTextColourC(colours.green)
	else
		setTextColourC(colours.lime)
	end
	write(t .. " turns")
	setTextColourC(colours.white)
	write(", and you had ")
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
	write(a .. " ammo")
	setTextColourC(colours.white)
	write(".\nThanks for playing!\n")
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
    [91] = "Signal: No Previous Move", -- used by bot AIs when they request the last move on the first move of the game
    [92] = "Signal: Bot Lost", -- force the bot to lose
    [93] = "Signal: Bot Won", -- force the bot to win
    [99] = "Signal: Bot is Unpredictable" -- used by prophet
}

local customPlays = {}
local playFunctions = {}
local turnFunctions = {}
local specialability = 6
local classes = {'Citizen', 'Veteran', 'Witch', 'Prophet', 'Empty Shell'}
local classAbilities = {6, 7, 4, 5, 8}
local classInstructions = {}

local function addNewClass(name, specialAbility, instructions, positionInList)
    positionInList = positionInList or #classes+1
    table.insert(classes, positionInList, name)
    table.insert(classAbilities, positionInList, specialAbility)
    classInstructions[name] = instructions
end

local function addNewMove(id, name, prophetColour, behavesLike, requiredAmmo)
    plays[id] = name
    customPlays[id] = {name, prophetColour, behavesLike, requiredAmmo}
end

local function setSpecialAbility(id)
    specialability = id
end

local function set(setting, value)
    getfenv()[setting] = value
end

local function onPlay(move, f)
    playFunctions[move] = f
end

local function onTurn(f)
    turnFunctions[#turnFunctions+1] = f
end

local ainums = {}
local ainames = {}
local ainame = "Dummy"

local programEnvironment = { -- the environment that mods get
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
    xpcall = xpcall,
    parallel = parallel,
    sleep = sleep,
    write = write,
    print = print,

    specialability = specialability,
    plays = plays, -- table of IDs to names
    set = set, -- lets you set any variable. this lets you pretty much play god; please use sparingly
    playSound = playSound,
    addNewMove = addNewMove,
    setSpecialAbility = setSpecialAbility,
    addNewClass = addNewClass,
    onPlay = onPlay,
    onTurn = onTurn
}

function concatTablesNumerically(table1, table2, addNL)
    if addNL and #table2 > 0 and #table1 > 0 then
        table.insert(table2, 1, '\n')
    end
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

local listOfFiles = fs.list('./shotgun_mods')
local modList = {}
local modListFiles = {}
local globalInits = {}
local inits = {}
local modsAIsarefrom = {}
local modCount = 0

for k, v in pairs(listOfFiles) do
    if v:find('.lua') and not fs.isDir(v) then
        modFile = './shotgun_mods/' .. v
        local open = fs.open(modFile, 'r')
        local data = open.readAll()
        open.close()

        programEnvironment['modName'] = 'Unknown'
        local fn, err = loadstring(data)
        if err then
            printError('Error in mod file "' .. v .. '"!\n' .. err)
            error()
        end
        setfenv(fn, programEnvironment)
        pcall(fn)

        if programEnvironment['modName'] == 'Unknown' then
            printError('Mod file "' .. v .. '" has not been assigned a name. Please assign it a name by defining the modName variable.')
        end
        
        if not config[v] then
            concatTablesNumerically(ainums, programEnvironment['aiList'], true)
            concatTablesByOverriding(ainames, programEnvironment['aiFunctions'])
        end

        globalInits[#globalInits+1] = programEnvironment['globalInit']
        inits[programEnvironment['modName']] = programEnvironment['init']
        modList[#modList+1] = programEnvironment['modName']
        modListFiles[programEnvironment['modName']] = v
        modCount = modCount + 1

        for _, bot in pairs(programEnvironment['aiList']) do
            modsAIsarefrom[bot] = programEnvironment['modName']
        end
    end
end

if modCount == 0 then
    ainums = {}
    local dataHandle = http.get('https://raw.githubusercontent.com/atenfyr/shotgun_mods/master/__default.lua', headers)
    local open = fs.open('./shotgun_mods/__default.lua', 'w')
    open.write(dataHandle.readAll())
    open.close()
    dataHandle.close()

    local fn, err = loadfile('./shotgun_mods/__default.lua')
    if err then
        printError('Error in mod file "' .. v .. '"!\n' .. err)
        error()
    end
    setfenv(fn, programEnvironment)
    pcall(fn)
    
    concatTablesNumerically(ainums, programEnvironment['aiList'], true)
    concatTablesByOverriding(ainames, programEnvironment['aiFunctions'])

    modList[#modList+1] = programEnvironment['modName']
    modListFiles[programEnvironment['modName']] = v
    modCount = modCount + 1
end

-- run globalInit functions in all mods
for _, f in pairs(globalInits) do
    f()
end

ainums[#ainums+1] = '\n'
ainums[#ainums+1] = 'Exit'
if ainums[1] == '\n' then
    table.remove(ainums, 1)
end

local function centrePrint(str, cursorY, offset)
    local offset = offset or 0
    local cursorX = math.floor((screenWidth-string.len(str))/2)+offset
    term.setCursorPos(cursorX, cursorY) 
    write(str)
    return cursorX
end

term.clear()
term.setCursorPos(1,1)

local selected = 1
local hasSelected = false
local sectionH = screenHeight-2
local centreY = math.floor(screenHeight/2)

local isModLoader = false

local options = {'Play', 'Mods', 'Exit'}
repeat
    term.clear()
    term.setCursorPos(1,1)
    setTextColourC(colours.green)
    centrePrint("-Shotgun-", centreY-#options)
    setTextColourC(colours.white)
    for i = 1, #options do
        if i == selected then
            local cursorX = centrePrint(options[i], centreY-#options+i+1)
            setTextColourC(colours.yellow)
            term.setCursorPos(cursorX-2, centreY-#options+i+1)
            write('[')
            term.setCursorPos(cursorX+string.len(options[i])+1, centreY-#options+i+1)
            write(']')
            setTextColourC(colours.white)
        else
            centrePrint(options[i], centreY-#options+i+1)
        end
    end

    local _, ek = os.pullEvent("key")
    if (ek == keys.up or ek == keys.w) and selected ~= 1 then
        selected = selected - 1
        playSound("minecraft:ui.button.click")
    elseif (ek == keys.down or ek == keys.s) and selected ~= #options then
        selected = selected + 1
        playSound("minecraft:ui.button.click")
    elseif (ek == keys.up or ek == keys.w) and selected == 1 then
        selected = #options
        playSound("minecraft:ui.button.click")
    elseif (ek == keys.down or ek == keys.s) and selected == #options then
        selected = 1
        playSound("minecraft:ui.button.click")
    elseif ek == keys.enter then
        playSound("minecraft:ui.button.click")
        if selected == 2 then
            isModLoader = true
        elseif selected == 3 then
            term.clear()
            term.setCursorPos(1,1)
            error()
        end
        hasSelected = true
    end
    sleep(0.1)
until hasSelected

selected = 1
hasSelected = false

if isModLoader then -- mod loader GUI
    modList[#modList+1] = '\n'
    modList[#modList+1] = 'Install new mods'
    modList[#modList+1] = 'Exit'
    while true do
        selected = 1
        hasSelected = false
        local chosen
        repeat
            term.clear()
            term.setCursorPos(1,1)
            setTextColourC(colours.green)
            print('Choose a mod:')
            local i = 0
            for _, modName in pairs(modList) do
                i = i + 1
                if i == selected then
                    setTextColourC(colours.yellow)
                    write('- ')
                    setTextColourC(colours.white)
                    write(modName .. '\n')
                elseif (i < math.floor((selected/sectionH)+1)*sectionH) and (i >= math.floor(selected/sectionH)*sectionH) then
                    setTextColourC(colours.white)
                    if modName == '\n' then
                        print()
                    else
                        print(modName)
                    end
                end
            end
        
            local newText = 'Page '.. math.floor((selected/sectionH)+1) .. ' of ' .. math.floor((#modList/sectionH)+1)
            term.setCursorPos(screenWidth-#newText, 1)
            setTextColourC(colours.green)
            write(newText)
            setTextColourC(colours.white)
        
            local _, ek = os.pullEvent("key")
            if (ek == keys.up or ek == keys.w) and selected ~= 1 then
                selected = selected - 1
                if modList[selected] == '\n' then
                    selected = selected - 1
                end
                playSound("minecraft:ui.button.click")
            elseif (ek == keys.down or ek == keys.s) and selected ~= #modList then
                selected = selected + 1
                if modList[selected] == '\n' then
                    selected = selected + 1
                end
                playSound("minecraft:ui.button.click")
            elseif (ek == keys.up or ek == keys.w) and selected == 1 then
                selected = #modList
                playSound("minecraft:ui.button.click")
            elseif (ek == keys.down or ek == keys.s) and selected == #modList then
                selected = 1
                playSound("minecraft:ui.button.click")
            elseif ek == keys.enter then
                hasSelected = true
                if selected == #modList-1 then -- install new mods
                    playSound("minecraft:ui.button.click")
                    
                    local files = {}
                    for _, url in pairs(sources) do
                        local h = http.get(url, headers)
                        local theseFiles = textutils.unserialise(h.readAll())
                        h.close()

                        concatTablesNumerically(files, theseFiles)
                    end

                    files[#files+1] = {'\n', '\n'}
                    files[#files+1] = {'Back', 'Back'}
                    selected = 1
                    hasSelected = false
                    repeat
                        term.clear()
                        term.setCursorPos(1,1)
                        setTextColourC(colours.green)
                        print('Available mods:')
                        for i = 1, #files do
                            if i == selected then
                                setTextColourC(colours.yellow)
                                write('- ')
                                setTextColourC(colours.white)
                                if not files[i][4] then
                                    write(files[i][1] .. '\n')
                                else
                                    write(files[i][1] .. ' (' .. files[i][4] .. ')\n')
                                end
                            elseif (i < math.floor((selected/sectionH)+1)*sectionH) and (i >= math.floor(selected/sectionH)*sectionH) then
                                setTextColourC(colours.white)
                                if files[i][1] == '\n' then
                                    print()
                                else
                                    if not files[i][4] then
                                        write(files[i][1] .. '\n')
                                    else
                                        write(files[i][1] .. ' (' .. files[i][4] .. ')\n')
                                    end
                                end
                            end
                        end

                        local newText = 'Page '.. math.floor((selected/sectionH)+1) .. ' of ' .. math.floor((#modList/sectionH)+1)
                        term.setCursorPos(screenWidth-#newText, 1)
                        setTextColourC(colours.green)
                        write(newText)
                        setTextColourC(colours.white)
                    
                        local _, ek = os.pullEvent("key")
                        if (ek == keys.up or ek == keys.w) and selected ~= 1 then
                            selected = selected - 1
                            if files[selected][1] == '\n' then
                                selected = selected - 1
                            end
                            playSound("minecraft:ui.button.click")
                        elseif (ek == keys.down or ek == keys.s) and selected ~= #files then
                            selected = selected + 1
                            if files[selected][1] == '\n' then
                                selected = selected + 1
                            end
                            playSound("minecraft:ui.button.click")
                        elseif (ek == keys.up or ek == keys.w) and selected == 1 then
                            selected = #files
                            playSound("minecraft:ui.button.click")
                        elseif (ek == keys.down or ek == keys.s) and selected == #files then
                            selected = 1
                            playSound("minecraft:ui.button.click")
                        elseif ek == keys.enter then
                            playSound("minecraft:ui.button.click")
                            hasSelected = true
                            choice = files[selected][2]
                            if choice ~= 'Back' then
                                if not modListFiles[files[selected][1]] then
                                    term.clear()
                                    term.setCursorPos(1,1)
                                    setTextColourC(colours.yellow)
                                    write('Connecting... ')
                                    local h = http.get(choice, headers)
                                    local data = h.readAll()
                                    h.close()
                                    setTextColourC(colours.lime)
                                    write('Success.\n')

                                    local open = fs.open('./shotgun_mods/' .. files[selected][3], 'w')
                                    open.write(data)
                                    open.close()

                                    table.insert(modList, 1, files[selected][1])
                                    modListFiles[files[selected][1]] = files[selected][3]

                                    setTextColourC(colours.lime)
                                    print('Finished!')
                                    setTextColourC(colours.yellow)
                                    print('\nPress any key to continue.')
                                    os.pullEvent('key')
                                else
                                    term.clear()
                                    term.setCursorPos(1,1)
                                    setTextColourC(colours.yellow)
                                    print('This mod is already installed on your system.\n\nPress any key to continue.')
                                    os.pullEvent('key')
                                end
                            else
                                hasSelected = true
                            end
                            playSound("minecraft:ui.button.click")
                        end
                    until hasSelected
                    selected = 1
                    hasSelected = false
                elseif selected == #modList then -- exit
                    playSound("minecraft:ui.button.click")
                    term.clear()
                    term.setCursorPos(1,1)
                    error()
                end
                chosen = modListFiles[modList[selected]]
                playSound("minecraft:ui.button.click")
            end
            sleep(0.1)
        until hasSelected

        term.clear()
        term.setCursorPos(1,1)
        selected = 1
        hasSelected = false
        options = {'Disable', 'Uninstall', 'Back'}
        if config[chosen] then
            options[1] = 'Enable'
        end

        repeat
            term.clear()
            term.setCursorPos(1,1)
            setTextColourC(colours.green)
            print('Options: ')

            for i = 1, #options do
                if i == selected then
                    setTextColourC(colours.yellow)
                    write('- ')
                    setTextColourC(colours.white)
                    write(options[i] .. '\n')
                else
                    setTextColourC(colours.white)
                    print(options[i])
                end
            end
        
            local _, ek = os.pullEvent("key")
            if (ek == keys.up or ek == keys.w) and selected ~= 1 then
                selected = selected - 1
                playSound("minecraft:ui.button.click")
            elseif (ek == keys.down or ek == keys.s) and selected ~= #options then
                selected = selected + 1
                playSound("minecraft:ui.button.click")
            elseif (ek == keys.up or ek == keys.w) and selected == 1 then
                selected = #options
                playSound("minecraft:ui.button.click")
            elseif (ek == keys.down or ek == keys.s) and selected == #options then
                selected = 1
                playSound("minecraft:ui.button.click")
            elseif ek == keys.enter then
                if selected == #options then
                    hasSelected = true
                elseif selected == 1 then
                    if not config[chosen] then
                        config[chosen] = true
                    else
                        config[chosen] = false
                    end
                    local h = fs.open('./shotgun_mods/config', 'w')
                    h.write(textutils.serialise(config))
                    h.close()

                    options = {'Disable', 'Uninstall', 'Back'}
                    if config[chosen] then
                        options[1] = 'Enable'
                    end
                elseif selected == 2 then
                    playSound("minecraft:ui.button.click")
                    selected = 1
                    options2 = {'Yes', 'No'}
                    repeat
                        term.clear()
                        term.setCursorPos(1,1)
                        setTextColourC(colours.green)
                        print('Are you sure you want to do this?')
            
                        for i = 1, #options2 do
                            if i == selected then
                                setTextColourC(colours.yellow)
                                write('- ')
                                setTextColourC(colours.white)
                                write(options2[i] .. '\n')
                            else
                                setTextColourC(colours.white)
                                print(options2[i])
                            end
                        end
                    
                        local _, ek = os.pullEvent("key")
                        if (ek == keys.up or ek == keys.w) and selected ~= 1 then
                            selected = selected - 1
                            playSound("minecraft:ui.button.click")
                        elseif (ek == keys.down or ek == keys.s) and selected ~= #options2 then
                            selected = selected + 1
                            playSound("minecraft:ui.button.click")
                        elseif (ek == keys.up or ek == keys.w) and selected == 1 then
                            selected = #options2
                            playSound("minecraft:ui.button.click")
                        elseif (ek == keys.down or ek == keys.s) and selected == #options2 then
                            selected = 1
                            playSound("minecraft:ui.button.click")
                        elseif ek == keys.enter then
                            playSound("minecraft:ui.button.click")
                            if selected == 1 then
                                fs.delete('./shotgun_mods/' .. chosen)
                                for nameOfMod, modPath in pairs(modListFiles) do
                                    if modPath == chosen then
                                        modListFiles[nameOfMod] = nil
                                        for number, nameOfMod2 in pairs(modList) do
                                            if nameOfMod2 == nameOfMod then
                                                table.remove(modList, number)
                                                break
                                            end
                                        end
                                        break
                                    end
                                end

                                term.clear()
                                term.setCursorPos(1,1)
                                setTextColourC(colours.green)
                                print('Successfully uninstalled.')
                                setTextColourC(colours.yellow)
                                write('- ')
                                setTextColourC(colours.white)
                                write('Okay')
                                os.pullEvent("key")
                                playSound("minecraft:ui.button.click")
                            end
                            hasSelected = true
                        end
                    until hasSelected
                end
                playSound("minecraft:ui.button.click")
            end
        until hasSelected
    end
    error() 
end

local pageCount = math.floor((#ainums/sectionH)+1)
local currentPage, mode

repeat
    term.clear()
    term.setCursorPos(1,1)
    setTextColourC(colours.green)
    print('Choose an AI to fight: ')
    
    local i = 0
    local currentPage = math.floor((selected/sectionH)+1)

    for name, _ in pairs(ainums) do
        i = i + 1
        if i == selected then
            setTextColourC(colours.yellow)
            write('- ')
            setTextColourC(colours.white)
            write(ainums[i] .. '\n')
        elseif (i < math.floor((selected/sectionH)+1)*sectionH) and (i >= math.floor(selected/sectionH)*sectionH) then
            if ainums[i] == '\n' then
                print()
            else
                setTextColourC(colours.white)
                print(ainums[i])
            end
        end
    end

    -- v = math.floor((selected-sectionH)/sectionH)*sectionH)
    -- ^ = math.floor((selected+sectionH)/sectionH)*sectionH)
    term.setCursorPos(screenWidth, screenHeight-1)
    if pageCount > 1 then
        setTextColourC(colours.green)
        if currentPage == 1 then
            mode = 1
            setTextColourC(colours.red)
        elseif currentPage == pageCount then
            mode = 2
        else
            mode = 3
        end
        write('^')
        term.setCursorPos(screenWidth, screenHeight)

        if currentPage == 1 then
            setTextColourC(colours.green)
        elseif currentPage == pageCount then
            setTextColourC(colours.red)
        end
        write('v')
    else
        setTextColourC(colours.red)
        write('^')
        term.setCursorPos(screenWidth, screenHeight)
        write('v')
    end

    local newText = 'Page '.. currentPage .. ' of ' .. pageCount
    term.setCursorPos(screenWidth-#newText, 1)
    setTextColourC(colours.green)
    write(newText)
    setTextColourC(colours.white)

    local ev, ek, x, y = pullEventTab({["key"] = true, ["mouse_click"] = true})
    if ev == "key" then
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
    else
        if mode == 1 then -- v
            if x == screenWidth and y == screenHeight then
                selected = math.floor((selected+sectionH)/sectionH)*sectionH
                playSound("minecraft:ui.button.click")
            end
        elseif mode == 2 then -- ^
            if x == screenWidth and y == screenHeight-1 then
                selected = math.floor((selected-sectionH)/sectionH)*sectionH
                playSound("minecraft:ui.button.click")
            end
        elseif mode == 3 then -- ^ v
            if x == screenWidth then
                if y == screenHeight then
                    selected = math.floor((selected+sectionH)/sectionH)*sectionH
                    playSound("minecraft:ui.button.click")
                elseif y == screenHeight-1 then
                    selected = math.floor((selected-sectionH)/sectionH)*sectionH
                    playSound("minecraft:ui.button.click")
                end
            end
        end
    end

    if selected == 0 then
        selected = 1
    end
    sleep(0.1)
until hasSelected

if ainame == 'Exit' then
    term.clear()
    term.setCursorPos(1,1)
    error()
end

if not ainames[ainame] then
    term.clear()
    term.setCursorPos(1,1)
    printError('Error: Could not find function for AI "' .. ainame .. '"')
    error()
end

local role = "Citizen"
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
    for i = 1, #classes do
        if i == selected then
            setTextColourC(colours.yellow)
            write('- ')
            setTextColourC(colours.white)
        end
        if classes[i] == '\n' then
            print()
        else
            print(classes[i])
        end
    end

    local _, ek = os.pullEvent("key")
    if (ek == keys.up or ek == keys.w) and selected ~= 1 then
        selected = selected - 1
        playSound("minecraft:ui.button.click")
    elseif (ek == keys.down or ek == keys.s) and selected ~= #classes then
        selected = selected + 1
        playSound("minecraft:ui.button.click")
    elseif (ek == keys.up or ek == keys.w) and selected == 1 then
        selected = #classes
        playSound("minecraft:ui.button.click")
    elseif (ek == keys.down or ek == keys.s) and selected == #classes then
        selected = 1
        playSound("minecraft:ui.button.click")
    elseif ek == keys.enter then
        role = classes[selected]
        specialability = classAbilities[selected]
        hasSelected = true
        playSound("minecraft:ui.button.click")
    end
    sleep(0.1)
until hasSelected

term.clear()
term.setCursorPos(1,1)

if not _G["shotgun_hasLearned"][role] then
    setTextColourC(colours.green)
    print("How to play " .. role .. ":\n")
    setTextColourC(colours.white)
    print("Press W to Shoot. (Costs 1 ammo, will kill other player)")
    print("Press A to Reload. (Gives 1 ammo)")
    print("Press D to Block. (Prevents Shoot from killing you)")
    if role == 'Veteran' then
        print("Press S to Retaliate. (Costs 2 ammo, bullets will be reflected, killing your opponent)")
        print("Additionally, you will start the game with 2 ammo.")
    elseif role == 'Witch' then
        print("Press S to Curse. (Costs 1 ammo, your opponent can't shoot next turn.)")
    elseif role == 'Prophet' then
        print("Press S to Foresee. (Costs 4 ammo, allows you to see your opponent's next turn)")
    elseif role == 'Empty Shell' then
        print("Press S to Succumb. (You will become unkillable, but you will lose 2 ammo per turn until you run out of ammo and die.)")
        print("You must kill your opponent after you have Succumbed, otherwise you will lose.")
    elseif role ~= 'Citizen' then
        write('Press S to play ' .. plays[specialability] .. '.')
        if classInstructions[role] then
            write(' (' .. classInstructions[role] .. ')')
        end
        write('\n')
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

local shielded
local cursed = false
local aicursed = false
local isPredicting = false
local hasSuccumbed = false
local godMode = false
local ammo = 0
local currentAmmo = 0
local tmove = 91
local mlm = 91
local turns = 0
local move = 6
local newLastSentence
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

    --isPredicting = true
    if isPredicting then
        playSound("minecraft:entity.zombie_villager.converted")
        local result, _, _, disguise = ainames[ainame](currentAmmo, playerAmmo, playersLastMove, botsLastMove, isCursed, botIsCursed, playerHasSuccumbed, true, playersCurrentMove, seed, localValues)
        if result >= 90 and result <= 99 then -- all signals
            setTextColourC(colours.red)
            print("You can't quite seem to figure it out..")
            setTextColourC(colours.white)
        else
            if (result == 3) or (result == 4) or (result == 7) then
                setTextColourC(colours.red)
            elseif (result == 1) or (result == 6) then
                setTextColourC(colours.lime)
            elseif (result == 2) or (result == 5) then
                setTextColourC(colours.orange)
            elseif customPlays[result] then
                setTextColourC(customPlays[result][2])
            end
            if disguise then
                print("You saw through " .. ainame .. "'s disguise! They are about to play " .. plays[result] .. ".")
            else
                print(ainame .. " is about to play " .. plays[result] .. ".")
            end
            setTextColourC(colours.white)
        end
    end
end

if inits[modsAIsarefrom[ainame]] then
    inits[modsAIsarefrom[ainame]](ainame)
end

local function runReplace(modifyValues)
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
            elseif k == 6 then
                newLastSentence = v
            end
        end
    end
end

while true do
    local sed = math.random(1,9999999)
    turns = turns + 1
    render(currentAmmo, ammo, tmove, mlm, cursed, aicursed, hasSuccumbed, isPredicting, move, sed, localValues)
    
    local timern = 0
    if isPredicting then
        timern = os.startTimer(2)
    else
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
    
    for _, f in pairs(turnFunctions) do
        local om2, modifyValues2, localValuesResp2, disguise2 = f(currentAmmo, ammo, tmove, mlm, cursed, aicursed, hasSuccumbed, false, move, sed, localValues)
        if om2 and om2 ~= 'nothing' then om = om2 end
        if modifyValues2 and type(modifyValues2) == 'table' then 
            modifyValues = modifyValues2
        end
        if localValuesResp2 and localValuesResp2 ~= 'nothing' then localValues = localValuesResp2 end
        if disguise2 and disguise2 ~= 'nothing' then disguise = disguise2 end
    end

    if om == 92 then
        replay(true, turns, ammo, (modifyValues:gsub('%%botname%%', ainame) or "???"), godMode, specialability, hasSuccumbed, true)
    elseif om == 93 then
        replay(false, turns, ammo, (modifyValues:gsub('%%botname%%', ainame) or "???"), godMode, specialability, hasSuccumbed, true)
    end
    
    newLastSentence = nil

    if playFunctions[move] then
        runReplace(playFunctions[move](false, currentAmmo, ammo, tmove, mlm, cursed, aicursed, hasSuccumbed, false, move, sed, localValues))
    end

    if playFunctions[om] then
        runReplace(playFunctions[om](true, currentAmmo, ammo, tmove, mlm, cursed, aicursed, hasSuccumbed, false, move, sed, localValues))
    end

    if modifyValues and type(modifyValues) == 'table' then
        runReplace(modifyValues)
    end

    if disguise == "nothing" then disguise = nil end
    
    if localValuesResp then
        localValues = localValuesResp
    end

    if currentAmmo < 0 then
        currentAmmo = 0
    end
    if ammo < 0 then
        ammo = 0
    end

    local lastSentence = ""
    if move == 3 and ammo <= 0 then
        lastSentence = "You played " .. plays[move] .. ", but you had no ammo. "
        move = 6
    elseif (move == 3 or move == 5) and (cursed == true) then
        lastSentence = "You played " .. plays[move] .. ", but you were cursed. "
        playSound("minecraft:entity.witch.ambient")
        playedASound = true
        move = 6
    elseif (move == 5 and ammo < 4) or (move == 4 and ammo <= 0) or (move == 7 and ammo < 2) or (customPlays[move] and customPlays[move][4] and ammo < customPlays[move][4]) then
        lastSentence = "You played " .. plays[move] .. ", but you didn't have enough ammo. "
        move = 6
    else
        lastSentence = "You played " .. plays[move] .. ". "
    end

    if move == 8 then
        if ammo < 3 then
            lastSentence = "You played " .. plays[move] .. ", but you didn't have enough ammo. "
        else
            playSound("minecraft:entity.wither.spawn")
            hasSuccumbed = true
            godMode = true
            specialability = 6
        end
    end
        
    lastSentence = lastSentence .. ainame .. " played " .. (disguise or plays[om])
    if om == 3 and currentAmmo <= 0 then
        lastSentence = lastSentence .. ", but they had no ammo."
        om = 6
    elseif (om == 3 or om == 5) and (aicursed == true) then
        lastSentence = lastSentence .. ", but they were cursed."
        playSound("minecraft:entity.witch.ambient")
        playedASound = true
        om = 6
    elseif (om == 5 and currentAmmo < 4) or (om == 4 and currentAmmo <= 0) or (om == 7 and currentAmmo < 2) or (customPlays[om] and customPlays[om][4] and currentAmmo < customPlays[om][4]) then
        lastSentence = lastSentence .. ", but they didn't have enough ammo."
        om = 6
    else
        lastSentence = lastSentence .. "."
    end

    if customPlays[move] and customPlays[move][4] then
        ammo = ammo - customPlays[move][4]
    end

    if customPlays[om] and customPlays[om][4] then
        currentAmmo = currentAmmo - customPlays[om][4]
    end

    if newLastSentence then
        lastSentence = newLastSentence
    end
    print(lastSentence)

    tmove = move
    mlm = om

    if customPlays[move] then
        move = customPlays[move][3]
        disguise = true -- mute sounds
    end
    if customPlays[om] then
        om = customPlays[om][3]
    end

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
            replay(true, turns, ammo, lastSentence, godMode, specialability, hasSuccumbed)
        elseif om == 2 and not disguise then
            playSound("minecraft:entity.zombie.attack_iron_door")
        end
    elseif move == 1 then
        if om == 3 then
            replay(false, turns, ammo, lastSentence, godMode, specialability, hasSuccumbed)
        else
            ammo = ammo + 1
        end
    elseif move == 4 or move == 5 or move == 6 then
        if move == 4 then
            ammo = ammo - 1
        end
        if om == 3 then
            replay(false, turns, ammo, lastSentence, godMode, specialability, hasSuccumbed)
        end
    elseif move == 7 then
        ammo = ammo - 2
        if om == 3 then
            replay(true, turns, ammo, lastSentence, godMode, specialability, hasSuccumbed)
        end
    end
    
    if om == 3 then
        currentAmmo = currentAmmo - 1
        if move == 1 or move == 4 or move == 5 or move == 6 then
            replay(false, turns, ammo, lastSentence, godMode, specialability, hasSuccumbed)
        elseif move == 2 and not disguise then
            playSound("minecraft:entity.zombie.attack_iron_door")
        end
    elseif om == 1 then
        if move == 3 then
            replay(true, turns, ammo, lastSentence, godMode, specialability, hasSuccumbed)
        else
            currentAmmo = currentAmmo + 1
        end
    elseif om == 4 or om == 5 or om == 6 then
        if om == 4 and turns ~= 1 then
            currentAmmo = currentAmmo - 1
        end
        if move == 3 then
            replay(true, turns, ammo, lastSentence, godMode, specialability, hasSuccumbed)
        end
    elseif om == 7 then
        currentAmmo = currentAmmo - 2
        if move == 3 then
            replay(false, turns, ammo, lastSentence, godMode, specialability, hasSuccumbed)
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