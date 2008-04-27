local major = "GTB-Beta1"
local minor = tonumber(string.match("$Revision: 675 $", "(%d+)") or 1)

assert(LibStub, string.format("%s requires LibStub.", major))

local GTB = LibStub:NewLibrary(major, minor)
if( not GTB ) then return end

local L = {
	["BAD_ARGUMENT"] = "bad argument #%d for '%s' (%s expected, got %s)",
	["MUST_CALL"] = "You must call '%s' from a registered GTB object.",
	["GROUP_EXISTS"] = "The group '%s' already exists.",
}

-- Validation for passed arguments
local function assert(level,condition,message)
	if( not condition ) then
		error(message,level)
	end
end

local function argcheck(value, num, ...)
	if( type(num) ~= "number" ) then
		error(L["BAD_ARGUMENT"]:format(2, "argcheck", "number", type(num)), 1)
	end

	for i=1,select("#", ...) do
		if( type(value) == select(i, ...) ) then return end
	end

	local types = string.join(", ", ...)
	local name = string.match(debugstack(2,2,0), ": in function [`<](.-)['>]")
	error(L["BAD_ARGUMENT"]:format(num, name, types, type(value)), 3)
end

-- GTB Library
GTB.framePool = GTB.framePool or {}
GTB.groups = GTB.groups or {}

local framePool = GTB.framePool
local groups = GTB.groups
local methods = {"SetBaseColor", "EnableGradient", "SetPoint", "SetScale", "SetWidth", "SetTexture", "SetBarGrowth", "SetIconPosition", "SetTextColor",
"SetTimerColor", "SetFadeTime", "RegisterOnFade", --[["SetTextOffset", "SetTimerOffset",]] "SetDisplayGroup", "GetDisplayGroup", "RegisterBar", "UnregisterBar", "SetRepeatingTimer", "UnregisterAllBars", "RegisterOnClick", "SetBarIcon"}

