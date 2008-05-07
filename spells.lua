DRTrackerSpells = { 
	-- Entangling Roots
	[339] = 10,
	[1062] = 10,
	[5195] = 10,
	[5196] = 10,
	[9852] = 10,
	[9853] = 10,
	[26989] = 10,
	
	-- Cyclone
	[33786] = 6,
}

-- This lets us link DRs together, for example Gouge and Sap
DRTrackerDiminishID = {
	-- Entangling Roots
	[339] = 26989,
	[1062] = 26989,
	[5195] = 26989,
	[5196] = 26989,
	[9852] = 26989,
	[9853] = 26989,
	[26989] = 26989,
	
	-- Cyclone
	[33786] = 33786,
}

local L = DRTrackerLocals
DRTrackerAbbrevs = {
	[L["Entangling Roots"]] = L["Ent Roots"],
}