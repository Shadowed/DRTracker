local major = "DRData-1.0"
local minor = tonumber(string.match("$Revision: 793$", "(%d+)") or 1)

assert(LibStub, string.format("%s requires LibStub.", major))

local Data = LibStub:NewLibrary(major, minor)
if( not Data ) then return end

-- How long before DR resets
Data.RESET_TIME = 18

-- List of spellID -> DR category
Data.spells = {
	--[[ TAUNT ]]--
	-- Taunt
	[53477] = "taunt",
	-- Mocking Blow
	[694] = "taunt",
	-- Growl (Druid)
	[6795] = "taunt",
	-- Growl (Pet)
	[2649] = "taunt",
	[14916] = "taunt",
	[14917] = "taunt",
	[14918] = "taunt",
	[14919] = "taunt",
	[14920] = "taunt",
	[14921] = "taunt",
	[27047] = "taunt",
	[61676] = "taunt",
	-- Dark Command
	[56222] = "taunt",
	-- Hand of Reckoning
	[62124] = "taunt",
	-- Righteous Defense
	[31790] = "taunt",
	-- Distracting Shot
	[20736] = "taunt",
	-- Challenging Shout
	[1161] = "taunt",
	-- Challenging Roar
	[5209] = "taunt",
	-- Death Grip
	[49560] = "taunt",
	-- Challenging Howl
	[59671] = "taunt",
	-- Angered Earth
	[36213] = "taunt",
	
	--[[ DISORIENTS ]]--
	-- Dragon's Breath
	[31661] = "disorient",
	[33041] = "disorient",
	[33042] = "disorient",
	[33043] = "disorient",
	[42949] = "disorient",
	[42950] = "disorient",
	
	-- Hungering Cold
	[49203] = "disorient",
	
	-- Sap
	[6770] = "disorient",
	[2070] = "disorient",
	[11297] = "disorient",
	[51724] = "disorient",
	
	-- Gouge
	[1776] = "disorient",
		
	-- Hex (Guessing)
	[51514] = "disorient",
	
	-- Shackle
	[9484] = "disorient",
	[9485] = "disorient",
	[10955] = "disorient",
	
	-- Polymorph
	[118] = "disorient",
	[12824] = "disorient",
	[12825] = "disorient",
	[28272] = "disorient",
	[28271] = "disorient",
	[12826] = "disorient",
	[61305] = "disorient",
	[61025] = "disorient",
	
	-- Repentance
	[20066] = "disorient",
		
	--[[ SILENCES ]]--
	-- Nether Shock
	[53588] = "silence",
	[53589] = "silence",
	
	-- Garrote
	[1330] = "silence",
	
	-- Arcane Torrent (Energy version)
	[25046] = "silence",
	
	-- Arcane Torrent (Mana version)
	[28730] = "silence",
	
	-- Arcane Torrent (Runic power version)
	[50613] = "silence",
	
	-- Silence
	[15487] = "silence",

	-- Silencing Shot
	[34490] = "silence",

	-- Improved Kick
	[18425] = "silence",

	-- Improved Counterspell
	[18469] = "silence",
	
	-- Strangulate
	[47476] = "silence",
	[49913] = "silence",
	[49914] = "silence",
	[49915] = "silence",
	[49916] = "silence",
	
	-- Gag Order (talent)
	[18498] = "silence",
	
	--[[ DISARMS ]]--
	-- Snatch
	[53542] = "disarm",
	[53543] = "disarm",
	
	-- Dismantle
	[51722] = "disarm",
	
	-- Disarm
	[676] = "disarm",
	
	-- Chimera Shot - Scorpid
	[53359] = "disarm",
	
	-- Psychic Horror (Disarm effect)
	[64058] = "disarm",
	
	--[[ FEARS ]]--
	-- Blind
	[2094] = "fear",

	-- Fear (Warlock)
	[5782] = "fear",
	[6213] = "fear",
	[6215] = "fear",
	
	-- Seduction (Pet)
	[6358] = "fear",
	
	-- Howl of Terror
	[5484] = "fear",
	[17928] = "fear",

	-- Psychic scream
	[8122] = "fear",
	[8124] = "fear",
	[10888] = "fear",
	[10890] = "fear",
	
	-- Scare Beast
	[1513] = "fear",
	[14326] = "fear",
	[14327] = "fear",
	
	-- Turn Evil
	[10326] = "fear",
	
	-- Intimidating Shout
	[5246] = "fear",
			
	--[[ CONTROL STUNS ]]--
	-- Gnaw
	[47481] = "ctrlstun",
	
	-- Intercept (Felguard)
	[30153] = "ctrlstun",
	[30195] = "ctrlstun",
	[30197] = "ctrlstun",
	[47995] = "ctrlstun",
	
	-- Ravage
	[50518] = "ctrlstun",
	[53558] = "ctrlstun",
	[53559] = "ctrlstun",
	[53560] = "ctrlstun",
	[53561] = "ctrlstun",
	[53562] = "ctrlstun",
	
	-- Sonic Blast
	[50519] = "ctrlstun",
	[53564] = "ctrlstun",
	[53565] = "ctrlstun",
	[53566] = "ctrlstun",
	[53567] = "ctrlstun",
	[53568] = "ctrlstun",
	
	-- Concussion Blow
	[12809] = "ctrlstun",
	
	-- Shockwave
	[46968] = "ctrlstun",
	
	-- Hammer of Justice
	[853] = "ctrlstun",
	[5588] = "ctrlstun",
	[5589] = "ctrlstun",
	[10308] = "ctrlstun",

	-- Bash
	[5211] = "ctrlstun",
	[6798] = "ctrlstun",
	[8983] = "ctrlstun",
	
	-- Intimidation
	[19577] = "ctrlstun",

	-- Charge
	[7922] = "ctrlstun",

	-- Maim
	[22570] = "ctrlstun",
	[49802] = "ctrlstun",

	-- Kidney Shot
	[408] = "ctrlstun",
	[8643] = "ctrlstun",

	-- War Stomp
	[20549] = "ctrlstun",

	-- Intercept
	[20252] = "ctrlstun",
	
	-- Deep Freeze
	[44572] = "ctrlstun",
			
	-- Shadowfury
	[30283] = "ctrlstun", 
	[30413] = "ctrlstun",
	[30414] = "ctrlstun",
	
	-- Holy Wrath
	[2812] = "ctrlstun",
	
	-- Inferno Effect
	[22703] = "ctrlstun",
	
	-- Demon Charge
	[60995] = "ctrlstun",
	
	-- Impact
	[12355] = "ctrlstun",
	
	-- Gnaw (Ghoul)
	[47481] = "ctrlstun",
	
	-- Glyph of Death Grip
	[58628] = "ctrlstun",
	
	--[[ RANDOM STUNS ]]--
	-- Improved Fire Nova Totem
	[64538] = "rndstun",
	[51880] = "rndstun",
	
	-- Stoneclaw Stun
	[39796] = "rndstun",
	
	-- Starfire Stun
	[16922] = "rndstun",
	
	-- Stormherald/Deep Thunder
	[34510] = "rndstun",
	
	-- Seal of Justice
	[20170] = "rndstun",
	
	-- Revenge Stun
	[12798] = "rndstun",
	
	--[[ CYCLONE ]]--
	-- Cyclone
	[33786] = "cyclone",
	
	--[[ ROOTS ]]--
	-- Freeze (Water Elemental)
	[33395] = "root",
	
	-- Frost Nova
	[122] = "root",
	[865] = "root",
	[6131] = "root",
	[10230] = "root",
	[27088] = "root",
	[42917] = "root",
	
	-- Entangling Roots
	[339] = "root",
	[1062] = "root",
	[5195] = "root",
	[5196] = "root",
	[9852] = "root",
	[9853] = "root",
	[26989] = "root",
	[53308] = "root",

	--[[ RANDOM ROOTS ]]--
	-- Improved Hamstring
	[23694] = "rndroot",
	
	-- Frostbite
	[12494] = "rndroot",

	--[[ SLEEPS ]]--
	-- Hibernate
	[2637] = "sleep",
	[18657] = "sleep",
	[18658] = "sleep",
	
	-- Banish
	[710] = "sleep",
	[18647] = "sleep",
	
	-- Freezing Trap
	[3355] = "freezetrap",
	[14308] = "freezetrap",
	[14309] = "freezetrap",
	
	-- Freezing Arrow
	[60210] = "freezetrap",

	-- Wyvern Sting
	[19386] = "freezetrap",
	[24132] = "freezetrap",
	[24133] = "freezetrap",
	[27068] = "freezetrap",
	[49011] = "freezetrap",
	[49012] = "freezetrap",
		
	--[[ MISC ]]--
	-- Scatter Shot
	[19503] = "scatters",
	
	-- Improved Conc Shot
	[19410] = "impconc",
	[22915] = "impconc",
	[28445] = "impconc",
	
	-- Death Coil
	[6789] = "dc",
	[17925] = "dc",
	[17926] = "dc",
	[27223] = "dc",
	[47859] = "dc",
	[47860] = "dc",
	
	-- Psychic Horror
	[64044] = "dc",
	
	-- Mind Control
	[605] = "charm",
	[10911] = "charm",
	[10912] = "charm",

	-- Cheap Shot
	[1833] = "cheapshot",

	-- Pounce
	[9005] = "cheapshot",
	[9823] = "cheapshot",
	[9827] = "cheapshot",
	[27006] = "cheapshot",
	[49803] = "cheapshot",
}

