DRTracker = LibStub("AceAddon-3.0"):NewAddon("DRTracker", "AceEvent-3.0")

local L = DRTrackerLocals

local instanceType

function DRTracker:OnInitialize()
	self.defaults = {
		profile = {
			scale = 1.0,
			width = 180
			redirectTo = "Spellbreak",
			locked = true,
			
			inside = {["pvp"] = true, ["arena"] = true}
		},
	}

	self.db = LibStub:GetLibrary("AceDB-3.0"):New("DRTrackerDB", self.defaults)

	self.SML = LibStub:GetLibrary("LibSharedMedia-3.0")
	self.revision = tonumber(string.match("$Revision: 678 $", "(%d+)") or 1)

	GTBLib = LibStub:GetLibrary("GTB-Beta1")
	GTBGroup = GTBLib:RegisterGroup("DRTracker", SML:Fetch(SML.MediaType.STATUSBAR, self.db.profile.texture))
	GTBGroup:RegisterOnFade(self, "OnBarFade")
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
local GROUP_AFFILIATION = bit.bor(COMBATLOG_OBJECT_AFFILIATION_PARTY, COMBATLOG_OBJECT_AFFILIATION_RAID, COMBATLOG_OBJECT_AFFILIATION_MINE)

local eventRegistered = {["SPELL_INTERRUPT"] = true, ["SPELL_CAST_SUCCESS"] = true, ["SPELL_AURA_APPLIED"] = true, ["SPELL_AURA_REMOVED"] = true, ["SPELL_SUMMON"] = true, ["SPELL_CREATE"] = true, ["SPELL_DISPEL_FAILED"] = true, ["SPELL_PERIODIC_DISPEL_FAILED"] = true, ["SPELL_AURA_DISPELLED"] = true, ["SPELL_AURA_STOLEN"] = true, ["PARTY_KILL"] = true, ["UNIT_DIED"] = true}
function DRTracker:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, eventType, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, ...)
	if( not eventRegistered[eventType] ) then
		return
	end
	
	local isDestEnemy = (bit.band(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE)
	local isSourceEnemy = (bit.band(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE)

	-- Enemy gained a debuff
	if( eventType == "SPELL_AURA_APPLIED" and isDestEnemy ) then
		local spellID, spellName, spellSchool, auraType = ...
		
	-- Buff or debuff faded from an enemy
	elseif( eventType == "SPELL_AURA_REMOVED" and isDestEnemy ) then
		local spellID, spellName, spellSchool, auraType = ...

	-- Spell casted succesfully
	elseif( eventType == "SPELL_CAST_SUCCESS" and isSourceEnemy ) then
		local spellID, spellName, spellSchool, auraType = ...
	
	-- Check if we should clear timers
	elseif( eventType == "PARTY_KILL" and isDestEnemy ) then

	-- Don't use UNIT_DIED inside arenas due to accuracy issues, outside of arenas we don't care too much
	elseif( instanceType ~= "arena" and eventType == "UNIT_DIED" and isDestEnemy ) then
	end

end

function DRTracker:TriggerTimer(spellID, spellName, sourceName, sourceGUID, destName, destGUID)
	--GTBGroup:SetTexture(SML:Fetch(SML.MediaType.STATUSBAR, self.db.profile.texture))
	--GTBGroup:RegisterBar(id, seconds, string.format("%s - %s", school.text, destName), school.icon)
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
