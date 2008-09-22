if( not DRTracker ) then return end

local Config = DRTracker:NewModule("Config")
local L = DRTrackerLocals

local SML, registered, options, config, dialog

function Config:OnInitialize()
	config = LibStub("AceConfig-3.0")
	dialog = LibStub("AceConfigDialog-3.0")
	

	SML = LibStub:GetLibrary("LibSharedMedia-3.0")
	SML:Register(SML.MediaType.STATUSBAR, "BantoBar", "Interface\\Addons\\DRTracker\\images\\banto")
	SML:Register(SML.MediaType.STATUSBAR, "Smooth",   "Interface\\Addons\\DRTracker\\images\\smooth")
	SML:Register(SML.MediaType.STATUSBAR, "Perl",     "Interface\\Addons\\DRTracker\\images\\perl")
	SML:Register(SML.MediaType.STATUSBAR, "Glaze",    "Interface\\Addons\\DRTracker\\images\\glaze")
	SML:Register(SML.MediaType.STATUSBAR, "Charcoal", "Interface\\Addons\\DRTracker\\images\\Charcoal")
	SML:Register(SML.MediaType.STATUSBAR, "Otravi",   "Interface\\Addons\\DRTracker\\images\\otravi")
	SML:Register(SML.MediaType.STATUSBAR, "Striped",  "Interface\\Addons\\DRTracker\\images\\striped")
	SML:Register(SML.MediaType.STATUSBAR, "LiteStep", "Interface\\Addons\\DRTracker\\images\\LiteStep")
end

-- GUI
local function set(info, value)
	local arg1, arg2, arg3 = string.split(".", info.arg)
	if( tonumber(arg2) ) then arg2 = tonumber(arg2) end
	
	if( arg2 and arg3 ) then
		DRTracker.db.profile[arg1][arg2][arg3] = value
	elseif( arg2 ) then
		DRTracker.db.profile[arg1][arg2] = value
	else
		DRTracker.db.profile[arg1] = value
	end
	
	DRTracker:Reload()
end

local function get(info)
	local arg1, arg2, arg3 = string.split(".", info.arg)
	if( tonumber(arg2) ) then arg2 = tonumber(arg2) end
	
	if( arg2 and arg3 ) then
		return DRTracker.db.profile[arg1][arg2][arg3]
	elseif( arg2 ) then
		return DRTracker.db.profile[arg1][arg2]
	else
		return DRTracker.db.profile[arg1]
	end
end

local function setNumber(info, value)
	set(info, tonumber(value))
end

local function setMulti(info, value, state)
	local arg1, arg2, arg3 = string.split(".", info.arg)
	if( tonumber(arg2) ) then arg2 = tonumber(arg2) end

	if( arg2 and arg3 ) then
		DRTracker.db.profile[arg1][arg2][arg3][value] = state
	elseif( arg2 ) then
		DRTracker.db.profile[arg1][arg2][value] = state
	else
		DRTracker.db.profile[arg1][value] = state
	end

	DRTracker:Reload()
end

local function getMulti(info, value)
	local arg1, arg2, arg3 = string.split(".", info.arg)
	if( tonumber(arg2) ) then arg2 = tonumber(arg2) end
	
	if( arg2 and arg3 ) then
		return DRTracker.db.profile[arg1][arg2][arg3][value]
	elseif( arg2 ) then
		return DRTracker.db.profile[arg1][arg2][value]
	else
		return DRTracker.db.profile[arg1][value]
	end
end


-- Return all registered SML textures
local textures = {}
function Config:GetTextures()
	for k in pairs(textures) do textures[k] = nil end

	for _, name in pairs(SML:List(SML.MediaType.STATUSBAR)) do
		textures[name] = name
	end
	
	return textures
end

-- Return all registered GTB groups
local groups = {}
function Config:GetGroups()
	for k in pairs(groups) do groups[k] = nil end

	groups[""] = L["None"]
	for name, data in pairs(DRTracker.GTB:GetGroups()) do
		groups[name] = name
	end
	
	return groups
