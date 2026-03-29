-- ColorTip
-- Dynamic (class & reaction) tooltip border, tooltip status bar & tooltip name color.
-- Players: name=class, healthbar=class, border top=reaction, sides=gradient, bottom=class
-- NPCs: healthbar=reaction, border=uniform reaction

local function ReactionColor(unit)
	local reaction = UnitReaction(unit, "player")
	if reaction then
		if reaction >= 5 then
			return 0.0118, 0.5686, 0.1098
		elseif reaction == 4 then
			return 0.7961, 0.6196, 0.0118
		else
			return 0.6627, 0.2627, 0.1922
		end
	end
	return 1.0, 1.0, 1.0
end

local function ClassColor(unit)
	if not UnitIsPlayer(unit) then return nil end
	local _, class = UnitClass(unit)
	if class then
		local r, g, b = GetClassColor(class)
		if r then return r, g, b end
	end
end

local function SetBorderAsymmetric(ns, tr, tg, tb, br, bg, bb)
	ns.TopEdge:SetVertexColor(tr, tg, tb)
	ns.TopLeftCorner:SetVertexColor(tr, tg, tb)
	ns.TopRightCorner:SetVertexColor(tr, tg, tb)
	ns.BottomEdge:SetVertexColor(br, bg, bb)
	ns.BottomLeftCorner:SetVertexColor(br, bg, bb)
	ns.BottomRightCorner:SetVertexColor(br, bg, bb)
	ns.LeftEdge:SetVertexColor(1, 1, 1, 1)
	ns.RightEdge:SetVertexColor(1, 1, 1, 1)
	ns.LeftEdge:SetGradient("VERTICAL", CreateColor(br, bg, bb), CreateColor(tr, tg, tb))
	ns.RightEdge:SetGradient("VERTICAL", CreateColor(br, bg, bb), CreateColor(tr, tg, tb))
end

local isUnitTooltip = false
local lastR, lastG, lastB = nil, nil, nil

local function ResetTooltipColors()
	lastR, lastG, lastB = nil, nil, nil
	GameTooltipTextLeft1:SetTextColor(1, 1, 1)
	local ns = GameTooltip.NineSlice
	if ns then
		local pieces = {
			"TopEdge", "TopRightCorner", "RightEdge", "BottomRightCorner",
			"BottomEdge", "BottomLeftCorner", "LeftEdge", "TopLeftCorner",
		}
		for _, key in ipairs(pieces) do
			local piece = ns[key]
			if piece then piece:SetVertexColor(1, 1, 1, 1) end
		end
	end
end

local origSetStatusBarColor = GameTooltipStatusBar.SetStatusBarColor
GameTooltipStatusBar.SetStatusBarColor = function(self, r, g, b, a)
	if lastR and isUnitTooltip then
		origSetStatusBarColor(self, lastR, lastG, lastB, a)
		return
	end
	origSetStatusBarColor(self, r, g, b, a)
end

GameTooltip:HookScript("OnShow", function(self)
	if not isUnitTooltip then
		ResetTooltipColors()
	end
end)

GameTooltip:HookScript("OnUpdate", function(self)
	if not lastR then return end
	local _, unit = self:GetUnit()
	if not unit then return end
	GameTooltipTextLeft1:SetTextColor(lastR, lastG, lastB)
end)

GameTooltip:HookScript("OnHide", function()
	isUnitTooltip = false
	ResetTooltipColors()
end)

TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip, data)
	if tooltip ~= GameTooltip or not data then return end

	local unit = data.unitToken
	if not unit and UnitExists("mouseover") then unit = "mouseover" end
	if not unit then return end
	isUnitTooltip = true

	local cr, cg, cb = ClassColor(unit)
	local rr, rg, rb = ReactionColor(unit)
	local ns = GameTooltip.NineSlice

	if cr then
		lastR, lastG, lastB = cr, cg, cb
		GameTooltipTextLeft1:SetTextColor(cr, cg, cb)
		if ns then SetBorderAsymmetric(ns, rr, rg, rb, cr, cg, cb) end
	else
		lastR, lastG, lastB = rr, rg, rb
		if ns then ns:SetBorderColor(rr, rg, rb) end
	end
end)

local function ResetIfNotUnit(tooltip)
	if tooltip ~= GameTooltip then return end
	if isUnitTooltip then
		isUnitTooltip = false
		ResetTooltipColors()
	end
end

TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, ResetIfNotUnit)
TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, ResetIfNotUnit)
TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Action, ResetIfNotUnit)
TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Object, ResetIfNotUnit)
