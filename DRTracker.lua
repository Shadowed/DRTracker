DRTracker = LibStub("AceAddon-3.0"):NewAddon("DRTracker", "AceEvent-3.0")

local L = DRTrackerLocals

local SML
local instanceType

local expirationTime = {}
local currentDRList = {}
local auraDuration = {}
local spellCalibration = { [0] = {}, [0.25] = {}, [0.50] = {}, [1.0] = {} }

function DRTracker:OnInitialize()
	self.defaults = {
		profile = {
			scale = 1.0,
			width = 180,
			redirectTo = "Spellbreak",
			locked = true,
			
			inside = {["pvp"] = true, ["arena"] = true}
		},
	}

	self.db = LibStub:GetLibrary("AceDB-3.0"):New("DRTrackerDB", self.defaults)

	self.revision = tonumber(string.match("$Revision: 678 $", "(%d+)") or 1)
	self.spells = DRTrackerSpells
	self.spellAbbrevs = DRTrackerAbbrevs
	self.diminishID = DRTrackerDiminishID

	SML = LibStub:GetLibrary("LibSharedMedia-3.0")
	

	GTBLib = LibStub:GetLibrary("GTB-Beta1")
	GTBGroup = GTBLib:RegisterGroup("DRTracker", SML:Fetch(SML.MediaType.STATUSBAR, self.db.profile.texture))
	GTBGroup:SetScale(self.db.profile.scale)
	GTBGroup:SetWidth(self.db.profile.width)
	GTBGroup:SetDisplayGroup(self.db.profile.redirectTo ~= "" and self.db.profile.redirectTo or nil)
	GTBGroup:SetPoint("TOPLEFT", self.anchor, "BOTTOMLEFT", 0, 0)

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
end

local COMBATLOG_OBJECT_TYPE_PLAYER = COMBATLOG_OBJECT_TYPE_PLAYER
local COMBATLOG_OBJECT_REACTION_FRIENDLY = COMBATLOG_OBJECT_REACTION_FRIENDLY
local COMBATLOG_OBJECT_AFFILIATION_MINE = COMBATLOG_OBJECT_AFFILIATION_MINE
local COMBATLOG_OBJECT_AFFILIATION_PARTY = COMBATLOG_OBJECT_AFFILIATION_PARTY
local COMBATLOG_OBJECT_AFFILIATION_RAID = COMBATLOG_OBJECT_AFFILIATION_RAID
local COMBATLOG_OBJECT_REACTION_HOSTILE	= COMBATLOG_OBJECT_REACTION_HOSTILE
local CombatLog_Object_IsAll = CombatLog_Object_IsAll

local eventRegistered = {["SPELL_AURA_APPLIED"] = true, ["SPELL_AURA_REMOVED"] = true, ["PARTY_KILL"] = true, ["UNIT_DIED"] = true}
function DRTracker:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, eventType, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, ...)
	if( not eventRegistered[eventType] or not CombatLog_Object_IsAll(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) ) then
		return
	end
		
	-- Enemy gained a debuff
	if( eventType == "SPELL_AURA_APPLIED" ) then
		local spellID, spellName, spellSchool, auraType = ...
		if( auraType == "DEBUFF" ) then
			self:AuraGained(spellID, spellName, destName, destGUID)
		end
	
	-- Buff or debuff faded from an enemy
	elseif( eventType == "SPELL_AURA_REMOVED" ) then
		local spellID, spellName, spellSchool, auraType = ...
		if( auraType == "DEBUFF" ) then
			self:AuraFaded(spellID, spellName, destName, destGUID)
		end
	
	-- Don't use UNIT_DIED inside arenas due to accuracy issues, outside of arenas we don't care too much
	elseif( ( instanceType ~= "arena" and eventType == "UNIT_DIED" ) or eventType == "PARTY_KILL") then
		for id in pairs(currentDRList) do
			local spell, guid = string.split(":", id)
			if( guid == destGUID ) then
				GTBGroup:UnregisterBar(id)
			end
		end
	end

end