end


-- DR filters
local spells = {}
local alreadyAdded = {}
local function sortSpells(a, b)
	return a < b
end

local function getTooltip(DRData, cat, name)
	for i=#(spells), 1, -1 do table.remove(spells, i) end
	for k in pairs(alreadyAdded) do alreadyAdded[k] = nil end
	
	for spellID, drCat in pairs(DRData:GetSpells()) do
		if( drCat == cat ) then
			local name = GetSpellInfo(spellID)
			if( not alreadyAdded[name] ) then
				alreadyAdded[name] = true
				table.insert(spells, name)
			end
		end
	end
	
	table.sort(spells, sortSpells)
	
	return string.format(L["Disable category %s.\n\nSpells in this category:\n%s"], name, table.concat(spells, "\n"))
end

local function createDRFilters(text, configKey)
	local config = {
		type = "group",
		order = 3,
		name = text,
		get = get,
		set = set,
		handler = Config,
		args = {
			desc = {
				order = 0,
				type = "description",
				name = L["Lets you choose which diminishing return categories should be disabled."],
			},
			list = {
				order = 1,
				type = "group",
				inline = true,
				name = L["List"],
				args = {},
			},
		},
	}

	-- Load spell list
	local DRData = LibStub("DRData-1.0")
	for cat in pairs(DRData:GetCategories()) do
		local name = DRData:GetCategoryName(cat)
		config.args.list.args[cat] = {
			order = 1,
			type = "toggle",
			name = name,
			desc = getTooltip(DRData, cat, name),
			arg = string.format("disabled.%s.%s", configKey, cat),
		}
	end
	
	return config
end

-- General options
local enabledIn = {["none"] = L["Everywhere else"], ["pvp"] = L["Battlegrounds"], ["arena"] = L["Arenas"], ["raid"] = L["Raid instances"], ["party"] = L["Party instances"]}

local function loadOptions()
	options = {}
	options.type = "group"
	options.name = "DRTracker"
	
	options.args = {}
	options.args.general = {
		type = "group",
		order = 1,
		name = L["General"],
		get = get,
		set = set,
		handler = Config,
		args = {
			enabled = {
				order = 0,
				type = "toggle",
				name = L["Show anchor"],
				desc = L["Display timer anchor for moving around."],
				width = "full",
				arg = "showAnchor",
			},
			showName = {
				order = 1,
				type = "toggle",
				name = L["Only show trigger name in bars"],
				width = "full",
				arg = "showName",
			},
			growUp = {
				order = 1,
				type = "toggle",
				name = L["Grow display up"],
				desc = L["Instead of adding everything from top to bottom, timers will be shown from bottom to top."],
				width = "full",
				arg = "growUp"
			},
			scale = {
				order = 3,
				type = "range",
				name = L["Display scale"],
				desc = L["How big the actual timers should be."],
				min = 0, max = 2, step = 0.1,
				set = setNumber,
				arg = "scale",
			},
			barWidth = {
				order = 4,
				type = "range",
				name = L["Bar width"],
				min = 0, max = 300, step = 1,
				set = setNumber,
				arg = "width",
			},
			barName = {
				order = 5,
				type = "select",
				name = L["Bar texture"],
				values = "GetTextures",
				dialogControl = 'LSM30_Statusbar',
				arg = "texture",
			},
			location = {
				order = 6,
				type = "select",
				name = L["Redirect bars to group"],
				desc = L["Group name to redirect bars to, this lets you show DRTracker timers under another addons bar group. Requires the bars to be created using GTB."],
				values = "GetGroups",
				arg = "redirectTo",
			},
			enabledIn = {
				order = 7,
				type = "multiselect",
				name = L["Enable DRTracker inside"],
				desc = L["Allows you to set what scenario's DRTracker should be enabled inside."],
				values = enabledIn,
				set = setMulti,
				get = getMulti,
				width = "full",
				arg = "inside"
			},
			showNPC = {
				order = 8,
				type = "toggle",
				name = L["Show NPC diminishing returns"],
				width = "full",
				arg = "showNPC",
			},
			showType = {
				order = 9,
				type = "multiselect",
				name = L["Show diminishing returns for"],
				desc = L["Allows you to set if diminishing returns should be shown for friendly players and/or enemy players. Use show self if you only want your DRs but not all friendly players."],
				values = {["enemy"] = L["Show enemies"], ["friendly"] = L["Show friendlies"], ["self"] = L["Show self"]},
				set = setMulti,
				get = getMulti,
				width = "full",
				arg = "showType"
			},
		},
	}
	
	options.args.enemy = createDRFilters(L["Enemy DR filter"], "EnemyDRChanged")
	options.args.friendly = createDRFilters(L["Friendly DR filter"], "FriendlyDRChanged")

	-- DB Profiles
	options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(DRTracker.db)
	options.args.profile.order = 2
