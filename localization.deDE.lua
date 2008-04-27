if( GetLocale() ~= "deDE" ) then
	return
end

DRTrackerLocals = setmetatable({
}, {__index = DRTrackerLocals})