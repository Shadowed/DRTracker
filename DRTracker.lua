DRTracker = LibStub("AceAddon-3.0"):NewAddon("DRTracker", "AceEvent-3.0")

local L = DRTrackerLocals

local SML
local instanceType

local expirationTime = {}
local currentDRList = {}
local spellMap = {}

local DR_RESET_SECONDS = 20

function DRTracker:OnInitialize()
	self.defaults = {
		profile = {
			scale = 1.0,
			width = 180,
			redirectTo = "",
			texture = "BantoBar",
			showAnchor = false,
			showName = true,
			showSpells = true,
			
			disableSpells = {},
			
			inside = {["pvp"] = true, ["arena"] = true}
		},
	}

	self.db = LibStub:GetLibrary("AceDB-3.0"):New("DRTrackerDB", self.defaults)

	self.revision = tonumber(string.match("$Revision: 678 $", "(%d+)") or 1)
	self.spells = DRTrackerSpells
	self.icons = DRTrackerIcons
	self.spellAbbrevs = DRTrackerAbbrevs

	SML = LibStub:GetLibrary("LibSharedMedia-3.0")
	SML.RegisterCallback(self, "LibSharedMedia_Registered", "TextureRegistered")

	GTBLib = LibStub:GetLibrary("GTB-1.0")
	GTBGroup = GTBLib:RegisterGroup("DRTracker", SML:Fetch(SML.MediaType.STATUSBAR, self.db.profile.texture))
	GTBGroup:RegisterOnMove(self, "OnBarMove")
	GTBGroup:SetScale(self.db.profile.scale)
	GTBGroup:SetWidth(self.db.profile.width)
	GTBGroup:SetDisplayGroup(self.db.profile.redirectTo ~= "" and self.db.profile.redirectTo or nil)
	GTBGroup:SetAnchorVisible(self.db.profile.showAnchor)

	if( self.db.profile.position ) then
		GTBGroup:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", self.db.profile.position.x, self.db.profile.position.y)
	end
	
	self.GTB = GTBLib
	self.GTBGroup = GTBGroup

	-- Monitor for zone change
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA")

	-- Quick check
	self:ZONE_CHANGED_NEW_AREA()

end

function DRTracker:OnEnable()
	local type = select(2, IsInInstance())
	if( not self.db.profile.inside[type] ) then
		return
	end
	
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	

	if( self.db.profile.showSpells ) then
		self:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
		self:RegisterEvent("PLAYER_FOCUS_CHANGED")
		self:RegisterEvent("PLAYER_TARGET_CHANGED")
		self:RegisterEvent("UNIT_AURA")
	end
end