-- Internal functions for managing bars
local function getFrame()
	-- Check for an unused bar
	if( #(framePool) > 0 ) then
		return table.remove(framePool, 1)
	end
		
	-- Create the actual bar
	local frame = CreateFrame("StatusBar", nil, UIParent)
	frame:SetClampedToScreen(true)
	frame:SetMinMaxValues(0, 1)
	frame:SetValue(1)	
	
	frame.bg = CreateFrame("StatusBar", nil, frame)
	frame.bg:SetMinMaxValues(0, 1)
	frame.bg:SetValue(1)
	frame.bg:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
	frame.bg:SetFrameLevel(0)
	
	-- None available, create a new one
	frame.button = CreateFrame("Button", nil, frame)
    	frame.button:EnableMouse(false)
	frame.button:SetClampedToScreen(true)
	frame.button:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp", "Button4Up", "Button5Up")
	frame.button:Hide()

	-- Create icon
	frame.icon = frame:CreateTexture(nil, "ARTWORK")
	
	-- Sparky
	frame.spark = frame:CreateTexture(nil, "OVERLAY")
	frame.spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
	frame.spark:SetWidth(16)
	frame.spark:SetBlendMode("ADD")
	
	-- Timer text
	frame.timer = frame:CreateFontString(nil, "OVERLAY")
	frame.timer:SetFontObject(GameFontHighlight)
	frame.timer:SetJustifyH("RIGHT")
	
	-- Display Text
	frame.text = frame:CreateFontString(nil, "OVERLAY")
	frame.text:SetFontObject(GameFontHighlight)
	frame.text:SetJustifyH("LEFT")
	
	return frame
end

-- Release it to be reused later
local function releaseFrame(frame)
	-- Stop updates
	frame:SetScript("OnUpdate", nil)
	frame:EnableMouse(false)
	frame:Hide()

	-- Reset alpha so everythings visible again
	frame:SetAlpha(1.0)

	-- Clear out our OnClick info
	frame.clickHandler = nil
	frame.clickFunc = nil
	frame.args = nil
	frame.fadingOut = nil

	-- And now readd to the frame pool
	table.insert(framePool, frame)	
end

-- Fadeout OnUpdate
local function fadeOnUpdate(self, elapsed)
	local time = GetTime()
	self.fadeTime = self.fadeTime - (time - self.lastUpdate)
	self.lastUpdate = time

	-- Done fading, hide
	if( self.fadeTime <= 0 ) then
		groups[self.owner]:UnregisterBar(self.barID)
		return
	end
		
	self:SetAlpha(self.fadeTime / self.timeToFade)
end

-- Starts to fade out the actual bar
local function fadeoutBar(self)
	local group = groups[self.owner]
	
	if( type(group.onFadeHandler) == "table" and type(group.onFadeFunc) == "string" and group.onFadeHandler[group.onFadeFunc] ) then
		group.onFadeHandler[group.onFadeFunc](group.onFadeHandler, self.barID)			
	elseif( type(group.onFadeFunc) == "string" ) then
		local func = getglobal(group.onFadeFunc)
		if( func ) then
			func(self.barID)
		end
	elseif( type(group.onFadeFunc) == "function" and group.onFadeFunc ) then
		group.onFadeFunc(self.barID)
	end
	
	group.onFadeHandler = handler
	group.onFadeFunc = func
	
	-- Don't fade at all, remove right now
	if( group.fadeTime <= 0 ) then
		group:UnregisterBar(self.barID)	
		return
	end
	
	-- Start fading
	self.timeToFade = group.fadeTime
	self.fadeTime = group.fadeTime
	self:SetScript("OnUpdate", fadeOnUpdate)
end

-- OnUpdate for a bar
local function barOnUpdate(self)
	local time = GetTime()
	-- Check if times ran out and that we need to start fading it out
	self.secondsLeft = self.secondsLeft - (time - self.lastUpdate)
	self.lastUpdate = time
	if( self.secondsLeft <= 0 and not self.fadingOut ) then
		-- Check if it's a repeating timer
		local bar = groups[self.groupName].bars[self.barID]
		if( bar.repeating ) then
			self.secondsLeft = self.startSeconds
			self.lastUpdate = time
			return
		end
		
		
		self:SetValue(0)
		self.spark:Hide()
		self.fadingOut = true
		
		fadeoutBar(self)
		return
	end
	
	-- Timer text, need to see if this can be optimized a bit later
	local hour = floor(self.secondsLeft / 3600)
	local minutes = self.secondsLeft - (hour * 3600)
	minutes = floor(minutes / 60)
	
	local seconds = self.secondsLeft - ((hour * 3600) + (minutes * 60))
	
	if( hour > 0 ) then
		self.timer:SetFormattedText("%d:%02d", hour, minute)
	elseif( minutes > 0 ) then
		self.timer:SetFormattedText("%d:%02d", minutes, floor(seconds))
	elseif( seconds < 10 ) then
		self.timer:SetFormattedText("%.1f", seconds)
	else
		self.timer:SetFormattedText("%.0f", floor(seconds))
	end
	
	local percent = self.secondsLeft / self.startSeconds

	-- Color gradient towards red
	if( self.gradients ) then
		-- finalColor + (currentColor - finalColor) * percentLeft		
		self:SetStatusBarColor(1.0 + (self.r - 1.0) * percent, self.g * percent, self.b * percent)
	end
	
	-- Spark position
	self.spark:SetPoint("CENTER", self, "LEFT", self:GetWidth() * percent, 0)

	-- Now update the actual displayed bar
	self:SetValue(percent)
end

-- Reposition the group
local function sortBars(a, b)
	return a.endTime < b.endTime
end

local function repositionFrames(group)
	table.sort(group.usedBars, sortBars)

	for i, bar in pairs(group.usedBars) do
		bar:ClearAllPoints()
		
		if( i > 1 ) then
			if( group.barGrowth == "DOWN" ) then
				bar:SetPoint("TOPLEFT", group.usedBars[i - 1], "BOTTOMLEFT", 0, 0)
			else
				bar:SetPoint("BOTTOMLEFT", group.usedBars[i - 1], "TOPLEFT", 0, 0)
			end
		else
			bar:SetPoint(group.point, group.relativeFrame, group.relativePoint, group.xOff, group.yOff)
		end

	end
end

------------------------
-- GTB PUBLIC METHODS --
------------------------

-- Register a new group
function GTB:RegisterGroup(name, texture, ...)
	argcheck(name, 1, "string")
	argcheck(texture, 2, "string")
	assert(3, not groups[name], string.format(L["GROUP_EXISTS"], name))

	local obj = {name = name, frame = CreateFrame("Frame"), texture = texture, scale = 1.0, fontSize = 11, height = 16, obj = obj, bars = {}, usedBars = {}}
	
	-- Inject our methods
	for _, func in pairs(methods) do
		obj[func] = GTB[func]
	end

	-- Register
	groups[name] = obj

	-- Set defaults
	obj.frame:SetHeight(1)
	
	if( select("#", ...) > 0 ) then
		obj:SetPoint(...)
	else
		obj:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	end
	
	obj:SetScale(1.0)
	obj:SetWidth(200)
	obj:SetFadeTime(0.25)
	obj:EnableGradient(true)
	obj:SetBarGrowth("DOWN")
	obj:SetIconPosition("LEFT")
	obj:SetBaseColor(0.0, 1.0, 0.0)
	obj:SetTextColor(1.0, 1.0, 1.0)
	obj:SetTimerColor(1.0, 1.0, 1.0)
		
	return obj	
end

-- Retrieve a group after it's been registered
function GTB:GetGroup(name)
	argcheck(name, 1, "string")
	return groups[name] and groups[name].obj
end

-- Returns every registered group and it's config obj
function GTB:GetGroups()
	return groups
end

-----------------
-- BAR DISPLAY --
-----------------

-- Gradients from base color -> red depending on time left
function GTB.EnableGradient(group, flag)
	argcheck(flag, 2, "boolean")
	assert(3, group.name and groups[group.name], string.format(L["MUST_CALL"], "EnableGradient"))
	
	group.gradients = flag
end

-- Group frame positioning, and all the timers inside it
function GTB.SetPoint(group, point, relativeFrame, relativePoint, xOff, yOff)
	argcheck(point, 2, "string")
	argcheck(relativeFrame, 3, "table", "string", "nil")
	argcheck(relativePoint, 4, "string", "nil")
	argcheck(xOff, 5, "number", "nil")
	argcheck(yOff, 6, "number", "nil")
	assert(3, group.name and groups[group.name], string.format(L["MUST_CALL"], "SetPoint"))
		
	group.point = point
	group.relativeFrame = relativeFrame
	group.relativePoint = relativePoint
	group.xOff = xOff
	group.yOff = yOff
	
	group.frame:ClearAllPoints()
	group.frame:SetPoint(point, relativeFrame, relativePoint, xOff, yOff)
end

-- Bar scale
function GTB.SetScale(group, scale)
	argcheck(scale, 2, "number")
	assert(3, group.name and groups[group.name], string.format(L["MUST_CALL"], "SetScale"))
	
	group.scale = scale
	group.frame:SetScale(scale)
end

-- Width of all the bars
function GTB.SetWidth(group, width)
	argcheck(width, 2, "number")
	assert(3, group.name and groups[group.name], string.format(L["MUST_CALL"], "SetWidth"))
	
	group.width = width
	group.frame:SetWidth(width)
end

-- Bar texture
function GTB.SetTexture(group, texture)
	argcheck(texture, 2, "string")
	assert(3, group.name and groups[group.name], string.format(L["MUST_CALL"], "SetTexture"))
	
	group.texture = texture
end

-- Bar growth mode (UP/DOWN)
function GTB.SetBarGrowth(group, type)
	assert(3, type == "UP" or type == "DOWN", string.format(L["BAD_ARGUMENT"], 2, "SetBarGrowth", "UP, DOWN", tostring(type)))
	assert(3, group.name and groups[group.name], string.format(L["MUST_CALL"], "SetBarGrowth"))
	
	group.barGrowth = type
end

-- Icon positioning (LEFT/RIGHT)
function GTB.SetIconPosition(group, position)
	assert(3, position == "LEFT" or position == "RIGHT", string.format(L["BAD_ARGUMENT"], 2, "SetBarGrowth", "UP, DOWN", tostring(position)))
	assert(3, group.name and groups[group.name], string.format(L["MUST_CALL"], "SetBarGrowth"))
	
	group.iconPosition = position
end

-- Group object
function GTB.SetBaseColor(group, r, g, b)
	argcheck(r, 2, "number")
	argcheck(g, 3, "number")
	argcheck(b, 4, "number")
	assert(3, group.name and groups[group.name], string.format(L["MUST_CALL"], "SetBaseColor"))
	
	if( not group.baseColor ) then
		group.baseColor = {}
	end
	
	group.baseColor.r = r
	group.baseColor.g = g
	group.baseColor.b = b
end

-- Text color
function GTB.SetTextColor(group, r, g, b)
	argcheck(r, 2, "number")
	argcheck(g, 3, "number")
	argcheck(b, 4, "number")
	assert(3, group.name and groups[group.name], string.format(L["MUST_CALL"], "SetTextColor"))
	
	if( not group.textColor ) then
		group.textColor = {}
	end
	
	group.textColor.r = r
	group.textColor.g = g
	group.textColor.b = b	
end

-- Timer text color
function GTB.SetTimerColor(group, r, g, b)
	argcheck(r, 2, "number")
	argcheck(g, 3, "number")
	argcheck(b, 4, "number")
	assert(3, group.name and groups[group.name], string.format(L["MUST_CALL"], "SetTimerColor"))
	
	if( not group.timerColor ) then
		group.timerColor = {}
	end
	
	group.timerColor.r = r
	group.timerColor.g = g
	group.timerColor.b = b	
end

-- How many seconds we should take to fade out
function GTB.SetFadeTime(group, seconds)
	argcheck(seconds, 2, "number")
	assert(3, group.name and groups[group.name], string.format(L["MUST_CALL"], "SetFadeTime"))
	
	group.fadeTime = seconds
end

--[[
-- Offset text from the left edge of the timer text
function GTB.SetTextOffset(group, offset)
	argcheck(offset, 2, "number")
	assert(3, group.name and groups[group.name], string.format(L["MUST_CALL"], "SetTextOffset"))
	
	group.textOffset = offset
end

-- Offset timer text from the left edge of the bar
function GTB.SetTimerOffset(group, offset)
	argcheck(offset, 2, "number")
	assert(3, group.name and groups[group.name], string.format(L["MUST_CALL"], "SetTimerOffset"))
	
	group.timerOffset = offset
end
]]

-- Redirect everything to the specified group
function GTB.SetDisplayGroup(group, name)
	argcheck(name, 2, "string", "nil")
	assert(3, group.name and groups[group.name], string.format(L["MUST_CALL"], "SetDisplayGroup"))
	
	group.redirectTo = name
end

-- Gets the current display group
function GTB.GetDisplayGroup(group)
	assert(3, group.name and groups[group.name], string.format(L["MUST_CALL"], "SetDisplayGroup"))
	
	return group.redirectTo
end

-- Associate a function to call when bars fade
function GTB.RegisterOnFade(group, handler, func)
	argcheck(handler, 2, "table", "function", "string")
	argcheck(func, 2, "string", "nil")

	if( func ) then
		group.onFadeHandler = handler
		group.onFadeFunc = func
	else
		group.onFadeFunc = handler
	end	
end

--------------------
-- BAR MANAGEMENT --
--------------------

-- Register
function GTB.RegisterBar(group, id, seconds, text, icon, r, g, b)
	argcheck(id, 2, "string", "number")
	argcheck(seconds, 3, "number")
	argcheck(text, 4, "string")
	argcheck(icon, 5, "string", "nil")
	argcheck(r, 6, "number", "nil")
	argcheck(g, 7, "number", "nil")
	argcheck(b, 8, "number", "nil")
	assert(3, group.name and groups[group.name], string.format(L["MUST_CALL"], "RegisterBar"))
	
	-- Check if we're supposed to redirect this to another group, and that the group exists
	if( group.redirectTo and groups[group.redirectTo] ) then
		group = groups[group.redirectTo]
	end
	
	-- Already exists, remove the old one quickly
	if( group.bars[id] ) then
		group:UnregisterBar(id)
	end

	-- Retrieve a frame thats either recycled, or a newly created one
	local frame = getFrame()
		
	-- So we can do sorting and positioning
	table.insert(group.usedBars, frame)

	-- Grab basic info about the font
	local path, size, style = GameFontHighlight:GetFont()
	size = group.fontSize or size
	
	-- Timer text
	local timerTextWidth = size * 3.6
	
	frame.timer:SetPoint("LEFT", frame, "LEFT", 0, 0)
	frame.timer:SetFont(path, size, style)
	frame.timer:SetText(seconds)

	frame.timer:SetHeight(group.height)
	frame.timer:SetWidth(timerTextWidth)
	
	-- Display text
	frame.text:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
	frame.text:SetFont(path, size, style)
	frame.text:SetText(text)

	frame.text:SetHeight(group.height)
	frame.text:SetWidth((group.width - timerTextWidth) * 0.90)
	
	-- Timer spark
	frame.spark:SetHeight(group.height + 25)
	frame.spark:Show()
	
	-- Update icon
	if( icon ) then
		frame.icon:SetTexture(icon)
		
		if( frame.icon:GetTexture() ) then
			local mod = -1
			if( group.iconPosition == "RIGHT" ) then
				mod = 1
			end
		
			frame.icon:SetWidth(group.height)
			frame.icon:SetHeight(group.height)
			frame.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
			frame.icon:SetPoint("TOPLEFT", frame, "TOP" .. group.iconPosition, mod * group.height, 0)
			frame.icon:Show()
		else
			frame.icon:Hide()
		end
	else
		frame.icon:Hide()
	end
	
	-- Set info the bar needs to know
	frame.r = r or group.baseColor.r
	frame.g = g or group.baseColor.g
	frame.b = b or group.baseColor.b
	frame.owner = group.name
	frame.lastUpdate = GetTime()
	frame.endTime = GetTime() + seconds
	frame.secondsLeft = seconds
	frame.startSeconds = seconds
	frame.gradients = group.gradients
	frame.groupName = group.name
	frame.barID = id
	
	-- Reposition this group
	repositionFrames(group)
	
	-- Setup background
	frame.bg:SetStatusBarTexture(group.texture)
	frame.bg:SetStatusBarColor(0.0, 0.5, 0.5, 0.5)
	frame.bg:SetWidth(group.width)
	frame.bg:SetHeight(group.height)

	-- Start it up
	frame:SetStatusBarTexture(group.texture)
	frame:SetStatusBarColor(frame.r, frame.g, frame.b)
	frame:SetWidth(group.width)
	frame:SetHeight(group.height)
	frame:SetScale(group.scale)
	frame:SetScript("OnUpdate", barOnUpdate)
	frame:Show()
	
	-- Register it
	group.bars[id] = frame
end

-- Remove all bars
function GTB.UnregisterAllBars(group)
	assert(3, group.name and groups[group.name], string.format(L["MUST_CALL"], "UnregisteRAllBars"))
	
	-- Check if we're supposed to redirect this to another group, and that the group exists
	if( group.redirectTo and groups[group.redirectTo] ) then
		group = groups[group.redirectTo]
	end

	-- Clear the used bars list
	local totalBars = #(group.usedBars)
	for i=totalBars, 1, -1 do
		table.remove(group.usedBars, i)
	end
	
	-- Release all the frames
	for id, bar in pairs(group.bars) do
		releaseFrame(bar)
		group.bars[id] = nil
	end
	
	return (totalBars > 0)
end

-- Unregistering
function GTB.UnregisterBar(group, id)
	argcheck(id, 2, "string", "number")
	assert(3, group.name and groups[group.name], string.format(L["MUST_CALL"], "UnregisterBar"))
	
	-- Check if we're supposed to redirect this to another group, and that the group exists
	if( group.redirectTo and groups[group.redirectTo] ) then
		group = groups[group.redirectTo]
	end

	-- Remove the old entry
	if( group.bars[id] ) then
		-- Remove from list of used bars
		for i=#(group.usedBars), 1, -1 do
			if( group.usedBars[i].barID == id ) then
				table.remove(group.usedBars, i)
				break
			end
		end
	
		releaseFrame(group.bars[id])
		repositionFrames(group)
		group.bars[id] = nil
		return true
	end
	
	return nil
end

-- Icon
function GTB.SetBarIcon(group, id, icon, left, right, top, bottom)
	argcheck(id, 2, "string", "number")
	argcheck(icon, 3, "string", "nil")
	argcheck(left, 4, "number", "nil")
	argcheck(right, 5, "number", "nil")
	argcheck(top, 6, "number", "nil")
	argcheck(bottom, 7, "number", "nil")
	assert(3, group.name and groups[group.name], string.format(L["MUST_CALL"], "SetBarIcon"))
	
	-- Check if we're supposed to redirect this to another group, and that the group exists
	if( group.redirectTo and groups[group.redirectTo] ) then
		group = groups[group.redirectTo]
	end

	local frame = group.bars[id]
	
	-- No bar exists for this id, fail silently
	if( not frame ) then
		return
	end
	
	-- Display icon
	if( icon ) then
		frame.bar.icon:SetTexture(icon)
		
		if( frame.bar.icon:GetTexture() ) then
			local mod = -1
			if( group.iconPosition == "RIGHT" ) then
				mod = 1
			end
		
			frame.icon:SetWidth(group.height)
			frame.icon:SetHeight(group.height)
			frame.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
			frame.icon:SetPoint("TOPLEFT", frame, "TOP" .. group.iconPosition, mod * group.height, 0)
			frame.icon:Show()
		else
			frame.bar.icon:Hide()
		end
	else
		frame.bar.icon:Hide()
	end
end

-- Change it to a repeating timer
function GTB.SetRepeatingTimer(group, id, flag)
	argcheck(id, 2, "string", "number")
	argcheck(flag, 3, "boolean")
	assert(3, group.name and groups[group.name], string.format(L["MUST_CALL"], "SetRepeatingTimer"))

	-- Check if we're supposed to redirect this to another group, and that the group exists
	if( group.redirectTo and groups[group.redirectTo] ) then
		group = groups[group.redirectTo]
	end

	local frame = group.bars[id]
	
	-- No bar exists for this id, fail silently
	if( not frame ) then
		return
	end
	
	-- Flag as repeating!
	if( group.bars[id] ) then
		group.bars[id].repeating = flag
	end
end

-- Associate OnClick
function GTB.RegisterOnClick(group, id, handler, func, ...)
	argcheck(id, 2, "string", "number")
	argcheck(handler, 3, "table", "nil")
	argcheck(func, 4, "function", "string")
	assert(3, group.name and groups[group.name], string.format(L["MUST_CALL"], "RegisterOnClick"))
	
	-- Check if we're supposed to redirect this to another group, and that the group exists
	if( group.redirectTo and groups[group.redirectTo] ) then
		group = groups[group.redirectTo]
	end

	local frame = group.bars[id]
	
	-- No bar exists for this id, fail silently
	if( not frame ) then
		return
	end
	
	frame:EnableMouse(true)

	-- Save for when we actually click
	frame.clickHandler = handler
	frame.clickFunc = func
	frame.args = {...}
end