-- DR Category names
Data.typeNames = {
	["disarm"] = "Disarm",
	["disorient"] = "Disorients",
	["fear"] = "Fears",
	["ctrlstun"] = "Controlled Stuns",
	["rndstun"] = "Random Stuns",
	["cyclone"] = "Cyclone",
	["cheapshot"] = "Cheap Shot",
	["chastise"] = "Chastise",
	["scatters"] = "Scatter Shot",
	["freezetrap"] = "Freeze Trap",
	["rndroot"]  = "Random Roots",
	["dc"] = "Death Coil",
	["sleep"] = "Sleep",
	["root"] = "Controlled Roots",
	["impconc"] = "Imp Concussive Shot",
	["charm"] = "Charms",
	["silence"] = "Silences",
	["taunt"] = "Taunts",
}

-- Categories that have DR in PvE as well as PvP
Data.pveDRs = {
	["ctrlstun"] = true,
	["rndstun"] = true,
	["taunt"] = true,
	["cyclone"] = true,
}

-- List of DRs
Data.categories = {}
for _, cat in pairs(Data.spells) do
	Data.categories[cat] = true
end

-- Public APIs
-- Category name in something usable
function Data:GetCategoryName(cat)
	return cat and Data.typeNames[cat] or nil
end

-- Spell list
function Data:GetSpells()
	return Data.spells