-- Combat log data
local COMBATLOG_OBJECT_REACTION_HOSTILE = COMBATLOG_OBJECT_REACTION_HOSTILE
local COMBATLOG_OBJECT_AFFILIATION_MINE = COMBATLOG_OBJECT_AFFILIATION_MINE
local eventRegistered = {["SPELL_CAST_SUCCESS"] = true, --[["SPELL_MISSED"] = true,]] ["SPELL_AURA_APPLIED"] = true, ["SPELL_AURA_REMOVED"] = true, ["PARTY_KILL"] = true, ["UNIT_DIED"] = true}
function DRTracker:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, eventType, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, ...)
	if( not eventRegistered[eventType] ) then
		return
	end
	
	--if( eventType == "SPELL_MISSED" ) then
	--	local id, name, school, type = ...
	--	if( name == "Cyclone" and type == "IMMUNE" ) then
	--		table.insert(TestLog, string.format("[%s] [%s] [%s] IMMUNE", GetTime(), name, destGUID))
	--	end
	--end
		
	-- Enemy gained a debuff
	if( eventType == "SPELL_AURA_APPLIED" and bit.band(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE ) then
		local spellID, spellName, spellSchool, auraType = ...
		if( auraType == "DEBUFF" and self.spells[spellID] ) then
			--if( spellName == "Cyclone" ) then
			--	table.insert(TestLog, string.format("[%s] [%s] [%s] GAIN", GetTime(), spellName, destGUID))
			--end

			spellMap[spellName .. (select(2, GetSpellInfo(spellID)))] = spellID
			self:AuraGained(spellID, spellName, destName, destGUID)
		end
	
	-- Buff or debuff faded from an enemy
	elseif( eventType == "SPELL_AURA_REMOVED" and bit.band(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE ) then
		local spellID, spellName, spellSchool, auraType = ...
		if( auraType == "DEBUFF" and self.spells[spellID] ) then
			--if( spellName == "Cyclone" ) then
			--	table.insert(TestLog, string.format("[%s] [%s] [%s] FADE", GetTime(), spellName, destGUID))
			--end
			self:AuraFaded(spellID, spellName, destName, destGUID)
		end
		
	-- Don't use UNIT_DIED inside arenas due to accuracy issues, outside of arenas we don't care too much
	elseif( ( ( instanceType ~= "arena" and eventType == "UNIT_DIED" ) or eventType == "PARTY_KILL" ) and bit.band(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE ) then
		for id in pairs(currentDRList) do
			local spell, guid = string.split(":", id)
			if( guid == destGUID ) then
				GTBGroup:UnregisterBar(id)
			end
		end
	end
end


function DRTracker:TimerFound(spellName, spellRank, destName, destGUID, icon, timeLeft, startSeconds)
	local spellID = spellMap[spellName .. spellRank]
	if( spellID and not self.db.profile.disableSpells[spellName] ) then
		GTBGroup:RegisterBar(spellID .. ":" .. destGUID, string.format("%s - %s", self.spellAbbrevs[spellName] or spellName, self:StripServer(destName)), timeLeft, startSeconds, icon)
	end
end

function DRTracker:AuraGained(spellID, spellName, destName, destGUID)
	-- Figure out when the last spell was used
	local id = self.spells[spellID] .. ":" .. destGUID
	local time = GetTime()
	local diminished = 100
	
	-- Already had this spell used on them within X seconds
	if( expirationTime[id] and expirationTime[id] >= time ) then
		diminished = self:GetNextDR(currentDRList[id])
		currentDRList[id] = diminished
		expirationTime[id] = GetTime() + DR_RESET_SECONDS

		if( not self.db.profile.disableSpells[spellName] ) then
			self:CreateDRTimer(id, destName, spellID)
		end
		
	-- Nothing started yet or it's been over X seconds, so start us off at 100%
	elseif( not expirationTime[id] or expirationTime[id] <= time ) then
		currentDRList[id] = diminished
		expirationTime[id] = GetTime() + DR_RESET_SECONDS
	end
end

function DRTracker:AuraFaded(spellID, spellName, destName, destGUID)
	local id = self.spells[spellID] .. ":" .. destGUID
	if( currentDRList[id] and not self.db.profile.disableSpells[spellName] ) then
		self:CreateDRTimer(id, destName, spellID)
	end

	expirationTime[id] = GetTime() + DR_RESET_SECONDS
end

function DRTracker:CreateDRTimer(id, name, spellID)
	local text
	if( self.db.profile.showName ) then
		text = string.format("[%d%%] %s", self:GetNextDR(currentDRList[id]), self:StripServer(name))
	else
		text = string.format("[%d%%] %s - %s", self:GetNextDR(currentDRList[id]), L[self.spells[spellID]] or self.spells[spellID], self:StripServer(name))
	end

	GTBGroup:RegisterBar(id .. ":dr", text, DR_RESET_SECONDS, nil, self.icons[self.spells[spellID]] or (select(3, GetSpellInfo(spellID))))
end

-- Timer scanning
function DRTracker:UNIT_AURA(event, unit)
	self:ScanUnit(unit)
end

function DRTracker:PLAYER_TARGET_CHANGED()
	self:ScanUnit("target")
end

function DRTracker:PLAYER_FOCUS_CHANGED()
	self:ScanUnit("focus")
end

function DRTracker:UPDATE_MOUSEOVER_UNIT()
	self:ScanUnit("mouseover")
end

function DRTracker:ScanUnit(unit)
	local destName = UnitName(unit)
	local destGUID = UnitGUID(unit)
	
	local id = 0
	while( true ) do
		id = id + 1
		local name, rank, texture, _, _, startSeconds, timeLeft = UnitDebuff(unit, id)
		if( not name ) then break end
		
		if( startSeconds and timeLeft ) then
			self:TimerFound(name, rank, destName, destGUID, texture, timeLeft, startSeconds)
		end
	end
end

-- See if we should enable Afflicted in this zone
function DRTracker:ZONE_CHANGED_NEW_AREA()
	local type = select(2, IsInInstance())

	if( type ~= instanceType ) then
		-- Check if it's supposed to be enabled in this zone
		if( self.db.profile.inside[type] ) then
			self:OnEnable()
		else
			self:OnDisable()
		end
	end
		
	instanceType = type
end

function DRTracker:StripServer(text)
	local name, server = string.match(text, "(.-)%-(.*)$")
	if( not name and not server ) then
		return text
	end
	
	return name
end

function DRTracker:Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99DRTracker|r: " .. msg)
end

function DRTracker:GetNextDR(dr)
	if( dr == 100 ) then
		return 50
	elseif( dr == 50 ) then
		return 25
	end
	
	return 0
end

function DRTracker:OnDisable()
	self:UnregisterAllEvents()
	
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA")
end

function DRTracker:Reload()
	self:OnDisable()

	-- Check to see if we should enable it
	local type = select(2, IsInInstance())
	if( self.db.profile.inside[type] ) then
		self:OnEnable()
	end

	GTBGroup:SetScale(self.db.profile.scale)
	GTBGroup:SetWidth(self.db.profile.width)
	GTBGroup:SetDisplayGroup(self.db.profile.redirectTo ~= "" and self.db.profile.redirectTo or nil)
	GTBGroup:SetAnchorVisible(self.db.profile.showAnchor)
	
	-- Reset map in case we disabled a spell
	for k in pairs(spellMap) do spellMap[k] = nil end
end

function DRTracker:OnBarMove(parent, x, y)
	DRTracker.db.profile.position.x = x
	DRTracker.db.profile.position.y = y
end

function DRTracker:TextureRegistered(event, mediaType, key)
	if( mediaType == SML.MediaType.STATUSBAR and DRTracker.db.profile.texture == key ) then
		GTBGroup:SetTexture(SML:Fetch(SML.MediaType.STATUSBAR, self.db.profile.texture))
	end
end