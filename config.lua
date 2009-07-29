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
	if( info.arg ) then
		local cat, subCat, key = string.split(".", info.arg)
		DRTracker.db.profile[cat][subCat][key] = value
	else
		DRTracker.db.profile[info[(#info)]] = value
	end
	
	DRTracker:Reload()
end

local function get(info)
	if( info.arg ) then
		local cat, subCat, key = string.split(".", info.arg)
		return DRTracker.db.profile[cat][subCat][key]
	end

	return DRTracker.db.profile[info[(#info)]]
end

local function setNumber(info, value)
	set(info, tonumber(value))
end

local function setMulti(info, state, value)
	DRTracker.db.profile[info[(#info)]][state] = value
	DRTracker:Reload()
end

local function getMulti(info, state)
	return DRTracker.db.profile[info[(#info)]][state]
end

local function reverseSet(info, value)
	return set(info, not value)
end

local function reverseGet(info, value)
	return not get(info)
end

-- Return all fonts
local fonts = {}
function Config:GetFonts()
	for k in pairs(fonts) do fonts[k] = nil end

	for _, name in pairs(SML:List(SML.MediaType.FONT)) do
		fonts[name] = name
	end
	
	return fonts
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
			if( name and not alreadyAdded[name] ) then
				alreadyAdded[name] = true
				table.insert(spells, name)
			end
		end
	end
	
	table.sort(spells, sortSpells)
	
	return string.format(L["Enable category %s.\n\nSpells in this category:\n%s"], name, table.concat(spells, "\n"))
end

local function createDRFilters(text, configKey)
	local config = {
		type = "group",
		order = 3,
		name = text,
		get = reverseGet,
		set = reverseSet,
		handler = Config,
		args = {
			desc = {
				order = 0,
				type = "description",
				name = L["Lets you choose which diminishing return categories should be enabled."],
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
	for cat, name in pairs(DRData:GetCategories()) do
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
			general = {
				order = 1,
				type = "group",
				inline = true,
				name = L["General"],
				args = {
					showName = {
						order = 1,
						type = "toggle",
						name = L["Only show trigger name in bars"],
						width = "full",
					},
					showNPC = {
						order = 8,
						type = "toggle",
						name = L["Show NPC diminishing returns"],
						width = "full",
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
					},
					sep = {
						order = 11,
						name = "",
						type = "description",
					},
					inside = {
						order = 12,
						type = "multiselect",
						name = L["Enable DRTracker inside"],
						desc = L["Allows you to choose which scenarios this mod should be enabled in."],
						values = {["none"] = L["Everywhere else"], ["pvp"] = L["Battlegrounds"], ["arena"] = L["Arenas"], ["raid"] = L["Raid instances"], ["party"] = L["Party instances"]},
						set = setMulti,
						get = getMulti,
					},
				}
			},
			bar = {
				order = 2,
				type = "group",
				inline = true,
				name = L["Bar display"],
				args = {
					showAnchor = {
						order = 0,
						type = "toggle",
						name = L["Show anchor"],
						desc = L["Instead of adding everything from top to bottom, timers will be shown from bottom to top."],
					},
					growUp = {
						order = 1,
						type = "toggle",
						name = L["Grow display up"],
						desc = L["Instead of adding everything from top to bottom, timers will be shown from bottom to top."],
					},
					sep = {
						order = 3,
						name = "",
						type = "description",
					},
					redirectTo = {
						order = 8,
						type = "select",
						name = L["Redirect bars to group"],
						desc = L["Group name to redirect bars to, this lets you show the mods timers under another addons bar group. Requires the bars to be created using GTB."],
						values = "GetGroups",
						width = "full",
					},
					icon = {
						order = 5,
						type = "select",
						name = L["Icon position"],
						values = {["LEFT"] = L["Left"], ["RIGHT"] = L["Right"]},
					},
					texture = {
						order = 6,
						type = "select",
						name = L["Texture"],
						dialogControl = "LSM30_Statusbar",
						values = "GetTextures",
					},
					sep = {
						order = 8,
						name = "",
						type = "description",
					},
					fadeTime = {
						order = 9,
						type = "range",
						name = L["Fade time"],
						min = 0, max = 2, step = 0.1,
					},
					scale = {
						order = 11,
						type = "range",
						name = L["Display scale"],
						min = 0, max = 2, step = 0.01,
					},
					maxRows = {
						order = 12,
						type = "range",
						name = L["Max timers"],
						min = 1, max = 100, step = 1,
					},
					width = {
						order = 13,
						type = "range",
						name = L["Width"],
						min = 50, max = 300, step = 1,
						set = setNumber,
					},
				},
			},
			text = {
				order = 3,
				type = "group",
				inline = true,
				name = L["Text"],
				args = {
					fontSize = {
						order = 1,
						type = "range",
						name = L["Size"],
						min = 1, max = 20, step = 1,
						set = setNumber,
					},
					fontName = {
						order = 2,
						type = "select",
						name = L["Font"],
						dialogControl = "LSM30_Font",
						values = "GetFonts",
					},
				},
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
				name = "DRTracker is a diminishing returns tracker for PvP and PvE",
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