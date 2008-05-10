DRTrackerSpells = { 
	-- Entangling Roots
	[339] = true,
	[1062] = true,
	[5195] = true,
	[5196] = true,
	[9852] = true,
	[9853] = true,
	[26989] = true,
	
	-- Cyclone
	[33786] = true,
	
	-- Hibernate
	[2637] = true,
	[18657] = true,
	[18658] = true,
	
	-- Polymorph
	[118] = true,
	[12824] = true,
	[12825] = true,
	[28272] = true,
	[28271] = true,
	[12826] = true,
	
	-- Hammer of Justice
	[853] = true,
	[5588] = true,
	[5589] = true,
	[10308] = true,
	
	-- Psychic scream
	[8122] = true,
	[8124] = true,
	[10888] = true,
	[10890] = true,
	
	-- Sap
	[6770] = true,
	[2070] = true,
	[11297] = true,
	
	-- Gouge
	[1776] = true,
	[1777] = true,
	[8629] = true,
	[11285] = true,
	[11286] = true,
	[38764] = true,
	
	-- Blind
	[2094] = true,
	
	-- Cheap Shot
	[1833] = true,

	-- Kidney Shot
	[408] = true,
	[8643] = true,
	
	-- Fear (Warlock)
	[5782] = true,
	[6213] = true,
	[6215] = true,
	
	-- Seduction (Pet)
	[6358] = true,
	
	-- Howl of Terror
	[5484] = true,
	[17928] = true,
	
	-- Charge
	[7922] = true,
	
	-- Intercept
	[20253] = true,
	[20614] = true,
	[20615] = true,
	[25273] = true,
	[25274] = true,
	
	-- Improved Hamstring
	[23694] = true,
}

-- spellID's that share the same diminishing returns, like Sap and Gouge
DRTrackerDiminishID = {
	-- Entangling Roots
	[339] = 1,
	[1062] = 1,
	[5195] = 1,
	[5196] = 1,
	[9852] = 1,
	[9853] = 1,
	[26989] = 1,
	
	-- Cyclone
	[33786] = 2,

	-- Sap + Gouge
	[6770] = 2,
	[2070] = 2,
	[11297] = 2,
	[1776] = 2,
	[1777] = 2,
	[8629] = 2,
	[11285] = 2,
	[11286] = 2,
	[38764] = 2,

	-- Hibernate
	[2637] = 3,
	[18657] = 3,
	[18658] = 3,
	
	-- Polymorph
	[118] = 4,
	[12824] = 4,
	[12825] = 4,
	[28272] = 4,
	[28271] = 4,
	[12826] = 4,
	
	-- Hammer of Justice
	[853] = 5,
	[5588] = 5,
	[5589] = 5,
	[10308] = 5,
	
	-- Psychic scream
	[8122] = 6,
	[8124] = 6,
	[10888] = 6,
	[10890] = 6,
	
	-- Cheap Shot
	[1833] = 7,
	
	-- Kidney Shot
	[408] = 8,
	[8643] = 8,

	-- Fear + Seduction + Howl of Terror
	[5782] = 9,
	[6213] = 9,
	[6215] = 9,
	[6358] = 9,
	[5484] = 9,
	[17928] = 9,

	-- Charge + Intercept
	[7922] = 10,
	[20253] = 10,
	[20614] = 10,
	[20615] = 10,
	[25273] = 10,
	[25274] = 10,
	
	-- Improved Hamstring
	[23694] = 11,
	
	-- Blind
	[2094] = 12,
}

local L = DRTrackerLocals
DRTrackerAbbrevs = {
	[(GetSpellInfo(339))] = L["Ent Roots"],
	[(GetSpellInfo(853))] = L["Hammer of Just"],
	[(GetSpellInfo(8122))] = L["Psy Scream"],
}