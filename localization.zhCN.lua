-- Translated by wowui.cn

if( GetLocale() ~= "zhCN" ) then
	return
end

DRTrackerLocals = setmetatable({
	["ALT + Drag to move the frame anchor."] = "ALT + 鼠标拖动移动框体.",

	-- Spell abbreviations
	["Ent Roots"] = "纠缠根须",
	["Psy Scream"] = "心灵尖啸",
	["Hammer of Just"] = "制裁之锤",

	-- Cmd
	["DRTracker slash commands"] = "DRTracker命令行",
	["- clear - Clears all running timers."] = "- clear - 清除所有运行中的计时条.",
	["- ui - Opens the configuration for DRTracker."] = "- ui - 打开图形配置窗口.",
	["- test - Shows test timers in DRTracker."] = "- test - 显示测试计时条.",

	-- GUI
	["None"] = "无",
	["General"] = "常规选项",
	
	["DRTracker"] = "DRTracker",
	
	["Only show trigger name in bars"] = "只在计时条内显示触发名字",
	
	["Display scale"] = "大小缩放",
	["How big the actual timers should be."] = "计时条大小缩放.",

	["Show NPC diminishing returns"] = "显示NPC的法术递减",

	["Enable DRTracker inside"] = "在以下环境下启用",
	["Allows you to choose which scenarios this mod should be enabled in."] = "允许你设置在什么情况下启用DRTracker.",

	["Enemy DR filter"] = "敌对监视过滤",
	["Friendly DR filter"] = "友方监视过滤",
	["List"] = "列表",
	["Lets you choose which diminishing return categories should be enabled."] = "选择你需要启用的技能效果递减分类.",
	["Enable category %s.\n\nSpells in this category:\n%s"] = "启用分类 %s.\n\n此类别内的法术:\n%s",

	["Show enemies"] = "显示敌对",
	["Show friendlies"] = "显示友方",
	["Show self"] = "显示自身",

	["Show diminishing returns for"] = "显示法术递减：",
	["Allows you to set if diminishing returns should be shown for friendly players and/or enemy players. Use show self if you only want your DRs but not all friendly players."] = "设置是否显示友方/敌对玩家的法术递减.如果你不想监视所有友方玩家请选择显示自身",
	
	["Everywhere else"] = "任何地方",
	["Battlegrounds"] = "战场",
	["Arenas"] = "竞技场",
	["Raid instances"] = "团队副本",
	["Party instances"] = "小队副本",

	["Grow display up"] = "向上增长",
	["Instead of adding everything from top to bottom, timers will be shown from bottom to top."] = "计时条由下向上增长.",

	["Redirect bars to group"] = "重定向计时条",
	["Group name to redirect bars to, this lets you show the mods timers under another addons bar group. Requires the bars to be created using GTB."] = "重定向计时条到其他插件的计时条下.",

	["Show anchor"] = "显示锚点",
	["Display timer anchors for moving around."] = "显示计时条锚点以拖动位置.",

	["Display scale"] = "显示缩放",
	["Max timers"] = "计时条上限",
	["Icon position"] = "图标位置",
	["Left"] = "左",
	["Right"] = "右",
	["Bar display"] = "计时条显示",
	
	["Bar color"] = "计时条颜色",
	
	["Fade time"] = "渐隐时间",
	
	["Texture"] = "材质",
	["Width"] = "宽",
	["Color"] = "颜色",
	
	["None"] = "无",
	["Text"] = "文字",
	["Size"] = "大小",
	["Font"] = "字体",
}, {__index = DRTrackerLocals})