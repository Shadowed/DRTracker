DRTracker = LibStub("AceAddon-3.0"):NewAddon("DRTracker", "AceEvent-3.0")

local L = DRTrackerLocals

local SML
local instanceType

local expirationTime = {}
local currentDRList = {}
local spellMap = {}
local runningSpells = {}

function DRTracker:OnInitialize()
	self.defaults = {
		profile = {
			scale = 1.0,
			width = 180,
			redirectTo = "",
			texture = "BantoBar",
			showAnchor = false,
			
			disableSpells = {},
			
			inside = {["pvp"] = true, ["arena"] = true}
		},
	}

	self.db = LibStub:GetLibrary("AceDB-3.0"):New("DRTrackerDB", self.defaults)

	self.revision = tonumber(string.match("$Revision: 678 $", "(%d+)") or 1)
	self.spells = DRTrackerSpells
	self.icons = DRTrackerIcons
	self.spellAbbrevs = DRTrackerAbbrevs

	self:CreateAnchor()

	SML = LibStub:GetLibrary("LibSharedMedia-3.0")
	GTBLib = LibStub:GetLibrary("GTB-Beta1")
	
	GTBGroup = GTBLib:RegisterGroup("DRTracker", SML:Fetch(SML.MediaType.STATUSBAR, self.db.profile.texture))
	GTBGroup:SetScale(self.db.profile.scale)
	GTBGroup:SetWidth(self.db.profile.width)
	GTBGroup:SetDisplayGroup(self.db.profile.redirectTo ~= "" and self.db.profile.redirectTo or nil)
	GTBGroup:SetPoint("TOPLEFT", self.anchor, "BOTTOMLEFT", 0, 0)
	
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
	self:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
	self:RegisterEvent("PLAYER_FOCUS_CHANGED")
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:RegisterEvent("UNIT_AURA")
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
			self:TimerFound(name, rank, destName, destGUID, texture, timeLeft)
		end
	end
end

