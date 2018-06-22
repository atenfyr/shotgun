# Shotgun
A game I made for ComputerCraft that is intended to emulate the common school game that is known by several names such as Shotgun, 007, and War (not to be confused with the card game).

# Mechanics
Every few seconds, you can press W, A, D, or S in order to play. You can choose a bot to fight against, which will choose a move to play. In addition, you may choose a class, and each class has a special ability.

- W will shoot, which uses up one ammo and will kill the other player if they are vulnerable. If both the player and the bot shoot, then neither party will die.
- A will reload, which gives you one ammo but makes you vulnerable.
- D will block, which will not use any ammo but will prevent you from being killed.
- S will activate your special ability; each class has different special moves. For instance, the Prophet can see the future, and the Witch can prevent the bot from shooting on the next turn. Usually, these abilites will use at least one ammo.

# Installation
Shotgun can be installed using wget:

`wget https://raw.githubusercontent.com/atenfyr/shotgun/master/shotgun.lua shotgun`

Shotgun uses sound extensively; if a speaker from CC 1.8+ is connected or the game is run on a command computer, audio will be enabled.

# Mods
Shotgun includes a built-in modding platform that you can access in the program. If you wish to manually install a mod, place a .lua file in the shotgun_mods folder automatically created by Shotgun. However, Shotgun does have a built-in collection of mods that you can install from inside the program.

If you wish to view the source code of all built-in mods, see the [shotgun_mods](https://github.com/atenfyr/shotgun_mods) repository.