end

-- Slash commands
SLASH_DRTRACKER1 = "/drtracker"
SLASH_DRTracker = "/drt"
SlashCmdList["DRTRACKER"] = function(msg)
	if( msg == "clear" ) then
		DRTracker.GTBGroup:UnregisterAllBars()
	elseif( msg == "test" ) then
		local GTBGroup = DRTracker.GTBGroup
		GTBGroup:UnregisterAllBars()
		GTBGroup:SetTexture(SML:Fetch(SML.MediaType.STATUSBAR, DRTracker.db.profile.texture))
		GTBGroup:RegisterBar("dr1", string.format("%s - %s", (select(1, GetSpellInfo(10890))), UnitName("player")), 10, nil, (select(3, GetSpellInfo(10890))))
		GTBGroup:RegisterBar("dr2", string.format("%s - %s", (select(1, GetSpellInfo(26989))), UnitName("player")), 15, nil, (select(3, GetSpellInfo(26989))))
		GTBGroup:RegisterBar("dr3", string.format("%s - %s", (select(1, GetSpellInfo(33786))), UnitName("player")), 20, nil, (select(3, GetSpellInfo(33786))))
	elseif( msg == "ui" ) then
		if( not registered ) then
			if( not options ) then
				loadOptions()
			end
			
			config:RegisterOptionsTable("DRTracker", options)
			dialog:SetDefaultSize("DRTracker", 625, 500)
			registered = true
		end

		dialog:Open("DRTracker")
	else
		DEFAULT_CHAT_FRAME:AddMessage(L["DRTracker slash commands"])
		DEFAULT_CHAT_FRAME:AddMessage(L["- clear - Clears all running timers."])
		DEFAULT_CHAT_FRAME:AddMessage(L["- test - Shows test timers in DRTracker."])
		DEFAULT_CHAT_FRAME:AddMessage(L["- ui - Opens the configuration for DRTracker."])
	end
end

-- Add the general options + profile, we don't add spells/anchors because it doesn't support sub cats
local register = CreateFrame("Frame", nil, InterfaceOptionsFrame)
register:SetScript("OnShow", function(self)
	self:SetScript("OnShow", nil)
	loadOptions()

	config:RegisterOptionsTable("DRTracker-Bliz", {
		name = "DRTracker",
		type = "group",
		args = {
			help = {
				type = "description",
				name = string.format("DRTracker r%d is a diminishing returns tracker for PvP", DRTracker.revision or 0),
			},
		},
	})
	
	dialog:SetDefaultSize("DRTracker-Bliz", 600, 400)
	dialog:AddToBlizOptions("DRTracker-Bliz", "DRTracker")
	
	config:RegisterOptionsTable("DRTracker-General", options.args.general)
	dialog:AddToBlizOptions("DRTracker-General", options.args.general.name, "DRTracker")

	config:RegisterOptionsTable("DRTracker-Profile", options.args.profile)
	dialog:AddToBlizOptions("DRTracker-Profile", options.args.profile.name, "DRTracker")
end)