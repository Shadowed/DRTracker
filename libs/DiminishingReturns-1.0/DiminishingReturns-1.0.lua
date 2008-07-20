local major = "DiminishingReturns-1.0"
local minor = tonumber(string.match("$Revision: 703$", "(%d+)") or 1)

assert(LibStub, string.format("%s requires LibStub.", major))

local DR = LibStub:NewLibrary(major, minor)
if( not DR ) then return end

local CallbackHandler = LibStub:GetLibrary("CallbackHandler-1.0")
local Data = LibStub:GetLibrary("DRData-1.0")

DR.trackedPlayers = DR.trackedPlayers or {}

local DR_RESET_SECONDS = 18
local trackedPlayers = DR.trackedPlayers

-- Public APIs
function DR:GetCategoryName(cat)
	return cat and Data.TypeNames[cat] or nil
end

-- Track DR
local function nextDR(diminished)
	if( diminished == 1.0 ) then
		return 0.50
	elseif( diminished == 0.50 ) then
		return 0.25
	end
	
	return 0
end

local function debuffGained(spellID, destName, destGUID, isEnemy)
	if( not trackedPlayers[destGUID] ) then
		trackedPlayers[destGUID] = {}
	end

	-- See if we should reset it back to undiminished
	local drCat = Data.Spells[spellID]
	local tracked = trackedPlayers[destGUID][drCat]
	if( tracked and tracked.reset <= GetTime() ) then
		tracked.diminished = 1.0
	end	
end

local function debuffFaded(spellID, destName, destGUID, isEnemy)
	local drCat = Data.Spells[spellID]
	if( not trackedPlayers[destGUID] ) then
		trackedPlayers[destGUID] = {}
	end

	if( not trackedPlayers[destGUID][drCat] ) then
		trackedPlayers[destGUID][drCat] = { reset = 0, diminished = 1.0 }
	end
	
	local time = GetTime()
	local tracked = trackedPlayers[destGUID][drCat]
	
	tracked.reset = time + DR_RESET_SECONDS
	tracked.diminished = nextDR(tracked.diminished)
	
	DR.callback:Fire(isEnemy and "EnemyDRChanged" or "FriendlyDRChanged", spellID, DR_RESET_SECONDS, drCat, tracked.diminished, destName, destGUID)
end

local function resetDR(destGUID)
	-- Reset the tracked DRs for this person
	if( trackedPlayers[destGUID] ) then
		for cat in pairs(trackedPlayers[destGUID]) do
			trackedPlayers[destGUID][cat].reset = 0
			trackedPlayers[destGUID][cat].diminished = 1.0
		end
		
		DR.callback:Fire("PlayerDied", destGUID)
	end
end

-- Combat log data
local COMBATLOG_OBJECT_TYPE_PLAYER = COMBATLOG_OBJECT_TYPE_PLAYER
local COMBATLOG_OBJECT_REACTION_HOSTILE = COMBATLOG_OBJECT_REACTION_HOSTILE

local eventRegistered = {["SPELL_AURA_APPLIED"] = true, ["SPELL_AURA_REMOVED"] = true, ["PARTY_KILL"] = true, ["UNIT_DIED"] = true}
local function COMBAT_LOG_EVENT_UNFILTERED(self, event, timestamp, eventType, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellID, spellName, spellSchool, auraType)
	if( not eventRegistered[eventType] or bit.band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) ~= COMBATLOG_OBJECT_TYPE_PLAYER ) then
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

-- Load callbacks
if( not DR.callback ) then
	DR.callback = CallbackHandler:New(DR, "RegisterCallback", "UnregisterCallback", "UnregisterAllCallbacks")
end

-- Register for event
DR.frame = DR.frame or CreateFrame("Frame")
DR.frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
DR.frame:SetScript("OnEvent", COMBAT_LOG_EVENT_UNFILTERED)