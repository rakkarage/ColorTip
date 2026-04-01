--[[
ColorTip
--]]

local lastR, lastG, lastB = 1, 1, 1

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
	local ns = GameTooltip.NineSlice
	if ns then ns:SetBorderColor(1, 1, 1) end
	GameTooltipStatusBarTexture:SetVertexColor(1, 1, 1)
end

local function Reset()
	ResetBorderAndBar()
	GameTooltipTextLeft1:SetTextColor(1, 1, 1)
end

local function ResetIfNotUnit(tooltip)
	if tooltip ~= GameTooltip then return end
	ResetBorderAndBar()
end

GameTooltip:HookScript("OnUpdate", function()
	local ns = GameTooltip.NineSlice
	if UnitIsPlayer("mouseover") then
		local _, class = UnitClass("mouseover")
		if class then lastR, lastG, lastB = GetClassColor(class) end
		local rr, rg, rb = ReactionColor("mouseover")
		GameTooltipTextLeft1:SetTextColor(lastR, lastG, lastB)
		if rr and ns then GradientBorder(ns, rr, rg, rb, lastR, lastG, lastB) end
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
	if not UnitIsPlayer(unit) then
		lastR, lastG, lastB = ReactionColor(unit)
	end
end)

TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, ResetIfNotUnit)
TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, ResetIfNotUnit)
TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Action, ResetIfNotUnit)
TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Object, ResetIfNotUnit)
