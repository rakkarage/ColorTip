--[[
ColorTip
--]]

local lastR, lastG, lastB = 1, 1, 1
local classLine = nil
local factionLine = nil

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
	classLine = nil
	factionLine = nil
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
	local _, class = UnitClass(unit)
	if not class then return end
	local localizedClass = LOCALIZED_CLASS_NAMES_MALE[class] or LOCALIZED_CLASS_NAMES_FEMALE[class]
	if not localizedClass then return end
	for i = 1, 6 do
		local t = _G["GameTooltipTextLeft" .. i]
		if t then
			local text = t:GetText()
			if text and string.find(text, localizedClass) then return t end
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
			if text and text == faction then return t end
		end
	end
end

GameTooltip:HookScript("OnUpdate", function()
	local ns = GameTooltip.NineSlice
	if UnitIsPlayer("mouseover") then
		local _, class = UnitClass("mouseover")
		if class then lastR, lastG, lastB = GetClassColor(class) end
		local rr, rg, rb = ReactionColor("mouseover")
		if rr then
			GameTooltipTextLeft1:SetTextColor(rr, rg, rb)
			if classLine then classLine:SetTextColor(lastR, lastG, lastB) end
			if factionLine then factionLine:SetTextColor(rr, rg, rb) end
			if ns then GradientBorder(ns, rr, rg, rb, lastR, lastG, lastB) end
		end
		GameTooltipStatusBarTexture:SetVertexColor(lastR, lastG, lastB)
	else
		if ns then ns:SetBorderColor(lastR, lastG, lastB) end
		GameTooltipStatusBarTexture:SetVertexColor(lastR, lastG, lastB)
	end
end)

GameTooltip:HookScript("OnHide", Reset)

TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip, data)
	if tooltip ~= GameTooltip then return end
	local unit = (data and data.unitToken) or (UnitExists("mouseover") and "mouseover") or nil
	if not unit then return end
	if UnitIsPlayer(unit) then
		classLine = GetClassLine(unit)
		factionLine = GetFactionLine(unit)
	else
		classLine = nil
		factionLine = nil
		lastR, lastG, lastB = ReactionColor(unit)
		if lastR then GameTooltipTextLeft1:SetTextColor(lastR, lastG, lastB) end
	end
end)

TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, ResetIfNotUnit)
TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, ResetIfNotUnit)
TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Action, ResetIfNotUnit)
TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Object, ResetIfNotUnit)
