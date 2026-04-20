-- 🎨 ColorTip: Dynamic (class & reaction) tooltip name, border, and status bar.

local _lastColorR, _lastColorG, _lastColorB = 1, 1, 1
local _lastReactionR, _lastReactionG, _lastReactionB = nil, nil, nil

local COLOR_ALLIED_GUILD = { r = 1, g = 0.85, b = 0.1 }
local COLOR_OTHER_GUILD = { r = 0.75, g = 0.6, b = 0.15 }

local function GetReactionColor(unit)
	local reaction = UnitReaction(unit, "player")
	if reaction then
		local c = FACTION_BAR_COLORS[reaction]
		if c then return c.r, c.g, c.b end
	end
	return 1, 1, 1
end

local function ForceReset(tooltip)
	if tooltip ~= GameTooltip then return end
	_lastColorR, _lastColorG, _lastColorB = 1, 1, 1
	_lastReactionR, _lastReactionG, _lastReactionB = nil, nil, nil

	local border = tooltip.NineSlice
	if border and border.TopEdge then
		border.TopEdge:SetVertexColor(1, 1, 1)
		border.TopLeftCorner:SetVertexColor(1, 1, 1)
		border.TopRightCorner:SetVertexColor(1, 1, 1)
		border.BottomEdge:SetVertexColor(1, 1, 1)
		border.BottomLeftCorner:SetVertexColor(1, 1, 1)
		border.BottomRightCorner:SetVertexColor(1, 1, 1)
		border.LeftEdge:SetGradient("VERTICAL", CreateColor(1, 1, 1), CreateColor(1, 1, 1))
		border.RightEdge:SetGradient("VERTICAL", CreateColor(1, 1, 1), CreateColor(1, 1, 1))
		border:SetBorderColor(1, 1, 1)
	end

	if GameTooltipStatusBar then
		GameTooltipStatusBar:SetStatusBarColor(1, 1, 1)
		local tex = GameTooltipStatusBar:GetStatusBarTexture()
		if tex then tex:SetVertexColor(1, 1, 1) end
	end
end

local function ApplyColors(tooltip)
	local _, unit = tooltip:GetUnit()

	if not unit or issecretvalue(unit) then
		unit = "mouseover"
		if not UnitExists(unit) or issecretvalue(unit) then return end
	end

	local border = tooltip.NineSlice
	local isPlayer = UnitIsPlayer(unit)

	if isPlayer then
		local _, classId = UnitClass(unit)
		if classId then _lastColorR, _lastColorG, _lastColorB = GetClassColor(classId) end
		_lastReactionR, _lastReactionG, _lastReactionB = GetReactionColor(unit)

		local class = classId and (LOCALIZED_CLASS_NAMES_MALE[classId] or LOCALIZED_CLASS_NAMES_FEMALE[classId])
		local faction = UnitFactionGroup(unit)
		local playerGuild = GetGuildInfo("player")
		local unitGuild = GetGuildInfo(unit)

		for i = 2, tooltip:NumLines() do
			local line = _G["GameTooltipTextLeft" .. i]
			local text = line and line:GetText()
			if text and not issecretvalue(text) then
				if class and text:find(class, 1, true) then
					line:SetTextColor(_lastColorR, _lastColorG, _lastColorB)
				elseif faction and text == faction then
					line:SetTextColor(_lastReactionR or _lastColorR, _lastReactionG or _lastColorG, _lastReactionB or _lastColorB)
				elseif unitGuild and text:find(unitGuild, 1, true) then
					if playerGuild and unitGuild == playerGuild then
						line:SetTextColor(COLOR_ALLIED_GUILD.r, COLOR_ALLIED_GUILD.g, COLOR_ALLIED_GUILD.b)
					else
						line:SetTextColor(COLOR_OTHER_GUILD.r, COLOR_OTHER_GUILD.g, COLOR_OTHER_GUILD.b)
					end
				end
			end
		end
	else
		_lastReactionR, _lastReactionG, _lastReactionB = nil, nil, nil
		_lastColorR, _lastColorG, _lastColorB = GetReactionColor(unit)
	end

	GameTooltipTextLeft1:SetTextColor(_lastReactionR or _lastColorR, _lastReactionG or _lastColorG, _lastReactionB or _lastColorB)

	if border and border.TopEdge then
		local r, g, b = _lastColorR, _lastColorG, _lastColorB
		local rr, rg, rb = _lastReactionR or r, _lastReactionG or g, _lastReactionB or b
		border.TopEdge:SetVertexColor(rr, rg, rb)
		border.TopLeftCorner:SetVertexColor(rr, rg, rb)
		border.TopRightCorner:SetVertexColor(rr, rg, rb)
		border.BottomEdge:SetVertexColor(r, g, b)
		border.BottomLeftCorner:SetVertexColor(r, g, b)
		border.BottomRightCorner:SetVertexColor(r, g, b)
		border.LeftEdge:SetGradient("VERTICAL", CreateColor(r, g, b), CreateColor(rr, rg, rb))
		border.RightEdge:SetGradient("VERTICAL", CreateColor(r, g, b), CreateColor(rr, rg, rb))
	end

	if GameTooltipStatusBar and GameTooltipStatusBar:IsShown() then
		GameTooltipStatusBar:SetStatusBarColor(_lastColorR, _lastColorG, _lastColorB)
		local tex = GameTooltipStatusBar:GetStatusBarTexture()
		if tex then tex:SetVertexColor(_lastColorR, _lastColorG, _lastColorB) end
	end
end

TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip)
	ApplyColors(tooltip)
end)

GameTooltip:HookScript("OnUpdate", function(tooltip)
	if tooltip:IsShown() and tooltip:GetAlpha() > 0.1 then
		ApplyColors(tooltip)
	end
end)

GameTooltip:HookScript("OnHide", function(tooltip)
	_lastColorR, _lastColorG, _lastColorB = 1, 1, 1
	_lastReactionR, _lastReactionG, _lastReactionB = nil, nil, nil
	if tooltip.NineSlice then tooltip.NineSlice:SetBorderColor(1, 1, 1) end
end)

if GameTooltipStatusBar then
	GameTooltipStatusBar:HookScript("OnValueChanged", function()
		if _lastColorR then
			GameTooltipStatusBar:SetStatusBarColor(_lastColorR, _lastColorG, _lastColorB)
		end
	end)
end

for _, value in pairs(Enum.TooltipDataType) do
	if value ~= Enum.TooltipDataType.Unit then
		TooltipDataProcessor.AddTooltipPostCall(value, ForceReset)
	end
end