-- Combat log data
local COMBATLOG_OBJECT_REACTION_HOSTILE = COMBATLOG_OBJECT_REACTION_HOSTILE
local COMBATLOG_OBJECT_AFFILIATION_MINE = COMBATLOG_OBJECT_AFFILIATION_MINE
local eventRegistered = {["SPELL_CAST_SUCCESS"] = true, ["SPELL_AURA_APPLIED"] = true, ["SPELL_AURA_REMOVED"] = true, ["PARTY_KILL"] = true, ["UNIT_DIED"] = true}
function DRTracker:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, eventType, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, ...)
	if( not eventRegistered[eventType] ) then
		return
	end
		
	-- Enemy gained a debuff
	if( eventType == "SPELL_AURA_APPLIED" and bit.band(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE ) then
		local spellID, spellName, spellSchool, auraType = ...
		if( auraType == "DEBUFF" and self.spells[spellID] ) then
			spellMap[spellName .. (select(2, GetSpellInfo(spellID)))] = spellID
			self:AuraGained(spellID, spellName, destName, destGUID)
		end
	
	-- Buff or debuff faded from an enemy
	elseif( eventType == "SPELL_AURA_REMOVED" and bit.band(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE ) then
		local spellID, spellName, spellSchool, auraType = ...
		if( auraType == "DEBUFF" and self.spells[spellID] ) then
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


function DRTracker:TimerFound(spellName, spellRank, destName, destGUID, icon, timeLeft)
	local spellID = spellMap[spellName .. spellRank]
	if( spellID and not self.db.profile.disableSpells[spellName] ) then
		local id = spellID .. ":" .. destGUID
		
		-- This is a quick hack, need to add a startSeconds or a TimerExists API to GTB
		if( runningSpells[id] ) then return end
		runningSpells[id] = true
		
		GTBGroup:SetTexture(SML:Fetch(SML.MediaType.STATUSBAR, self.db.profile.texture))
		GTBGroup:UnregisterBar(id)
		GTBGroup:RegisterBar(id, timeLeft, string.format("%s - %s", self.spellAbbrevs[spellName] or spellName, destName), icon)
	end
end

function DRTracker:AuraGained(spellID, spellName, destName, destGUID)
	-- Figure out when the last spell was used
	local id = self.spells[spellID] .. ":" .. destGUID
	local time = GetTime()
	local diminished = 100
	
	-- Already had this spell used on them within 15 seconds
	if( expirationTime[id] and expirationTime[id] >= time ) then
		diminished = self:GetNextDR(currentDRList[id])
		currentDRList[id] = diminished
		
		if( not self.db.profile.disableSpells[spellName] ) then
			local icon = self.icons[self.spells[spellID]] or (select(3, GetSpellInfo(spellID)))
			GTBGroup:RegisterBar(id .. ":dr", 15, string.format("[DR %d%%] %s - %s", self:GetNextDR(diminished), L[self.spells[spellID]] or self.spells[spellID], destName), icon)
		end
		
	-- Nothing started yet or it's been over 15 seconds, so start us off at 100%
	elseif( not expirationTime[id] or expirationTime[id] <= time ) then
		currentDRList[id] = diminished
		
		-- Set it here in case a spell of the same DR category is used before this one fades
		expirationTime[id] = GetTime() + 15
	end
end

function DRTracker:AuraFaded(spellID, spellName, destName, destGUID)
	local id = self.spells[spellID] .. ":" .. destGUID
	if( currentDRList[id] and not self.db.profile.disableSpells[spellName] ) then
		local icon = self.icons[self.spells[spellID]] or (select(3, GetSpellInfo(spellID)))
		GTBGroup:RegisterBar(id .. ":dr", 15, string.format("[DR %d%%] %s - %s", self:GetNextDR(currentDRList[id]), L[self.spells[spellID]] or self.spells[spellID], destName), icon)
	end

	runningSpells[spellID .. ":" .. destGUID] = nil
	expirationTime[id] = GetTime() + 15
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

function DRTracker:GetNextDR(dr)
	if( dr == 100 ) then
		return 50
	elseif( dr == 50 ) then
		return 25
	end
	
	return 0
end

local function showTooltip(self)
	GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
	GameTooltip:SetText(L["ALT + Drag to move the frame anchor."], nil, nil, nil, nil, 1)
end

local function hideTooltip(self)
	GameTooltip:Hide()
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
	self.anchor:SetScript("OnEnter", showTooltip)
	self.anchor:SetScript("OnLeave", hideTooltip)
	self.anchor:SetScript("OnMouseDown", function(self)
		if( DRTracker.db.profile.showAnchor and IsAltKeyDown() ) then
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
		
			if( not DRTracker.db.profile.position ) then
				DRTracker.db.profile.position = {}
			end
			
			DRTracker.db.profile.position.x = x
			DRTracker.db.profile.position.y = y
			
			GTBGroup:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
		end
	end)	
	
	self.anchor.text = self.anchor:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	self.anchor.text:SetText(L["DRTracker"])
	self.anchor.text:SetPoint("CENTER", self.anchor, "CENTER")
	
	if( self.db.profile.position ) then
		local scale = self.anchor:GetEffectiveScale()
		self.anchor:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", self.db.profile.position.x * scale, self.db.profile.position.y * scale)
	else
		self.anchor:SetPoint("CENTER", UIParent, "CENTER")
	end
	
	-- Hide anchor if locked
	if( not self.db.profile.showAnchor ) then
		self.anchor:SetAlpha(0)
		self.anchor:EnableMouse(false)
	end
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
	
	self.anchor:SetWidth(self.db.profile.width)
	self.anchor:SetScale(self.db.profile.scale)
	
	if( not self.db.profile.showAnchor ) then
		self.anchor:SetAlpha(0)
		self.anchor:EnableMouse(false)
	else
		self.anchor:SetAlpha(1)
		self.anchor:EnableMouse(true)
	end
	
	-- Reset map in case we disabled a spell
	for k in pairs(spellMap) do spellMap[k] = nil end
end