end

-- Seconds before DR resets
function Data:GetResetTime()
	return Data.RESET_TIME
end

-- Get the category of the spellID
function Data:GetSpellCategory(spellID)
	return spellID and Data.spells[spellID] or nil
end

-- Does this category DR in PvE?
function Data:IsPVE(cat)
	return cat and Data.pveDRs[cat] or nil
end

-- List of categories
function Data:GetCategories()
	return Data.categories
end

-- Next DR, if it's 1.0, next is 0.50, if it's 0.50 next is 0.25 and such
function Data:NextDR(diminished)
	if( diminished == 1.0 ) then
		return 0.50
	elseif( diminished == 0.50 ) then
		return 0.25
	end
	
	return 0
end

--[[ EXAMPLES ]]--
--[[
	This is how you would track DR easily, you're welcome to do whatever you want with the below 4 functions.

	Does not include tracking for PvE, you'd need to hack that in yourself but it's not (too) hard.
]]

--[[
local trackedPlayers = {}
local function debuffGained(spellID, destName, destGUID, isEnemy)
	if( not trackedPlayers[destGUID] ) then
		trackedPlayers[destGUID] = {}
	end

	-- See if we should reset it back to undiminished
	local drCat = DRData:GetSpellCae
	local tracked = trackedPlayers[destGUID][drCat]
	if( tracked and tracked.reset <= GetTime() ) then
		tracked.diminished = 1.0
	end	
end

local function debuffFaded(spellID, destName, destGUID, isEnemy)
	local drCat = DRData:GetSpellCategory(spellID)
	if( not trackedPlayers[destGUID] ) then
		trackedPlayers[destGUID] = {}
	end

	if( not trackedPlayers[destGUID][drCat] ) then
		trackedPlayers[destGUID][drCat] = { reset = 0, diminished = 1.0 }
	end
	
	local time = GetTime()
	local tracked = trackedPlayers[destGUID][drCat]
	
	tracked.reset = time + DRData:GetResetTime()
	tracked.diminished = nextDR(tracked.diminished)
end

local function resetDR(destGUID)
	-- Reset the tracked DRs for this person
	if( trackedPlayers[destGUID] ) then
		for cat in pairs(trackedPlayers[destGUID]) do
			trackedPlayers[destGUID][cat].reset = 0
			trackedPlayers[destGUID][cat].diminished = 1.0
		end
	end
end

local COMBATLOG_OBJECT_TYPE_PLAYER = COMBATLOG_OBJECT_TYPE_PLAYER
local COMBATLOG_OBJECT_REACTION_HOSTILE = COMBATLOG_OBJECT_REACTION_HOSTILE
local COMBATLOG_OBJECT_CONTROL_PLAYER = COMBATLOG_OBJECT_CONTROL_PLAYER

local eventRegistered = {["SPELL_AURA_APPLIED"] = true, ["SPELL_AURA_REMOVED"] = true, ["PARTY_KILL"] = true, ["UNIT_DIED"] = true}
local function COMBAT_LOG_EVENT_UNFILTERED(self, event, timestamp, eventType, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellID, spellName, spellSchool, auraType)
	if( not eventRegistered[eventType] or ( bit.band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) ~= COMBATLOG_OBJECT_TYPE_PLAYER and bit.band(destFlags, COMBATLOG_OBJECT_CONTROL_PLAYER) ~= COMBATLOG_OBJECT_CONTROL_PLAYER ) ) then
		return
	end
	
	-- Enemy gained a debuff
	if( eventType == "SPELL_AURA_APPLIED" ) then
		if( auraType == "DEBUFF" and Data.Spells[spellID] ) then
			debuffGained(spellID, destName, destGUID, (bit.band(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE))
		end
	
	-- Buff or debuff faded from an enemy
	elseif( eventType == "SPELL_AURA_REMOVED" ) then
		if( auraType == "DEBUFF" and Data.Spells[spellID] ) then
			debuffFaded(spellID, destName, destGUID, (bit.band(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE))
		end
		
	-- Don't use UNIT_DIED inside arenas due to accuracy issues, outside of arenas we don't care too much
	elseif( ( eventType == "UNIT_DIED" and select(2, IsInInstance()) ~= "arena" ) or eventType == "PARTY_KILL" ) then
		resetDR(destGUID)
	end
end
]]