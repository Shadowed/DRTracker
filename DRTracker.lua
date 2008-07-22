DRTracker = LibStub("AceAddon-3.0"):NewAddon("DRTracker", "AceEvent-3.0")

local L = DRTrackerLocals

local SML, instanceType, DRLib, GTBLib, GTBGroup

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
			
			disableCategories = {},
			
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
	
	-- DR Tracking lib
	DRLib = LibStub("DiminishingReturns-1.0")
	
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
	
	if( self.db.profile.showType.enemy ) then
		DRLib.RegisterCallback(self, "EnemyDRChanged", "DRChanged")
	end
	
	if( self.db.profile.showType.friendly ) then
		DRLib.RegisterCallback(self, "FriendlyDRChanged", "DRChanged")
	end
	
	DRLib.RegisterCallback(self, "PlayerDied", "PlayerDied")
end

function DRTracker:OnDisable()
	DRLib.UnregisterAllCallbacks(self)
	GTBGroup:UnregisterAllBars()
end

function DRTracker:DRChanged(event, spellID, resetIn, drCategory, diminished, name, guid)
	-- Don't show this category of DR
	if( self.db.profile.disableCategories[drCategory] ) then
		return
	end
	
	local id = drCategory .. guid .. "dr"
	barID[id] = guid

	local spellName, _, spellIcon = GetSpellInfo(spellID)
	local text
	if( self.db.profile.showName ) then
		text = string.format("[%d%%] %s", diminished * 100, self:StripServer(name))
	else
		text = string.format("[%d%%] %s - %s", diminished * 100, DRLib:GetCategoryName(drCategory) or drCategory, self:StripServer(name))
	end

	GTBGroup:RegisterBar(id, text, resetIn, nil, self.icons[drCategory] or spellIcon)
end

-- Player died, remove all of their DRs
function DRTracker:PlayerDied(event, destGUID)
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