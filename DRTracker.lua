DRTracker = LibStub("AceAddon-3.0"):NewAddon("DRTracker", "AceEvent-3.0")

local L = DRTrackerLocals

local SML, instanceType, DRLib, GTBLib, GTBGroup, playerGUID

local barID = {}

function DRTracker:OnInitialize()
	self.defaults = {
		profile = {
			scale = 1.0,
			width = 180,
			redirectTo = "",
			texture = "BantoBar",
			showAnchor = false,
			showName = true,
			growUp = false,
			
			disabled = {EnemyDRChanged = {}, FriendlyDRChanged = {}},
			
			showType = {enemy = true, friendly = false},
			inside = {["pvp"] = true, ["arena"] = true},
		},
	}

	self.db = LibStub:GetLibrary("AceDB-3.0"):New("DRTrackerDB", self.defaults)

	self.revision = tonumber(string.match("$Revision: 678 $", "(%d+)") or 1)

	self.icons = {
		["rndstun"] = "Interface\\Icons\\INV_Mace_02",
		["ctrlstun"] = "Interface\\Icons\\Spell_Frost_FrozenCore",
		["fear"] = "Interface\\Icons\\Spell_Shadow_Possession",
		["disorient"] = "Interface\\Icons\\Ability_Gouge",
		["root"] = "Interface\\Icons\\Spell_Frost_FrostNova",
	}
	
	-- Remove the old fields
	if( self.db.profile.disableSpells ) then
		self.db.proifle.showSpells = nil
		self.db.profile.disableSpells = nil
	end
	
	-- Switch format around
	if( self.db.profile.disableCategories ) then
		local data = {}
		data.EnemyDRChanged = CopyTable(self.db.profile.disableCategories)
		data.FriendlyDRChanged = CopyTable(self.db.profile.disableCategories)
		
		self.db.profile.disableCategories = nil
		self.db.profile.disabled = data
	end

	-- Media
	SML = LibStub:GetLibrary("LibSharedMedia-3.0")
	SML.RegisterCallback(self, "LibSharedMedia_Registered", "TextureRegistered")
	
	-- Timer bars
	GTBLib = LibStub:GetLibrary("GTB-1.0")
	GTBGroup = GTBLib:RegisterGroup("DRTracker", SML:Fetch(SML.MediaType.STATUSBAR, self.db.profile.texture))
	GTBGroup:RegisterOnMove(self, "OnBarMove")
	GTBGroup:SetScale(self.db.profile.scale)
	GTBGroup:SetWidth(self.db.profile.width)
	GTBGroup:SetDisplayGroup(self.db.profile.redirectTo ~= "" and self.db.profile.redirectTo or nil)
	GTBGroup:SetAnchorVisible(self.db.profile.showAnchor)
	GTBGroup:SetBarGrowth(self.db.profile.growUp and "UP" or "DOWN")

	if( self.db.profile.position ) then
		GTBGroup:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", self.db.profile.position.x, self.db.profile.position.y)
	end
	
	self.GTB = GTBLib
	self.GTBGroup = GTBGroup
	
	-- GUID!
	playerGUID = UnitGUID("player")
	
	-- DR Tracking lib
	DRData = LibStub("DRData-1.0")
	
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
end

function DRTracker:OnDisable()
	GTBGroup:UnregisterAllBars()
end

function DRTracker:DRChanged(event, spellID, resetIn, drCategory, diminished, name, guid)
	-- Don't show this category of DR
	if( self.db.profile.disabled[event][drCategory] ) then
		return
	end
	
	-- Not tracking enemy, or friendly
	if( ( not self.db.profile.showType.enemy and event == "EnemyDRChanged" ) or ( not self.db.profile.showType.friendly and not self.db.profile.showType.self and event == "FriendlyDRChanged" ) ) then
		return
	end
	
	-- Hide DRs if it's a friendly DR, we don't have friendly on and only self, oh and it's not the player
	if( event == "FriendlyDRChanged" and self.db.profile.showType.self and not self.db.profile.showType.friendly and guid ~= playerGUID ) then
		return
	end
	
	local id = drCategory .. guid .. "dr"
	barID[id] = guid

	local spellName, _, spellIcon = GetSpellInfo(spellID)
	local text
	if( self.db.profile.showName ) then
		text = string.format("[%d%%] %s", diminished * 100, self:StripServer(name))
	else
		text = string.format("[%d%%] %s - %s", diminished * 100, DRData:GetCategoryName(drCategory) or drCategory, self:StripServer(name))
	end

	GTBGroup:RegisterBar(id, text, resetIn, nil, self.icons[drCategory] or spellIcon)