function DRTracker:AuraGained(spellID, spellName, destName, destGUID)
	if( not self.spells[spellID] ) then
		return
	end
	
	-- Figure out when the last spell was used
	local id = self.diminishID[spellID] .. ":" .. destGUID
	local time = GetTime()
	local diminished = 1.0
	
	-- Already had this spell used on them within 15 seconds
	if( expirationTime[id] and expirationTime[id] >= time ) then
		if( currentDRList[id] == 1 ) then
			diminished = 0.50
		elseif( currentDRList[id] == 0.50 ) then
			diminished = 0.25
		else
			diminished = 0
		end
		
		currentDRList[id] = diminished
		
		local nextDR = diminished
		if( nextDR == 0.50 ) then
			nextDR = 0.25
		elseif( nextDR == 0.25 ) then
			nextDR = 0
		end
		
		GTBGroup:RegisterBar(id .. ":dr", 15, string.format("[DR %d%%] %s - %s", nextDR * 100, self.spellAbbrevs[spellName] or spellName, destName), (select(3, GetSpellInfo(spellID))))
		
	-- Nothing started yet, so start us off at 100%
	elseif( not expirationTime[id] or expirationTime[id] <= time) then
		currentDRList[id] = diminished
	end
	
	-- Tries to do some basic spell calibration
	auraDuration[id] = GetTime()
	
	local seconds = self.spells[spellID] * diminished
	if( spellCalibration[diminished][spellID] ) then
		seconds = spellCalibration[diminished][spellID]

	end
	
	GTBGroup:SetTexture(SML:Fetch(SML.MediaType.STATUSBAR, self.db.profile.texture))
	GTBGroup:RegisterBar(id .. spellID, seconds, string.format("%s - %s", self.spellAbbrevs[spellName] or spellName, destName), (select(3, GetSpellInfo(spellID))))
end

function DRTracker:AuraFaded(spellID, spellName, destName, destGUID)
	if( not self.spells[spellID] ) then
		return
	end
	
	local id = self.diminishID[spellID] .. ":" .. destGUID
	expirationTime[id] = GetTime() + 15
		
	if( currentDRList[id] ) then
		local nextDR = currentDRList[id]
		if( nextDR == 1.0 ) then
			nextDR = 0.50
		elseif( nextDR == 0.50 ) then
			nextDR = 0.25
		else
			nextDR = 0
		end

		GTBGroup:RegisterBar(id .. ":dr", 15, string.format("[DR %d%%] %s - %s", nextDR * 100, self.spellAbbrevs[spellName] or spellName, destName), (select(3, GetSpellInfo(spellID))))
	end

	GTBGroup:UnregisterBar(id .. spellID)
	
	if( auraDuration[id] ) then
		local timeSpent = GetTime() - auraDuration[id]
		local offBy = (self.spells[spellID] * currentDRList[id]) - timeSpent

		
		if( offBy <= 0.60 and offBy > 0 ) then
			spellCalibration[currentDRList[id]][spellID] = timeSpent
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

function DRTracker:Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99DRTracker|r: " .. msg)
end

function DRTracker:CreateAnchor()
	local backdrop = {bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeSize = 0.6,
			insets = {left = 1, right = 1, top = 1, bottom = 1}}

	-- Create our anchor for moving the frame
	self.anchor = CreateFrame("Frame")
	self.anchor:SetWidth(self.db.profile.width)
	self.anchor:SetHeight(12)
	self.anchor:SetBackdrop(backdrop)
	self.anchor:SetBackdropColor(0, 0, 0, 1.0)
	self.anchor:SetBackdropBorderColor(0.75, 0.75, 0.75, 1.0)
	self.anchor:SetClampedToScreen(true)
	self.anchor:SetScale(self.db.profile.scale)
	self.anchor:EnableMouse(true)
	self.anchor:SetMovable(true)
	self.anchor:SetScript("OnMouseDown", function(self)
		if( not Spellbreak.db.profile.locked and IsAltKeyDown() ) then
			self.isMoving = true
			self:StartMoving()
		end
	end)

	self.anchor:SetScript("OnMouseUp", function(self)
		if( self.isMoving ) then
			self.isMoving = nil
			self:StopMovingOrSizing()
			
			local scale = self:GetEffectiveScale()
			local x = self:GetLeft() * scale
			local y = self:GetTop() * scale
		
			if( not Spellbreak.db.profile.position ) then
				Spellbreak.db.profile.position = {}
			end
			
			Spellbreak.db.profile.position.x = x
			Spellbreak.db.profile.position.y = y
			
			GTBGroup:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
		end
	end)	
	
	self.anchor.text = self.anchor:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	self.anchor.text:SetText(L["Spellbreak"])
	self.anchor.text:SetPoint("CENTER", self.anchor, "CENTER")
	
	if( self.db.profile.position ) then
		local scale = self.anchor:GetEffectiveScale()
		self.anchor:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", self.db.profile.position.x * scale, self.db.profile.position.y * scale)
	else
		self.anchor:SetPoint("CENTER", UIParent, "CENTER")
	end
	
	-- Hide anchor if locked
	if( self.db.profile.locked ) then
		self.anchor:SetAlpha(0)
		self.anchor:EnableMouse(false)
	end
end
