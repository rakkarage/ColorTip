--[[
ColorTip
--]]

local lastR, lastG, lastB = 1, 1, 1
local lastRR, lastRG, lastRB = nil, nil, nil
local cachedUnit = nil
local classLine = nil
local factionLine = nil
local guildLine = nil
local function ReactionColor(unit)
	local reaction = UnitReaction(unit, "player")
	if reaction then
		local c = FACTION_BAR_COLORS[reaction]
		if c then return c.r, c.g, c.b end
	end
end

local function GradientBorder(ns, tr, tg, tb, br, bg, bb)
	ns.TopEdge:SetVertexColor(tr, tg, tb)
	ns.TopLeftCorner:SetVertexColor(tr, tg, tb)
	ns.TopRightCorner:SetVertexColor(tr, tg, tb)
	ns.BottomEdge:SetVertexColor(br, bg, bb)
	ns.BottomLeftCorner:SetVertexColor(br, bg, bb)
	ns.BottomRightCorner:SetVertexColor(br, bg, bb)
	ns.LeftEdge:SetGradient("VERTICAL", CreateColor(br, bg, bb), CreateColor(tr, tg, tb))
	ns.RightEdge:SetGradient("VERTICAL", CreateColor(br, bg, bb), CreateColor(tr, tg, tb))
end

local function ResetBorderAndBar()
	lastR, lastG, lastB = 1, 1, 1
	lastRR, lastRG, lastRB = nil, nil, nil
	cachedUnit = nil
	classLine = nil
	factionLine = nil
	guildLine = nil
	local ns = GameTooltip.NineSlice
	if ns then ns:SetBorderColor(1, 1, 1) end
	GameTooltipStatusBarTexture:SetVertexColor(1, 1, 1)
end

local function Reset()
	ResetBorderAndBar()
	for i = 1, 6 do
		local t = _G["GameTooltipTextLeft" .. i]
		if t then t:SetTextColor(1, 1, 1) end
	end
end

local function ResetIfNotUnit(tooltip)
	if tooltip ~= GameTooltip then return end
	ResetBorderAndBar()
end

local function GetClassLine(unit)
	local _, classId = UnitClass(unit)
	if not classId then return end
	local class = LOCALIZED_CLASS_NAMES_MALE[classId] or LOCALIZED_CLASS_NAMES_FEMALE[classId]
	if not class then return end
	for i = 1, 6 do
		local t = _G["GameTooltipTextLeft" .. i]
		if t then
			local text = t:GetText()
			if text and not issecretvalue(text) and string.find(text, class, 1, true) then
				return t
			end
		end
	end
end

local function GetFactionLine(unit)
	local faction = UnitFactionGroup(unit)
	if not faction then return end
	for i = 1, 6 do
		local t = _G["GameTooltipTextLeft" .. i]
		if t then
			local text = t:GetText()
			if text and not issecretvalue(text) and text == faction then
				return t
			end
		end
	end
end

local function GetGuildLine()
	local myGuild = GetGuildInfo("player")
	if not myGuild then return end
	for i = 1, 6 do
		local t = _G["GameTooltipTextLeft" .. i]
		if t then
			local text = t:GetText()
			if text and not issecretvalue(text) and text == myGuild then
				return t
			end
		end
	end
end

GameTooltip:HookScript("OnUpdate", function()
	local ns = GameTooltip.NineSlice
	if cachedUnit and UnitIsPlayer(cachedUnit) then
		local _, classId = UnitClass(cachedUnit)
		if classId then lastR, lastG, lastB = GetClassColor(classId) end
		if lastRR then
			GameTooltipTextLeft1:SetTextColor(lastRR, lastRG, lastRB)
			if classLine then classLine:SetTextColor(lastR, lastG, lastB) end
			if factionLine then factionLine:SetTextColor(lastRR, lastRG, lastRB) end
			if ns then GradientBorder(ns, lastRR, lastRG, lastRB, lastR, lastG, lastB) end
		end
		if guildLine then guildLine:SetTextColor(1, 0.85, 0.1) end
		GameTooltipStatusBarTexture:SetVertexColor(lastR, lastG, lastB)
	else
		if lastRR and ns then
			GradientBorder(ns, lastRR, lastRG, lastRB, lastR, lastG, lastB)
		elseif ns then
			ns:SetBorderColor(lastR, lastG, lastB)
		end
		GameTooltipStatusBarTexture:SetVertexColor(lastR, lastG, lastB)
	end
end)

GameTooltip:HookScript("OnHide", Reset)
TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip, data)
	if tooltip ~= GameTooltip then return end
	local unit = (data and data.unitToken) or (UnitExists("mouseover") and "mouseover") or nil
	if not unit then return end
	cachedUnit = unit
	if UnitIsPlayer(unit) then
		classLine = GetClassLine(unit)
		factionLine = GetFactionLine(unit)
		guildLine = GetGuildLine()
		lastRR, lastRG, lastRB = ReactionColor(unit)
	else
		classLine = nil
		factionLine = nil
		guildLine = nil
		lastRR, lastRG, lastRB = nil, nil, nil
		lastR, lastG, lastB = ReactionColor(unit)
		if lastR then GameTooltipTextLeft1:SetTextColor(lastR, lastG, lastB) end
	end
end)

TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, ResetIfNotUnit)
TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, ResetIfNotUnit)
TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Action, ResetIfNotUnit)
TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Object, ResetIfNotUnit)