end

-- Player died, remove all of their DRs
function DRTracker:PlayerDied(destGUID)
	for id, guid in pairs(barID) do
		if( guid == destGUID ) then
			GTBGroup:UnregisterBar(id)
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

function DRTracker:Reload()
	self:OnDisable()
	self:OnEnable()

	GTBGroup:SetScale(self.db.profile.scale)
	GTBGroup:SetWidth(self.db.profile.width)
	GTBGroup:SetDisplayGroup(self.db.profile.redirectTo ~= "" and self.db.profile.redirectTo or nil)
	GTBGroup:SetAnchorVisible(self.db.profile.showAnchor)
	GTBGroup:SetBarGrowth(self.db.profile.growUp and "UP" or "DOWN")
end

function DRTracker:OnBarMove(parent, x, y)
	if( not DRTracker.db.profile.position ) then
		DRTracker.db.profile.position = {}
	end

	DRTracker.db.profile.position.x = x
	DRTracker.db.profile.position.y = y
end

function DRTracker:TextureRegistered(event, mediaType, key)
	if( mediaType == SML.MediaType.STATUSBAR and DRTracker.db.profile.texture == key ) then
		GTBGroup:SetTexture(SML:Fetch(SML.MediaType.STATUSBAR, self.db.profile.texture))
	end
end


-- DR TRACKING
local trackedPlayers = {}
local function debuffGained(spellID, destName, destGUID, isEnemy)
	if( not destName ) then return end
	
	if( not trackedPlayers[destGUID] ) then
		trackedPlayers[destGUID] = {}
	end

	-- See if we should reset it back to undiminished
	local drCat = DRData:GetSpellCategory(spellID)
	local tracked = trackedPlayers[destGUID][drCat]
	if( tracked and tracked.reset <= GetTime() ) then
		tracked.diminished = 1.0
	end
end

local function debuffFaded(spellID, destName, destGUID, isEnemy)
	if( not destName ) then return end
	
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
	tracked.diminished = DRData:NextDR(tracked.diminished)
	
	DRTracker:DRChanged((isEnemy and "EnemyDRChanged" or "FriendlyDRChanged"), spellID, DRData:GetResetTime(), drCat, tracked.diminished, destName, destGUID)
end

local function resetDR(destGUID)
	-- Reset the tracked DRs for this person
	if( trackedPlayers[destGUID] ) then
		for cat in pairs(trackedPlayers[destGUID]) do
			trackedPlayers[destGUID][cat].reset = 0
			trackedPlayers[destGUID][cat].diminished = 1.0
		end
	end
	
	DRTracker:PlayerDied(destGUID)
end

local COMBATLOG_OBJECT_TYPE_PLAYER = COMBATLOG_OBJECT_TYPE_PLAYER
local COMBATLOG_OBJECT_REACTION_HOSTILE = COMBATLOG_OBJECT_REACTION_HOSTILE
local COMBATLOG_OBJECT_CONTROL_PLAYER = COMBATLOG_OBJECT_CONTROL_PLAYER

local eventRegistered = {["SPELL_AURA_APPLIED"] = true, ["SPELL_AURA_REMOVED"] = true, ["PARTY_KILL"] = true, ["UNIT_DIED"] = true}
function DRTracker:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, eventType, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellID, spellName, spellSchool, auraType)
	if( not eventRegistered[eventType] or ( bit.band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) ~= COMBATLOG_OBJECT_TYPE_PLAYER and bit.band(destFlags, COMBATLOG_OBJECT_CONTROL_PLAYER) ~= COMBATLOG_OBJECT_CONTROL_PLAYER ) ) then
		return
	end
	
	-- Enemy gained a debuff
	if( eventType == "SPELL_AURA_APPLIED" ) then
		if( auraType == "DEBUFF" and DRData:GetSpellCategory(spellID) ) then
			debuffGained(spellID, destName, destGUID, (bit.band(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE))
		end
	
	-- Buff or debuff faded from an enemy
	elseif( eventType == "SPELL_AURA_REMOVED" ) then
		if( auraType == "DEBUFF" and DRData:GetSpellCategory(spellID) ) then
			debuffFaded(spellID, destName, destGUID, (bit.band(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE))
		end
		
	-- Don't use UNIT_DIED inside arenas due to accuracy issues, outside of arenas we don't care too much
	elseif( ( eventType == "UNIT_DIED" and select(2, IsInInstance()) ~= "arena" ) or eventType == "PARTY_KILL" ) then
		resetDR(destGUID)
	end
end